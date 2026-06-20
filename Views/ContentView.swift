import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
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
        .task {
            #if DEBUG
            SampleDataSeeder.seedIfNeeded(context: context)
            hasCompletedOnboarding = true
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
