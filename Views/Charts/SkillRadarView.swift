import SwiftUI

/// Bar chart comparing latest vs previous skill scores
struct SkillRadarView: View {
    let latestFeedback: Feedback?
    let previousFeedback: Feedback?

    struct SkillComparison: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let current: Int
        let previous: Int
        var diff: Int { current - previous }
    }

    var skills: [SkillComparison] {
        let skillNames = ["概念理解", "计算能力", "解题思路", "规范书写"]
        let icons = ["lightbulb", "function", "flowchart", "pencil.and.ruler"]

        return skillNames.enumerated().map { i, name in
            let cur = latestFeedback?.skillScores.first(where: { $0.skillName == name })?.score ?? 0
            let prev = previousFeedback?.skillScores.first(where: { $0.skillName == name })?.score ?? 0
            return SkillComparison(name: name, icon: icons[i], current: cur, previous: prev)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("技能对比")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("本次 vs 上次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if latestFeedback == nil {
                Text("暂无反馈数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(skills) { skill in
                    skillRow(skill)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, tint: .indigo)
    }

    private func skillRow(_ skill: SkillComparison) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: skill.icon)
                    .frame(width: 20)
                    .foregroundStyle(.indigo)
                Text(skill.name)
                    .font(.subheadline)
                Spacer()

                // Diff badge
                if skill.previous > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: skill.diff >= 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(skill.diff))")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(skill.diff >= 0 ? .mint : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(skill.diff >= 0 ? .mint.opacity(0.12) : .orange.opacity(0.12))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Bar comparison
            HStack(spacing: 8) {
                // Current bar
                bar(value: skill.current, maxVal: 5, color: .indigo)
                    .overlay(alignment: .trailing) {
                        Text("\(skill.current)")
                            .font(.caption2)
                            .foregroundStyle(.indigo)
                            .padding(.trailing, 4)
                    }

                // Previous bar (ghost)
                if skill.previous > 0 {
                    bar(value: skill.previous, maxVal: 5, color: .secondary.opacity(0.4))
                }
            }
        }
    }

    private func bar(value: Int, maxVal: Int, color: Color) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: max(CGFloat(value) / CGFloat(maxVal) * geo.size.width, 4))
        }
        .frame(height: 20)
        .background(.quat, in: RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    SkillRadarView(latestFeedback: nil, previousFeedback: nil)
}
