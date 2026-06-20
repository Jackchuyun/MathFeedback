import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        TabView {
            // Page 1
            VStack(spacing: 24) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.indigo.gradient)
                Text("欢迎使用 MathFeedback")
                    .font(.title)
                    .fontWeight(.bold)
                Text("专业的数学培训课后反馈工具\n专为高中数学教师设计")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)

            // Page 2
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 64))
                    .foregroundStyle(.mint.gradient)
                Text("追踪学生进步")
                    .font(.title)
                    .fontWeight(.bold)
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "person.2", text: "添加学生并创建班级")
                    FeatureRow(icon: "square.and.pencil", text: "课后生成反馈报告")
                    FeatureRow(icon: "chart.bar", text: "可视化进步曲线和技能对比")
                    FeatureRow(icon: "bell", text: "智能提醒需关注的学生")
                }
            }
            .padding(40)

            // Page 3
            VStack(spacing: 24) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 64))
                    .foregroundStyle(.indigo.gradient)
                Text("数据安全")
                    .font(.title)
                    .fontWeight(.bold)
                Text("所有数据仅存储在你的设备上\n你可以随时导出备份")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text("开始使用")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(.indigo.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .liquidGlassControl(cornerRadius: 18, tint: .indigo)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding(40)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .liquidGlassBackground()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
