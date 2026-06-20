import Foundation
import Security

enum DeepSeekError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(String)
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "请先在设置中填写 DeepSeek API Key。"
        case .invalidResponse:
            return "DeepSeek 返回格式异常，请稍后重试。"
        case .requestFailed(let message):
            return message
        case .emptyContent:
            return "DeepSeek 没有生成有效内容，请补充学习内容后重试。"
        }
    }
}

enum DeepSeekCredentials {
    private static let service = "com.mathfeedback.deepseek"
    private static let account = "api-key"

    static var apiKey: String {
        get {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var item: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                  let data = item as? Data,
                  let key = String(data: data, encoding: .utf8) else {
                return ""
            }
            return key
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            if trimmed.isEmpty {
                SecItemDelete(query as CFDictionary)
                return
            }

            let data = Data(trimmed.utf8)
            let attributes: [String: Any] = [kSecValueData as String: data]
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

            if status == errSecItemNotFound {
                var addQuery = query
                addQuery[kSecValueData as String] = data
                addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                SecItemAdd(addQuery as CFDictionary, nil)
            }
        }
    }
}

struct TeacherNoteInput {
    let studentName: String
    let grade: String
    let className: String?
    let lessonTopic: String
    let learningContent: String
    let overallRating: Int
    let conceptScore: Int
    let calculationScore: Int
    let reasoningScore: Int
    let writingScore: Int
    let homeworkCompletion: Int
    let classParticipation: Int
    let strengths: String
    let weaknesses: String
}

enum DeepSeekTeacherNoteService {
    static let defaultModel = "deepseek-v4-flash"
    private static let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!

    static func generateTeacherNote(input: TeacherNoteInput, model: String) async throws -> String {
        let apiKey = DeepSeekCredentials.apiKey
        guard !apiKey.isEmpty else { throw DeepSeekError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            DeepSeekChatRequest(
                model: model.isEmpty ? defaultModel : model,
                messages: [
                    .init(role: "system", content: systemPrompt),
                    .init(role: "user", content: userPrompt(from: input))
                ],
                temperature: 0.72,
                maxTokens: 420,
                stream: false
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let error = try? JSONDecoder().decode(DeepSeekErrorResponse.self, from: data) {
                throw DeepSeekError.requestFailed(error.error.message)
            }
            let message = String(data: data, encoding: .utf8) ?? "DeepSeek 请求失败，请稍后重试。"
            throw DeepSeekError.requestFailed(message)
        }

        let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
        let content = decoded.choices.first?.message.content
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { throw DeepSeekError.emptyContent }
        return cleaned(content)
    }

    private static let systemPrompt = """
    你是一名经验丰富的高中数学教师，擅长写课后反馈中的教师评语。
    请根据输入信息生成一段自然、具体、积极但不空泛的中文教师评语。
    要求：
    1. 只输出教师评语正文，不要标题、项目符号、Markdown 或解释。
    2. 语气专业温和，适合发给家长和学生。
    3. 长度控制在 120 到 180 个汉字。
    4. 必须结合课题、学习内容、评分、技能维度、学习指标、优点和改进点。
    5. 先肯定表现，再指出一个最重要的改进方向，最后给出后续学习建议。
    6. 不要编造未提供的考试分数、排名或承诺。
    """

    private static func userPrompt(from input: TeacherNoteInput) -> String {
        """
        学生：\(input.studentName)
        年级：\(input.grade)
        班级：\(input.className ?? "未填写")
        课题：\(input.lessonTopic)
        学习内容：
        \(emptyFallback(input.learningContent))

        综合评分：\(input.overallRating)/5
        技能维度：
        - 概念理解：\(input.conceptScore)/5
        - 计算能力：\(input.calculationScore)/5
        - 解题思路：\(input.reasoningScore)/5
        - 规范书写：\(input.writingScore)/5

        学习指标：
        - 作业完成度：\(input.homeworkCompletion)%
        - 课堂参与度：\(input.classParticipation)%

        优点标签或补充：
        \(emptyFallback(input.strengths))

        改进点标签或补充：
        \(emptyFallback(input.weaknesses))
        """
    }

    private static func emptyFallback(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未填写" : trimmed
    }

    private static func cleaned(_ content: String) -> String {
        content
            .replacingOccurrences(of: "教师评语：", with: "")
            .replacingOccurrences(of: "教师评语:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DeepSeekChatRequest: Encodable {
    let model: String
    let messages: [DeepSeekMessage]
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

private struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

private struct DeepSeekChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: DeepSeekMessage
    }
}

private struct DeepSeekErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
