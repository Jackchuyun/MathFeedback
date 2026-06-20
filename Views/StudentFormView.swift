import SwiftUI
import SwiftData

struct StudentFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var student: Student?

    @Query(sort: \ClassGroup.name) private var existingClasses: [ClassGroup]
    @State private var name: String = ""
    @State private var grade: String = "高一"
    @State private var notes: String = ""
    @State private var className: String = ""

    private let grades = ["高一", "高二", "高三"]

    init(student: Student? = nil) {
        self.student = student
    }

    private var uniqueClassNames: [String] {
        let names = existingClasses.map { $0.name }
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Label("姓名", systemImage: "person.text.rectangle")
                        .font(.subheadline).foregroundStyle(.secondary)
                    TextField("学生姓名", text: $name)
                        .textFieldStyle(.plain).padding(10)
                        .liquidGlassControl(cornerRadius: 10)
                }

                // Grade
                VStack(alignment: .leading, spacing: 6) {
                    Label("年级", systemImage: "graduationcap")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Picker("年级", selection: $grade) {
                        ForEach(grades, id: \.self) { g in Text(g).tag(g) }
                    }
                    .pickerStyle(.segmented)
                }

                // Class — text field + chip suggestions
                VStack(alignment: .leading, spacing: 6) {
                    Label("班级（或一对一）", systemImage: "rectangle.3.group")
                        .font(.subheadline).foregroundStyle(.secondary)
                    TextField("输入班级名，如：高二3班", text: $className)
                        .textFieldStyle(.plain).padding(10)
                        .liquidGlassControl(cornerRadius: 10)

                    if !uniqueClassNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(uniqueClassNames, id: \.self) { cn in
                                    Button { className = cn } label: {
                                        Text(cn)
                                            .font(.caption).padding(.horizontal, 10).padding(.vertical, 5)
                                            .foregroundStyle(className == cn ? .white : .secondary)
                                            .liquidGlassCapsule(tint: className == cn ? .indigo : nil)
                                            .background(className == cn ? Color.indigo.opacity(0.72) : .clear, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 6) {
                    Label("备注", systemImage: "note.text")
                        .font(.subheadline).foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .font(.body).frame(minHeight: 100).padding(6)
                        .liquidGlassControl(cornerRadius: 10)
                        .scrollContentBackground(.hidden)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .liquidGlassBackground()
            .navigationTitle(student == nil ? "添加学生" : "编辑学生")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let s = student {
                    name = s.name; grade = s.grade; notes = s.notes
                    className = s.classGroup?.name ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Resolve or create ClassGroup
        var targetClass: ClassGroup? = nil
        let trimmedClass = className.trimmingCharacters(in: .whitespaces)
        if !trimmedClass.isEmpty {
            if let existing = existingClasses.first(where: { $0.name == trimmedClass }) {
                targetClass = existing
            } else {
                let new = ClassGroup(name: trimmedClass)
                context.insert(new)
                targetClass = new
            }
        }

        if let existing = student {
            existing.name = trimmed; existing.grade = grade; existing.notes = notes
            existing.classGroup = targetClass
        } else {
            let new = Student(name: trimmed, grade: grade, notes: notes)
            new.classGroup = targetClass
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    StudentFormView().modelContainer(previewContainer)
}
