import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Student.name) private var students: [Student]
    @Query(sort: \ClassGroup.name) private var classGroups: [ClassGroup]

    @State private var showFeedbackForm = false
    @State private var selectedFeedback: Feedback? = nil
    @State private var selectedClass: ClassGroup? = nil

    private var filteredStudents: [Student] {
        guard let cls = selectedClass else { return students }
        return students.filter { $0.classGroup?.id == cls.id }
    }

    private var thisWeekFeedbacks: [Feedback] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return filteredStudents.flatMap { $0.feedbacks }.filter { $0.date >= weekAgo }
    }

    private var totalFeedbacks: Int {
        filteredStudents.reduce(0) { $0 + $1.feedbacks.count }
    }

    private var weeklyAverage: Double {
        guard !thisWeekFeedbacks.isEmpty else { return 0 }
        return Double(thisWeekFeedbacks.reduce(0) { $0 + $1.overallRating }) / Double(thisWeekFeedbacks.count)
    }

    private var attentionStudents: [Student] {
        filteredStudents.filter { $0.needsAttention || $0.isStale }
    }

    private var recentActivities: [(Student, Feedback)] {
        filteredStudents
            .flatMap { s in s.feedbacks.map { (s, $0) } }
            .sorted { $0.1.date > $1.1.date }
            .prefix(8)
            .map { ($0.0, $0.1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header date
                    dateHeader

                    // Class filter
                    if !classGroups.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ClassChip(name: "全部", isActive: selectedClass == nil) {
                                    selectedClass = nil
                                }
                                ForEach(classGroups) { cls in
                                    ClassChip(name: cls.name, isActive: selectedClass?.id == cls.id) {
                                        selectedClass = cls
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Stats cards
                    statsGrid

                    // Attention section
                    if !attentionStudents.isEmpty {
                        attentionSection
                    }

                    // Recent activity
                    if !recentActivities.isEmpty {
                        recentActivitySection
                    }

                    // Empty state
                    if students.isEmpty {
                        welcomeSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .liquidGlassBackground()
            .navigationTitle("反馈")
            .toolbar {
                ToolbarItem(placement: .platformTrailing) {
                    Button { showFeedbackForm = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showFeedbackForm) {
                FeedbackFormView()
            }
            .navigationDestination(item: $selectedFeedback) { fb in
                FeedbackDetailView(feedback: fb)
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Text(Date.now, format: .dateTime.month(.wide).day().weekday(.wide))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "square.and.pencil",
                value: "\(thisWeekFeedbacks.count)",
                label: "本周反馈",
                color: .indigo
            )
            StatCard(
                icon: "star.fill",
                value: String(format: "%.1f", weeklyAverage),
                label: "本周均分",
                color: .mint
            )
            StatCard(
                icon: "person.2",
                value: "\(filteredStudents.count)",
                label: "学生总数",
                color: .indigo
            )
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(totalFeedbacks)",
                label: "累计反馈",
                color: .mint
            )
        }
    }

    // MARK: - Attention Section

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.orange)
                Text("需关注")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(attentionStudents.count) 人")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(attentionStudents) { student in
                NavigationLink(destination: StudentDetailView(student: student)) {
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(.orange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Text(String(student.name.prefix(1)))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(student.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text(attentionReason(for: student))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.quat)
                    }
                    .padding(12)
                    .liquidGlassControl(cornerRadius: 12, tint: .orange)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.indigo)
                Text("最近动态")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(Array(recentActivities.enumerated()), id: \.element.1.id) { _, item in
                Button {
                    selectedFeedback = item.1
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(ratingColor(item.1.overallRating))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.0.name) · \(item.1.lessonTopic)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text(item.1.date, format: .relative(presentation: .named))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(item.1.overallRating)/5")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(ratingColor(item.1.overallRating).opacity(0.12)))
                            .foregroundStyle(ratingColor(item.1.overallRating))
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if item.1.id != recentActivities.last?.1.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    // MARK: - Welcome

    private var welcomeSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 52))
                .foregroundStyle(.indigo.opacity(0.3))
                .padding(.top, 40)
            Text("开始记录学生成长")
                .font(.title3)
                .fontWeight(.semibold)
            Text("添加学生后即可创建课后反馈\n跟踪每位学生的学习轨迹")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func attentionReason(for student: Student) -> String {
        if student.isStale { return "超过 30 天未反馈" }
        if student.needsAttention { return "近期评分连续下降" }
        return ""
    }

    private func ratingEmoji(_ r: Int) -> String {
        ["", "😞", "😐", "🙂", "😊", "🌟"][r]
    }

    private func ratingColor(_ r: Int) -> Color {
        switch r { case 1,2: return .orange; case 3: return .indigo; case 4,5: return .mint; default: return .indigo }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: color)
    }
}

struct ClassChip: View {
    let name: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isActive ? .white : .secondary)
                .liquidGlassCapsule(tint: isActive ? .indigo : nil)
                .background(isActive ? Color.indigo.opacity(0.72) : .clear, in: Capsule())
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(previewContainer)
}
