import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Student.name) private var students: [Student]

    @State private var searchText = ""
    @State private var selectedGrade: String = "全部"
    @State private var selectedClass: String? = nil
    @State private var showAddSheet = false

    private let grades = ["全部", "高一", "高二", "高三"]

    /// Classes available for the currently selected grade
    private var availableClasses: [String] {
        let base = selectedGrade == "全部" ? students : students.filter { $0.grade == selectedGrade }
        var names = Set<String>()
        for s in base { if let cls = s.classGroup?.name { names.insert(cls) } }
        return names.sorted()
    }

    var filteredStudents: [Student] {
        var result = students
        if selectedGrade != "全部" {
            result = result.filter { $0.grade == selectedGrade }
        }
        if let cls = selectedClass {
            result = result.filter { $0.classGroup?.name == cls }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if students.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("学生")
            .searchable(text: $searchText, prompt: "搜索姓名")
            .toolbar {
                ToolbarItem(placement: .platformTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                StudentFormView()
            }
            .onChange(of: selectedGrade) { _, _ in
                // Reset class filter when grade changes
                let classes = availableClasses
                if selectedClass != nil, !classes.contains(selectedClass!) {
                    selectedClass = nil
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("添加第一个学生")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button { showAddSheet = true } label: {
                Label("添加学生", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
    }

    // MARK: - List

    private var listContent: some View {
        VStack(spacing: 0) {
            // Grade filter
            Picker("年级", selection: $selectedGrade) {
                ForEach(grades, id: \.self) { g in Text(g).tag(g) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Class filter
            if !availableClasses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ClassChip(name: "全部", isActive: selectedClass == nil) {
                            selectedClass = nil
                        }
                        ForEach(availableClasses, id: \.self) { cn in
                            ClassChip(name: cn, isActive: selectedClass == cn) {
                                selectedClass = cn
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }

            List {
                ForEach(filteredStudents) { student in
                    NavigationLink(destination: StudentDetailView(student: student)) {
                        StudentRow(student: student)
                            .padding(12)
                            .liquidGlassCard(cornerRadius: 18, tint: .indigo, interactive: true)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: deleteStudents)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .liquidGlassBackground()
    }

    private func deleteStudents(at offsets: IndexSet) {
        for i in offsets { context.delete(filteredStudents[i]) }
        try? context.save()
    }
}

// MARK: - Student Row

struct StudentRow: View {
    let student: Student

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(student.name.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(gradeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.body).fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(student.grade)
                    if let cls = student.classGroup {
                        Text("·"); Text(cls.name)
                    }
                    Text("· 加入 \(student.joinDate.formatted(.dateTime.month(.wide).day()))")
                }
                .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if let fb = student.latestFeedback {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.caption2)
                    Text("\(fb.overallRating)").font(.subheadline).fontWeight(.semibold)
                }
                .foregroundStyle(.indigo)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(.indigo.opacity(0.1)))
            }
        }
        .padding(.vertical, 4)
    }

    private var gradeColor: Color {
        switch student.grade {
        case "高一": return .indigo
        case "高二": return .mint
        case "高三": return .orange
        default: return .indigo
        }
    }
}

#Preview {
    StudentListView()
        .modelContainer(previewContainer)
}
