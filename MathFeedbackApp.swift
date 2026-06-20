import SwiftUI
import SwiftData

@main
struct MathFeedbackApp: App {
    @StateObject private var appState = MathFeedbackAppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = appState.container {
                    ContentView()
                        .modelContainer(container)
                } else {
                    StartupErrorView(
                        message: appState.startupError,
                        recoveryMessage: appState.recoveryMessage,
                        retry: appState.openContainer,
                        rebuildDataStore: appState.rebuildDataStore
                    )
                }
            }
        }
    }
}

@MainActor
private final class MathFeedbackAppState: ObservableObject {
    @Published var container: ModelContainer?
    @Published var startupError: String?
    @Published var recoveryMessage: String?

    init() {
        openContainer()
    }

    func openContainer() {
        do {
            container = try ModelContainer(for: Student.self, Feedback.self, SkillScore.self, ClassGroup.self)
            startupError = nil
            recoveryMessage = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    func rebuildDataStore() {
        do {
            let backupFolder = try SwiftDataStoreRecovery.backupAndRemoveDefaultStores()
            recoveryMessage = "旧数据库文件已备份到「文件」App 的 Documents：\(backupFolder.lastPathComponent)"
            openContainer()
        } catch {
            recoveryMessage = "重建失败：\(error.localizedDescription)"
        }
    }
}

private struct StartupErrorView: View {
    let message: String?
    let recoveryMessage: String?
    let retry: () -> Void
    let rebuildDataStore: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
            Text("无法打开数据")
                .font(.title2)
                .fontWeight(.bold)
            Text("本地数据库暂时无法加载。请重启 App；如果问题持续，请联系支持并保留当前设备数据。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .liquidGlassControl(cornerRadius: 12, tint: .orange)
            }
            if let recoveryMessage {
                Text(recoveryMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .liquidGlassControl(cornerRadius: 12, tint: .mint)
            }
            Button {
                retry()
            } label: {
                Label("重试打开", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Button(role: .destructive) {
                rebuildDataStore()
            } label: {
                Label("备份旧数据并重建", systemImage: "externaldrive.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            Link("联系支持", destination: URL(string: "mailto:jack_huang28@foxmail.com")!)
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassBackground()
    }
}
