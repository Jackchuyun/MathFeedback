import SwiftUI
import SwiftData

struct StudentDetailView: View {
    let student: Student

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allFeedbacks: [Feedback]

    @State private var showFeedbackForm = false
    @State private var showEditSheet = false
    @State private var isExporting = false
    @State private var reportURL: URL?
    @State private var showDeleteAlert = false

    // Use all fetched feedbacks for this specific student
    private var studentFeedbacks: [Feedback] {
        allFeedbacks.filter { $0.student?.id == student.id }
    }

    private var sortedFeedbacks: [Feedback] {
        studentFeedbacks.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                progressChartSection
                skillComparisonSection
                weakPointSection
                trendSummarySection
                feedbackHistorySection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .liquidGlassBackground()
        .navigationTitle("学生详情")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .platformTrailing) {
                HStack(spacing: 16) {
                    Button {
                        isExporting = true
                        Task {
                            reportURL = await ReportExporter.exportPDF(for: student)
                            isExporting = false
                        }
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                    Button { showFeedbackForm = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.indigo)
                    }
                    Menu {
                        Button { showEditSheet = true } label: {
                            Label("编辑信息", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("删除学生", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(preselectedStudent: student)
        }
        .sheet(isPresented: $showEditSheet) {
            StudentFormView(student: student)
        }
        .alert("删除学生", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                context.delete(student)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("将同时删除该学生的全部反馈记录，此操作不可撤销。")
        }
        .sheet(isPresented: Binding<Bool>(
            get: { reportURL != nil },
            set: { if !$0 { reportURL = nil } }
        )) {
            if let url = reportURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradeGradient)
                    .frame(width: 72, height: 72)
                Text(String(student.name.prefix(1)))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(student.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .font(.caption)
                Text(student.grade)
                    .font(.subheadline)
            }
            .foregroundStyle(.indigo)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(.indigo.opacity(0.1)))

            HStack(spacing: 24) {
                statItem(value: "\(sortedFeedbacks.count)", label: "反馈次数")
                statItem(value: String(format: "%.1f", averageRating), label: "平均评分")
                statItem(value: student.joinDate.formatted(.dateTime.month(.wide).day()), label: "加入日期")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .liquidGlassCard(cornerRadius: 24, tint: .indigo)
    }

    // MARK: - Progress Chart

    @ViewBuilder
    private var progressChartSection: some View {
        if sortedFeedbacks.count >= 2 {
            ProgressChart(feedbacks: Array(sortedFeedbacks.reversed().suffix(10)))
        }
    }

    // MARK: - Skill Comparison

    @ViewBuilder
    private var skillComparisonSection: some View {
        if let latest = sortedFeedbacks.first {
            SkillRadarView(
                latestFeedback: latest,
                previousFeedback: sortedFeedbacks.count > 1 ? sortedFeedbacks[1] : nil
            )
        }
    }

    // MARK: - Weak Points

    @ViewBuilder
    private var weakPointSection: some View {
        let weak = weakSkills
        if !weak.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("持续薄弱点")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 8) {
                    ForEach(weak, id: \.self) { skill in
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.caption2)
                            Text(skill)
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.orange.opacity(0.1)))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .liquidGlassCard(cornerRadius: 18, tint: .orange)
        }
    }

    // MARK: - Trend Summary

    @ViewBuilder
    private var trendSummarySection: some View {
        if sortedFeedbacks.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundStyle(.indigo)
                    Text("趋势总结")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text(trendDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .liquidGlassCard(cornerRadius: 18, tint: .indigo)
        }
    }

    // MARK: - Feedback History

    private var feedbackHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .foregroundStyle(.indigo)
                Text("反馈历史")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showFeedbackForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.indigo)
                }
                .buttonStyle(.plain)
            }

            if sortedFeedbacks.isEmpty {
                VStack(spacing: 14) {
                    Text("暂无反馈记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        showFeedbackForm = true
                    } label: {
                        Label("添加第一条反馈", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(sortedFeedbacks) { fb in
                    NavigationLink(destination: FeedbackDetailView(feedback: fb)) {
                        FeedbackHistoryRow(feedback: fb)
                            .padding(12)
                            .background(.quaternary.opacity(0.001), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Computed properties (local, not on model)

    private var averageRating: Double {
        guard !sortedFeedbacks.isEmpty else { return 0 }
        let total = sortedFeedbacks.reduce(0) { $0 + $1.overallRating }
        return Double(total) / Double(sortedFeedbacks.count)
    }

    private var weakSkills: [String] {
        let recent = Array(sortedFeedbacks.prefix(3))
        let allSkills = ["概念理解", "计算能力", "解题思路", "规范书写"]
        return allSkills.filter { skill in
            let scores = recent.flatMap { $0.skillScores }.filter { $0.skillName == skill }
            guard !scores.isEmpty else { return false }
            let avg = Double(scores.reduce(0) { $0 + $1.score }) / Double(scores.count)
            return avg < 3
        }
    }

    private var trendDescription: String {
        let sorted = sortedFeedbacks.reversed() as [Feedback]
        guard sorted.count >= 2 else { return "反馈数据不足，请至少添加 2 次反馈" }
        let recent = Array(sorted.suffix(4))
        let ratings = recent.map { $0.overallRating }
        let diff = ratings.last! - ratings.first!
        if diff > 0 { return "近 \(recent.count) 次反馈总体 📈上升，表现持续进步" }
        if diff < 0 { return "近 \(recent.count) 次反馈总体 📉下降，需要更多关注" }
        return "近 \(recent.count) 次反馈总体 ➡️稳定，保持当前节奏"
    }

    // MARK: - Helpers

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var gradeGradient: LinearGradient {
        switch student.grade {
        case "高一": return LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "高三": return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Feedback History Row

struct FeedbackHistoryRow: View {
    let feedback: Feedback

    var body: some View {
        HStack(spacing: 12) {
            Text("\(feedback.overallRating)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(ratingColor(feedback.overallRating).gradient, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(feedback.lessonTopic)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(feedback.date, format: .dateTime.year().month(.wide).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quat)
        }
        .padding(.vertical, 6)
    }

    private func ratingColor(_ r: Int) -> Color {
        switch r {
        case 1, 2: return .orange
        case 3: return .indigo
        case 4, 5: return .mint
        default: return .indigo
        }
    }
}

#Preview {
    NavigationStack {
        StudentDetailView(student: Student(name: "李明", grade: "高二"))
    }
    .modelContainer(previewContainer)
}
