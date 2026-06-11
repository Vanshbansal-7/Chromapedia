// Chromapedia
// Views/Components/SharedComponents.swift

import SwiftUI

// MARK: - Hex Badge
struct HexBadge: View {
    let hex: String
    var style: BadgeStyle = .dark
    enum BadgeStyle { case dark, light, frosted }
    var body: some View {
        Text(hex)
            .font(.system(.caption, design: .monospaced, weight: .bold)).tracking(0.5)
            .foregroundStyle(style == .dark ? .white : style == .light ? .black : .primary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Group {
                if style == .dark { Color.black.opacity(0.6) }
                else if style == .light { Color.white.opacity(0.85) }
                else { Color.clear.background(.ultraThinMaterial) }
            })
            .clipShape(Capsule())
    }
}

// MARK: - Springy Button Style
struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

