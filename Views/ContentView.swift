import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("didRunOneTimeStudentDataReset20260706") private var didRunOneTimeStudentDataReset = false

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
            guard !didRunOneTimeStudentDataReset else { return }

            do {
                for skillScore in try context.fetch(FetchDescriptor<SkillScore>()) {
                    context.delete(skillScore)
                }
                for feedback in try context.fetch(FetchDescriptor<Feedback>()) {
                    context.delete(feedback)
                }
                for student in try context.fetch(FetchDescriptor<Student>()) {
                    context.delete(student)
                }
                for classGroup in try context.fetch(FetchDescriptor<ClassGroup>()) {
                    context.delete(classGroup)
                }
                try context.save()

                let students = try context.fetchCount(FetchDescriptor<Student>())
                let classes = try context.fetchCount(FetchDescriptor<ClassGroup>())
                let feedback = try context.fetchCount(FetchDescriptor<Feedback>())
                let skills = try context.fetchCount(FetchDescriptor<SkillScore>())

                if students == 0, classes == 0, feedback == 0, skills == 0 {
                    print("DATA_RESET_COMPLETE students=0 classes=0 feedback=0 skills=0")
                    didRunOneTimeStudentDataReset = true
                } else {
                    print("DATA_RESET_FAILED students=\(students) classes=\(classes) feedback=\(feedback) skills=\(skills)")
                }
            } catch {
                context.rollback()
                print("DATA_RESET_FAILED \(error)")
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
