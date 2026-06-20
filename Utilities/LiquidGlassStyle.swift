import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            Color.platformGroupedBackground

            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.16),
                    Color.mint.opacity(0.10),
                    Color.orange.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.white.opacity(0.24), .clear],
                center: .topLeading,
                startRadius: 12,
                endRadius: 360
            )

            RadialGradient(
                colors: [Color.mint.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 24,
                endRadius: 320
            )
        }
    }
}

extension View {
    @ViewBuilder
    func liquidGlassBackground() -> some View {
        background {
            LiquidGlassBackground()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    func liquidGlassCard(
        cornerRadius: CGFloat = 18,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, macOS 26.0, *) {
            let glass = (tint.map { Glass.regular.tint($0.opacity(0.18)) } ?? .regular)
                .interactive(interactive)

            self
                .background(.clear, in: shape)
                .glassEffect(glass, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(0.28), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
        } else {
            self
                .background(.regularMaterial, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(0.18), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
        }
    }

    @ViewBuilder
    func liquidGlassControl(
        cornerRadius: CGFloat = 12,
        tint: Color? = nil,
        interactive: Bool = true
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, macOS 26.0, *) {
            let glass = (tint.map { Glass.clear.tint($0.opacity(0.20)) } ?? .clear)
                .interactive(interactive)

            self
                .background(.clear, in: shape)
                .glassEffect(glass, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(0.25), lineWidth: 0.6)
                }
        } else {
            self
                .background(.regularMaterial, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(0.16), lineWidth: 0.6)
                }
        }
    }

    @ViewBuilder
    func liquidGlassCapsule(tint: Color? = nil, interactive: Bool = true) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            let glass = (tint.map { Glass.clear.tint($0.opacity(0.22)) } ?? .clear)
                .interactive(interactive)

            self
                .background(.clear, in: Capsule())
                .glassEffect(glass, in: Capsule())
                .overlay {
                    Capsule().stroke(.white.opacity(0.25), lineWidth: 0.6)
                }
        } else {
            self
                .background(.regularMaterial, in: Capsule())
                .overlay {
                    Capsule().stroke(.white.opacity(0.16), lineWidth: 0.6)
                }
        }
    }
}
