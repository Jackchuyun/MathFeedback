import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupData: Data?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMsg = ""
    @State private var showPrivacy = false
    @State private var showImportConfirmation = false
    @State private var pendingBackupData: Data?
    @State private var deepSeekAPIKey = ""
    @AppStorage("deepSeekModel") private var deepSeekModel = DeepSeekTeacherNoteService.defaultModel

    private var backupFilename: String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmm"
        return "MathFeedback_备份_\(df.string(from: .now)).json"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                // Data Management
                Section {
                    Button {
                        backupData = DataBackup.exportAll(context: context)
                        if backupData != nil {
                            showExporter = true
                        } else {
                            showAlertMsg("导出失败", "无法生成备份数据，请重试")
                        }
                    } label: {
                        Label("导出全部数据", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showImporter = true
                    } label: {
                        Label("从备份恢复", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("换手机时：旧手机导出 → 存储到 iCloud「文件」→ 新手机导入恢复。\n建议每次重要更新后导出备份。")
                }

                Section {
                    SecureField("sk-...", text: $deepSeekAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("模型", selection: $deepSeekModel) {
                        Text("DeepSeek V4 Flash").tag("deepseek-v4-flash")
                        Text("DeepSeek V4 Pro").tag("deepseek-v4-pro")
                    }

                    Button {
                        DeepSeekCredentials.apiKey = deepSeekAPIKey
                        showAlertMsg("已保存", "DeepSeek API Key 已安全保存到本机钥匙串。")
                    } label: {
                        Label("保存 DeepSeek 设置", systemImage: "checkmark.seal")
                    }

                    if !deepSeekAPIKey.isEmpty {
                        Button(role: .destructive) {
                            deepSeekAPIKey = ""
                            DeepSeekCredentials.apiKey = ""
                            showAlertMsg("已清除", "DeepSeek API Key 已从本机删除。")
                        } label: {
                            Label("清除 API Key", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("AI 生成")
                } footer: {
                    Text("点击反馈表单中的 AI 生成时，课题、学习内容、评分、技能维度、学习指标、优点和改进点会发送到 DeepSeek 用于生成教师评语。API Key 仅保存在本机钥匙串。")
                }

                // Privacy
                Section {
                    Button { showPrivacy = true } label: {
                        Label("隐私政策", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://jackchuyun.github.io/mathfeedback-site/privacy.html")!) {
                        Label("在线隐私政策", systemImage: "safari")
                    }
                    Link(destination: URL(string: "mailto:jack_huang28@foxmail.com")!) {
                        Label("联系支持", systemImage: "envelope")
                    }
                    Link(destination: URL(string: "https://jackchuyun.github.io/mathfeedback-site/support.html")!) {
                        Label("在线支持页面", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("隐私与支持")
                }

                // About
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("最低系统")
                        Spacer()
                        Text("iOS 17.0").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                } footer: {
                    Text("MathFeedback — 专注高中数学课后反馈")
                }
            }
            .navigationTitle("设置")
            .scrollContentBackground(.hidden)
            .liquidGlassBackground()
            .onAppear {
                deepSeekAPIKey = DeepSeekCredentials.apiKey
            }
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
            .fileExporter(isPresented: $showExporter,
                          document: backupData.map { BackupDocument(data: $0) } ?? BackupDocument(data: Data()),
                          contentType: .json,
                          defaultFilename: backupFilename) { result in
                if case .success = result {
                    showAlertMsg("导出成功", "备份文件已保存。换手机时在新手机上用「从备份恢复」导入此文件即可。")
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result {
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if didAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    if let data = try? Data(contentsOf: url) {
                        pendingBackupData = data
                        showImportConfirmation = true
                    } else {
                        showAlertMsg("读取失败", "无法读取该备份文件，请确认文件仍可访问。")
                    }
                }
            }
            .confirmationDialog("确认恢复备份？", isPresented: $showImportConfirmation, titleVisibility: .visible) {
                Button("恢复并合并数据") {
                    guard let data = pendingBackupData else { return }
                    if DataBackup.importAll(from: data, context: context) {
                        showAlertMsg("恢复成功", "备份已合并到当前数据。相同 ID 的学生和反馈会被更新，不会重复创建。")
                    } else {
                        showAlertMsg("恢复失败", "文件格式不正确，请选择 MathFeedback 备份 JSON 文件。")
                    }
                    pendingBackupData = nil
                }
                Button("取消", role: .cancel) {
                    pendingBackupData = nil
                }
            } message: {
                Text("恢复会导入学生、班级和反馈记录；如遇相同 ID，将使用备份中的内容更新当前数据。")
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMsg)
            }
        }
    }

    private func showAlertMsg(_ title: String, _ msg: String) {
        alertTitle = title
        alertMsg = msg
        showAlert = true
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("""
                    MathFeedback 隐私政策

                    最后更新：2026年6月13日

                    1. 数据收集
                    MathFeedback 不收集、出售或共享个人身份信息。您输入的学生姓名、班级、反馈记录、评分、作业和导出报告默认存储在您的设备本地。

                    2. 数据存储
                    所有数据使用 Apple SwiftData 框架存储在您的 iPhone 本地存储中。开发者不运营用于存储这些数据的云服务器。

                    3. 第三方服务
                    本 App 不使用第三方分析、广告或追踪服务。若您在设置中填写 DeepSeek API Key 并点击「AI 生成」教师评语，App 会将课题、学习内容、评分、技能维度、学习指标、优点和改进点发送到 DeepSeek API，用于生成教师评语。API Key 仅保存在本机钥匙串中。

                    4. 数据安全
                    您的数据由您控制。您可以通过设置中的「导出全部数据」功能备份数据，存储在标准的 JSON 文件中。换手机时，将备份文件保存到 iCloud 文件，在新手机上导入即可恢复。

                    5. 儿童隐私
                    如果您使用本 App 管理学生数据，请妥善保护您的设备密码、备份文件和 DeepSeek API Key。使用 AI 生成功能前，请确认您有权将相关反馈内容发送给 DeepSeek 处理。

                    6. 联系我们
                    如有隐私或支持相关问题，请联系开发者：jack_huang28@foxmail.com。

                    7. 政策更新
                    本隐私政策可能会随时更新。更新后的政策将在 App 内公布。
                    """)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineSpacing(6)
                }
                .padding(20)
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassBackground()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(previewContainer)
}
