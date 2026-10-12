import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView {
                    HomeView()
                        .tabItem { Label("反馈", systemImage: "square.text.square") }

                    StudentListView()
                        .tabItem { Label("学生", systemImage: "person.2") }

                    SettingsView()
                        .tabItem { Label("设置", systemImage: "gearshape") }
                }
                .tint(.indigo)
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
