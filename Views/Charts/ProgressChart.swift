import SwiftUI
import Charts

struct ProgressChart: View {
    let feedbacks: [Feedback]
    var highlightFeedbackId: UUID? = nil

    struct DataPoint: Identifiable {
        let id = UUID()
        let feedbackId: UUID
        let date: Date
        let rating: Int
        let index: Int
        let isHighlighted: Bool
    }

    var points: [DataPoint] {
        feedbacks.enumerated().map { i, fb in
            DataPoint(
                feedbackId: fb.id,
                date: fb.date,
                rating: fb.overallRating,
                index: i + 1,
                isHighlighted: fb.id == highlightFeedbackId
            )
        }
    }

    var trendIcon: String {
        guard points.count >= 2 else { return "minus" }
        let diff = points.last!.rating - points.first!.rating
        if diff > 0 { return "arrow.up.right" }
        if diff < 0 { return "arrow.down.right" }
        return "arrow.right"
    }

    var trendColor: Color {
        guard points.count >= 2 else { return .secondary }
        let diff = points.last!.rating - points.first!.rating
        if diff > 0 { return .mint }
        if diff < 0 { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("综合评分趋势")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: trendIcon)
                    .foregroundStyle(trendColor)
                    .fontWeight(.bold)
            }

            if points.count < 2 {
                Text("需要至少 2 次反馈才能显示趋势图")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("次数", point.index),
                        y: .value("评分", point.rating)
                    )
                    .foregroundStyle(.indigo.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    AreaMark(
                        x: .value("次数", point.index),
                        y: .value("评分", point.rating)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo.opacity(0.2), .indigo.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Normal points
                    if !point.isHighlighted {
                        PointMark(
                            x: .value("次数", point.index),
                            y: .value("评分", point.rating)
                        )
                        .foregroundStyle(.indigo)
                        .symbolSize(36)
                    }

                    // Highlighted point — larger, with ring
                    if point.isHighlighted {
                        PointMark(
                            x: .value("次数", point.index),
                            y: .value("评分", point.rating)
                        )
                        .foregroundStyle(.orange.gradient)
                        .symbolSize(100)
                        .annotation(position: .top) {
                            Text("本次")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .chartYScale(domain: 0.8...5.2)
                .chartXScale(domain: 1...points.count)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let r = value.as(Int.self) {
                                Text(ratingEmoji(r))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    private func ratingEmoji(_ r: Int) -> String {
        ["", "😞", "😐", "🙂", "😊", "🌟"][r]
    }
}

#Preview {
    ProgressChart(feedbacks: [])
}
