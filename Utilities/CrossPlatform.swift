import SwiftUI

#if os(macOS)
import AppKit

extension Color {
    static let platformGroupedBackground = Color(nsColor: .controlBackgroundColor)
}

extension ToolbarItemPlacement {
    static let platformTrailing: ToolbarItemPlacement = .automatic
}
#else
import UIKit

extension Color {
    static let platformGroupedBackground = Color(uiColor: .systemGroupedBackground)
}

extension ToolbarItemPlacement {
    static let platformTrailing: ToolbarItemPlacement = .topBarTrailing
}
#endif

extension ShapeStyle where Self == Color {
    static var quat: Color { .secondary.opacity(0.3) }
}
