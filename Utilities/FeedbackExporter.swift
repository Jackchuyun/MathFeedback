import SwiftUI

/// Export a single feedback in various formats
enum FeedbackExporter {

    // MARK: - Plain Text

    static func plainText(for feedback: Feedback) -> String {
        let df = DateFormatter.feedbackDate
        var text = ""
        text += "\(feedback.student?.name ?? "") — 课后反馈\n"
        text += "══════════════════\n\n"
        text += "课题: \(feedback.lessonTopic)\n"
        text += "日期: \(df.string(from: feedback.date))\n"
        text += "综合评分: \(feedback.overallRating)/5\n\n"

        text += "【技能维度】\n"
        for skill in feedback.skillScores {
            let bar = String(repeating: "★", count: skill.score) + String(repeating: "☆", count: 5 - skill.score)
            text += "  \(skill.skillName): \(bar) (\(skill.score)/5)\n"
        }
        text += "\n"

        text += "【学习指标】\n"
        text += "  作业完成度: \(feedback.homeworkCompletion)%\n"
        text += "  课堂参与度: \(feedback.classParticipation)%\n\n"

        if !feedback.learningContent.isEmpty {
            text += "【学习内容】\n\(feedback.learningContent)\n\n"
        }
        if !feedback.strengths.isEmpty {
            text += "【优点】\n\(feedback.strengths)\n\n"
        }
        if !feedback.weaknesses.isEmpty {
            text += "【改进点】\n\(feedback.weaknesses)\n\n"
        }
        if !feedback.teacherNotes.isEmpty {
            text += "【教师评语】\n\(feedback.teacherNotes)\n\n"
        }
        if !feedback.homework.isEmpty {
            text += "【课后作业】\n\(feedback.homework)\n\n"
        }

        text += "—— MathFeedback 生成 ——\n"
        return text
    }

    // MARK: - URL exports

    static func txtURL(for feedback: Feedback) -> URL {
        let filename = safeFilename("\(feedback.student?.name ?? "学生")_\(feedback.lessonTopic)_反馈.txt")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? plainText(for: feedback).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    #if os(iOS)
    static func pdfURL(for feedback: Feedback) -> URL {
        let text = plainText(for: feedback)
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 56
        let contentWidth = pageWidth - margin * 2

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        let filename = safeFilename("\(feedback.student?.name ?? "学生")_\(feedback.lessonTopic)_反馈.pdf")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let data = renderer.pdfData { ctx in
            var y: CGFloat = margin
            ctx.beginPage()

            let bodyFont = UIFont.systemFont(ofSize: 12)
            let monoFont = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)

            for paragraph in text.components(separatedBy: "\n") {
                if y > pageHeight - margin - 20 { ctx.beginPage(); y = margin }
                let font: UIFont = paragraph.hasPrefix("═") || paragraph.hasPrefix("——") ? monoFont : (paragraph.isEmpty ? bodyFont : bodyFont)
                let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.darkGray]
                if paragraph.contains("【") && paragraph.contains("】") {
                    let a2: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.systemIndigo]
                    let rect = CGRect(x: margin, y: y, width: contentWidth, height: .greatestFiniteMagnitude)
                    (paragraph as NSString).draw(in: rect, withAttributes: a2)
                    y += 20
                } else {
                    let rect = CGRect(x: margin, y: y, width: contentWidth, height: .greatestFiniteMagnitude)
                    let opts: NSStringDrawingOptions = [.usesLineFragmentOrigin]
                    let bounds = (paragraph as NSString).boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: opts, attributes: attr, context: nil)
                    (paragraph as NSString).draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: bounds.height), withAttributes: attr)
                    y += max(bounds.height + 1, 14)
                }
            }
        }

        try? data.write(to: url)
        return url
    }
    #endif

    private static func safeFilename(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return raw.components(separatedBy: invalid).joined(separator: "_")
    }
}
