import SwiftUI
import SwiftData

struct FeedbackFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Student.name) private var students: [Student]

    var preselectedStudent: Student? = nil

    @State private var selectedStudent: Student?
    @State private var date = Date()
    @State private var lessonTopic = ""
    @State private var overallRating = 3

    // Skill scores
    @State private var conceptScore = 3
    @State private var calculationScore = 3
    @State private var reasoningScore = 3
    @State private var writingScore = 3

    @State private var homeworkCompletion: Double = 80
    @State private var classParticipation: Double = 80
    @State private var learningContent = ""
    @State private var strengths = ""
    @State private var weaknesses = ""
    @State private var teacherNotes = ""
    @State private var homework = ""

    @State private var showTopicPicker = false
    @State private var showStudentForm = false
    @State private var isGeneratingTeacherNote = false
    @State private var generationErrorMessage = ""
    @State private var showGenerationError = false
    @AppStorage("deepSeekModel") private var deepSeekModel = DeepSeekTeacherNoteService.defaultModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if students.isEmpty && preselectedStudent == nil {
                    noStudentState
                        .padding(.horizontal, 16)
                        .padding(.top, 80)
                } else {
                    VStack(spacing: 20) {
                        studentAndTopicSection
                        overallRatingSection
                        skillScoresSection
                        progressSection
                        textInputSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .liquidGlassBackground()
            .navigationTitle("新反馈")
            #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !(students.isEmpty && preselectedStudent == nil) {
                    saveButton
                }
            }
            .sheet(isPresented: $showStudentForm) {
                StudentFormView()
            }
            .alert("生成失败", isPresented: $showGenerationError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(generationErrorMessage)
            }
            .onAppear {
                if let pre = preselectedStudent {
                    selectedStudent = pre
                }
            }
        }
    }

    private var noStudentState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 54))
                .foregroundStyle(.indigo.opacity(0.35))
            Text("先添加学生")
                .font(.title3)
                .fontWeight(.semibold)
            Text("创建反馈前需要先建立学生档案。添加后即可记录课后表现、生成反馈报告。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button {
                showStudentForm = true
            } label: {
                Label("添加学生", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Student & Topic

    private var studentAndTopicSection: some View {
        VStack(spacing: 12) {
            // Student picker
            Menu {
                ForEach(students) { s in
                    Button(s.name) { selectedStudent = s }
                }
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                    Text(selectedStudent?.name ?? "选择学生")
                        .foregroundStyle(selectedStudent == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .liquidGlassControl(cornerRadius: 14, tint: .indigo)
            }

            // Date picker
            HStack {
                Label("日期", systemImage: "calendar")
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(14)
            .liquidGlassControl(cornerRadius: 14, tint: .indigo)

            // Topic
            HStack {
                Label("课题", systemImage: "book.pages")
                Spacer()
                Menu {
                    ForEach(FeedbackGenerator.lessonTopics, id: \.self) { topic in
                        Button(topic) { lessonTopic = topic }
                    }
                } label: {
                    Text(lessonTopic.isEmpty ? "选择课题" : lessonTopic)
                        .foregroundStyle(lessonTopic.isEmpty ? .secondary : .primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .liquidGlassControl(cornerRadius: 14, tint: .indigo)
        }
    }

    // MARK: - Overall Rating

    private var overallRatingSection: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "综合评分", icon: "star.fill")

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            overallRating = rating
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(ratingEmoji(rating))
                                .font(.title2)
                            Text("\(rating)")
                                .font(.caption2)
                                .foregroundStyle(overallRating == rating ? .indigo : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(overallRating == rating ? .indigo.opacity(0.12) : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(overallRating == rating ? .indigo.opacity(0.3) : .clear, lineWidth: 1)
                        )
                        .scaleEffect(overallRating == rating ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Skill Scores

    private var skillScoresSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "技能维度", icon: "chart.bar.doc.horizontal")

            SkillRatingRow(icon: "lightbulb", name: "概念理解", rating: $conceptScore)
            Divider()
            SkillRatingRow(icon: "function", name: "计算能力", rating: $calculationScore)
            Divider()
            SkillRatingRow(icon: "flowchart", name: "解题思路", rating: $reasoningScore)
            Divider()
            SkillRatingRow(icon: "pencil.and.ruler", name: "规范书写", rating: $writingScore)
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Progress Bars

    private var progressSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "学习指标", icon: "gauge.with.needle")

            VStack(spacing: 6) {
                HStack {
                    Label("作业完成度", systemImage: "doc.text")
                    Spacer()
                    Text("\(Int(homeworkCompletion))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.indigo)
                        .contentTransition(.numericText())
                }
                Slider(value: $homeworkCompletion, in: 0...100, step: 5)
                    .tint(.indigo)
            }

            VStack(spacing: 6) {
                HStack {
                    Label("课堂参与度", systemImage: "hand.raised")
                    Spacer()
                    Text("\(Int(classParticipation))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.mint)
                        .contentTransition(.numericText())
                }
                Slider(value: $classParticipation, in: 0...100, step: 5)
                    .tint(.mint)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .mint)
    }

    // MARK: - Text Inputs

    private var textInputSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "详细评价", icon: "text.quote")

            // Learning content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("学习内容", systemImage: "book")
                        .font(.subheadline)
                        .foregroundStyle(.indigo)
                    Spacer()
                    if !lessonTopic.isEmpty {
                        Button {
                            learningContent = FeedbackGenerator.defaultLearningContent(for: lessonTopic)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "sparkles")
                                Text("生成提示")
                            }
                            .font(.caption2)
                            .foregroundStyle(.indigo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                TextEditor(text: $learningContent)
                    .frame(minHeight: 50)
                    .padding(8)
                    .liquidGlassControl(cornerRadius: 10)
                    .font(.body)
            }

            // Strengths with template chips
            VStack(alignment: .leading, spacing: 8) {
                Label("优点", systemImage: "hand.thumbsup")
                    .font(.subheadline)
                    .foregroundStyle(.mint)

                ChipSelector(phrases: FeedbackGenerator.strengthPhrases) { phrase in
                    appendToField(&strengths, phrase: phrase)
                }

                TextEditor(text: $strengths)
                    .frame(minHeight: 50)
                    .padding(8)
                    .liquidGlassControl(cornerRadius: 10)
                    .font(.body)
            }

            // Weaknesses with template chips
            VStack(alignment: .leading, spacing: 8) {
                Label("改进点", systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.orange)

                ChipSelector(phrases: FeedbackGenerator.weaknessPhrases) { phrase in
                    appendToField(&weaknesses, phrase: phrase)
                }

                TextEditor(text: $weaknesses)
                    .frame(minHeight: 50)
                    .padding(8)
                    .liquidGlassControl(cornerRadius: 10)
                    .font(.body)
            }

            // Teacher notes
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("教师评语", systemImage: "pencil.line")
                        .font(.subheadline)
                        .foregroundStyle(.indigo)
                    Spacer()
                    Button {
                        generateTeacherNote()
                    } label: {
                        HStack(spacing: 4) {
                            if isGeneratingTeacherNote {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGeneratingTeacherNote ? "生成中" : "AI 生成")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isGeneratingTeacherNote || selectedStudent == nil || lessonTopic.isEmpty)
                }
                TextEditor(text: $teacherNotes)
                    .frame(minHeight: 72)
                    .padding(8)
                    .liquidGlassControl(cornerRadius: 10)
                    .font(.body)
            }

            // Homework
            VStack(alignment: .leading, spacing: 8) {
                Label("课后作业", systemImage: "pencil.and.list.clipboard")
                    .font(.subheadline)
                    .foregroundStyle(.mint)
                TextEditor(text: $homework)
                    .frame(minHeight: 50)
                    .padding(8)
                    .liquidGlassControl(cornerRadius: 10)
                    .font(.body)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("保存反馈")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                (selectedStudent != nil && !lessonTopic.isEmpty)
                    ? Color.indigo.gradient
                    : Color.gray.opacity(0.3).gradient
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedStudent == nil || lessonTopic.isEmpty)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .liquidGlassCard(cornerRadius: 24, tint: .indigo)
    }

    // MARK: - Actions

    private func appendToField(_ field: inout String, phrase: String) {
        if field.isEmpty {
            field = phrase
        } else {
            field += "\n" + phrase
        }
    }

    private func save() {
        guard let student = selectedStudent, !lessonTopic.isEmpty else { return }

        let skills = [
            SkillScore(skillName: "概念理解", score: conceptScore),
            SkillScore(skillName: "计算能力", score: calculationScore),
            SkillScore(skillName: "解题思路", score: reasoningScore),
            SkillScore(skillName: "规范书写", score: writingScore),
        ]

        let feedback = Feedback(
            date: date,
            lessonTopic: lessonTopic,
            learningContent: learningContent,
            overallRating: overallRating,
            strengths: strengths,
            weaknesses: weaknesses,
            teacherNotes: teacherNotes,
            homework: homework,
            homeworkCompletion: Int(homeworkCompletion),
            classParticipation: Int(classParticipation),
            skillScores: skills
        )
        feedback.student = student
        context.insert(feedback)
        try? context.save()
        dismiss()
    }

    private func generateTeacherNote() {
        guard let student = selectedStudent else {
            presentGenerationError("请先选择学生。")
            return
        }

        guard !lessonTopic.isEmpty else {
            presentGenerationError("请先选择课题。")
            return
        }

        let input = TeacherNoteInput(
            studentName: student.name,
            grade: student.grade,
            className: student.classGroup?.name,
            lessonTopic: lessonTopic,
            learningContent: learningContent,
            overallRating: overallRating,
            conceptScore: conceptScore,
            calculationScore: calculationScore,
            reasoningScore: reasoningScore,
            writingScore: writingScore,
            homeworkCompletion: Int(homeworkCompletion),
            classParticipation: Int(classParticipation),
            strengths: strengths,
            weaknesses: weaknesses
        )

        isGeneratingTeacherNote = true
        Task {
            do {
                let note = try await DeepSeekTeacherNoteService.generateTeacherNote(input: input, model: deepSeekModel)
                await MainActor.run {
                    teacherNotes = note
                    isGeneratingTeacherNote = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingTeacherNote = false
                    presentGenerationError(error.localizedDescription)
                }
            }
        }
    }

    private func presentGenerationError(_ message: String) {
        generationErrorMessage = message
        showGenerationError = true
    }

    private func ratingEmoji(_ r: Int) -> String {
        ["", "😞", "😐", "🙂", "😊", "🌟"][r]
    }
}

// MARK: - Subcomponents

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
        }
        .foregroundStyle(.secondary)
    }
}

struct SkillRatingRow: View {
    let icon: String
    let name: String
    @Binding var rating: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.indigo)
            Text(name)
                .font(.body)
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.body)
                        .foregroundStyle(star <= rating ? .indigo : .quat)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                rating = star
                            }
                        }
                }
            }
        }
    }
}

struct ChipSelector: View {
    let phrases: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(phrases, id: \.self) { phrase in
                    Button {
                        onSelect(phrase)
                    } label: {
                        Text(phrase)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .liquidGlassCapsule()
                            .foregroundStyle(.secondary)
                            .overlay(
                                Capsule().stroke(.quat, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    FeedbackFormView()
        .modelContainer(previewContainer)
}
