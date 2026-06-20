import SwiftUI
import Charts

struct FeedbackDetailView: View {
    let feedback: Feedback

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showExportOptions = false
    @State private var exportURL: URL?
    @State private var copyConfirmation = false

    private var previousFeedback: Feedback? {
        guard let student = feedback.student else { return nil }
        let all = student.feedbacks.sorted { $0.date > $1.date }
        guard let idx = all.firstIndex(where: { $0.id == feedback.id }),
              idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    private var studentAverage: Double {
        feedback.student?.averageRating ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ratingHero
                metaCard
                skillBarsCard
                progressRingsCard
                textCard
                if let prev = previousFeedback {
                    comparisonChart(previous: prev)
                }
                deleteButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .liquidGlassBackground()
        .navigationTitle(feedback.lessonTopic)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .platformTrailing) {
                Menu {
                    Button { copyToClipboard() } label: {
                        Label("复制文本", systemImage: "doc.on.doc")
                    }
                    Button {
                        exportURL = FeedbackExporter.txtURL(for: feedback)
                    } label: {
                        Label("导出 TXT", systemImage: "doc.text")
                    }
                    #if os(iOS)
                    Button {
                        exportURL = FeedbackExporter.pdfURL(for: feedback)
                    } label: {
                        Label("导出 PDF", systemImage: "doc.richtext")
                    }
                    #endif
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .alert("删除反馈", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                context.delete(feedback)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("此操作不可撤销，确定要删除这条反馈吗？")
        }
        .sheet(isPresented: Binding<Bool>(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = FeedbackExporter.plainText(for: feedback)
        #endif
    }

    // MARK: - Rating Hero

    private var ratingHero: some View {
        VStack(spacing: 8) {
            Text(ratingEmoji(feedback.overallRating))
                .font(.system(size: 48))
            Text("综合评分 \(feedback.overallRating)/5")
                .font(.title3)
                .fontWeight(.bold)

            // vs average indicator
            if studentAverage > 0 {
                let diff = Double(feedback.overallRating) - studentAverage
                HStack(spacing: 4) {
                    Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                    Text(String(format: "%.1f", abs(diff)))
                    Text(diff >= 0 ? "高于" : "低于")
                    Text("均分 \(String(format: "%.1f", studentAverage))")
                }
                .font(.caption)
                .foregroundStyle(diff >= 0 ? .mint : .orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill((diff >= 0 ? Color.mint : Color.orange).opacity(0.1)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .liquidGlassCard(cornerRadius: 24, tint: ratingColor(feedback.overallRating))
    }

    // MARK: - Meta Card

    private var metaCard: some View {
        HStack {
            metaItem(icon: "person", label: "学生", value: feedback.student?.name ?? "-")
            Divider().frame(height: 30)
            metaItem(icon: "calendar", label: "日期", value: feedback.date.formatted(.dateTime.month(.wide).day()))
            Divider().frame(height: 30)
            metaItem(icon: "book.pages", label: "课题", value: feedback.lessonTopic)
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Skill Bars Card (Chart-style)

    private var skillBarsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "技能维度评分", icon: "chart.bar.fill")

            ForEach(feedback.skillScores, id: \.skillName) { score in
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: skillIcon(score.skillName))
                            .frame(width: 18)
                            .font(.caption)
                        Text(score.skillName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(score.score)/5")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(skillBarColor(score.score))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(.quat).frame(height: 8)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(skillBarColor(score.score).gradient)
                                .frame(width: max(CGFloat(score.score) / 5 * geo.size.width, 8), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Progress Rings

    private var progressRingsCard: some View {
        HStack(spacing: 24) {
            ringView(
                value: feedback.homeworkCompletion,
                title: "作业完成度",
                color: .indigo,
                icon: "doc.text"
            )
            ringView(
                value: feedback.classParticipation,
                title: "课堂参与度",
                color: .mint,
                icon: "hand.raised"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .mint)
    }

    private func ringView(value: Int, title: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(.quat, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(value) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(value)%")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 90, height: 90)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Comparison Chart

    private func comparisonChart(previous: Feedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "与上次对比", icon: "arrow.left.arrow.right")

            // Overall rating comparison
            HStack(spacing: 0) {
                VStack {
                    Text("\(feedback.overallRating)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.indigo)
                    Text("本次")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                let diff = feedback.overallRating - previous.overallRating
                VStack {
                    Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(diff >= 0 ? .mint : .orange)
                    Text("变化")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("\(previous.overallRating)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("上次")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            Divider()

            // Skill-by-skill comparison bars
            ForEach(feedback.skillScores, id: \.skillName) { currentSkill in
                let prevSkill = previous.skillScores.first(where: { $0.skillName == currentSkill.skillName })
                let prevScore = prevSkill?.score ?? 0
                let skillDiff = currentSkill.score - prevScore

                VStack(spacing: 4) {
                    HStack {
                        Text(currentSkill.skillName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if prevScore > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: skillDiff >= 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(skillDiff))")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(skillDiff >= 0 ? .mint : .orange)
                        }
                    }
                    HStack(spacing: 4) {
                        barSegment(value: currentSkill.score, maxVal: 5, color: .indigo)
                        if prevScore > 0 {
                            barSegment(value: prevScore, maxVal: 5, color: .secondary.opacity(0.5))
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    private func barSegment(value: Int, maxVal: Int, color: Color) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: max(CGFloat(value) / CGFloat(maxVal) * geo.size.width, 4))
        }
    }

    // MARK: - Text Card

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "详细评价", icon: "text.quote")
            Divider()
            if !feedback.learningContent.isEmpty {
                textSection(icon: "book.fill", title: "学习内容", content: feedback.learningContent, color: .indigo)
                Divider()
            }
            if !feedback.strengths.isEmpty {
                textSection(icon: "hand.thumbsup.fill", title: "优点", content: feedback.strengths, color: .mint)
                Divider()
            }
            if !feedback.weaknesses.isEmpty {
                textSection(icon: "exclamationmark.triangle.fill", title: "改进点", content: feedback.weaknesses, color: .orange)
                Divider()
            }
            textSection(icon: "pencil.line", title: "教师评语",
                        content: feedback.teacherNotes.isEmpty ? "暂无评语" : feedback.teacherNotes,
                        color: .indigo)
            if !feedback.homework.isEmpty {
                Divider()
                textSection(icon: "pencil.and.list.clipboard.fill", title: "课后作业", content: feedback.homework, color: .mint)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("删除此反馈", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red.opacity(0.1))
        .foregroundStyle(.red)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func metaItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.indigo)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func textSection(icon: String, title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(content)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
    }

    private func skillIcon(_ name: String) -> String {
        switch name {
        case "概念理解": return "lightbulb"
        case "计算能力": return "function"
        case "解题思路": return "flowchart"
        case "规范书写": return "pencil.and.ruler"
        default: return "questionmark"
        }
    }

    private func skillBarColor(_ score: Int) -> Color {
        switch score {
        case 1, 2: return .orange
        case 3: return .indigo
        case 4, 5: return .mint
        default: return .indigo
        }
    }

    private func ratingEmoji(_ r: Int) -> String {
        ["", "😞", "😐", "🙂", "😊", "🌟"][r]
    }

    private func ratingColor(_ r: Int) -> Color {
        switch r { case 1,2: return .orange; case 3: return .indigo; case 4,5: return .mint; default: return .indigo }
    }
}

#Preview {
    NavigationStack {
        FeedbackDetailView(feedback: Feedback(lessonTopic: "三角函数", overallRating: 4))
    }
    .modelContainer(previewContainer)
}
