import SwiftUI
import AppKit

public struct AstorkaTheme {
    // MARK: - Core Palette (Obsidian & Cyber)
    public static let bgDark = Color(red: 0.047, green: 0.051, blue: 0.067)      // #0C0D11
    public static let surfaceDark = Color(red: 0.078, green: 0.086, blue: 0.118) // #14161E
    public static let cardDark = Color(red: 0.110, green: 0.122, blue: 0.165)    // #1C1F2A
    public static let cardDarkHover = Color(red: 0.145, green: 0.161, blue: 0.220) // #252938
    public static let panelHeader = Color(red: 0.063, green: 0.071, blue: 0.098) // #101219

    // MARK: - Neon Accents
    public static let cyanNeon = Color(red: 0.0, green: 0.92, blue: 1.0)
    public static let purpleNeon = Color(red: 0.66, green: 0.28, blue: 1.0)
    public static let emeraldNeon = Color(red: 0.08, green: 0.88, blue: 0.52)
    public static let amberNeon = Color(red: 1.0, green: 0.72, blue: 0.12)
    public static let redNeon = Color(red: 1.0, green: 0.32, blue: 0.32)

    // MARK: - Borders & Dividers
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderHighlight = Color.white.opacity(0.18)
    public static let borderCyanGlow = Color(red: 0.0, green: 0.92, blue: 1.0).opacity(0.35)

    // MARK: - Gradients
    public static let cyberGradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.88, blue: 1.0), Color(red: 0.62, green: 0.25, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let emeraldGradient = LinearGradient(
        colors: [Color(red: 0.08, green: 0.88, blue: 0.52), Color(red: 0.0, green: 0.75, blue: 0.9)],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let amberGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.72, blue: 0.12), Color(red: 1.0, green: 0.45, blue: 0.1)],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let darkCardGradient = LinearGradient(
        colors: [cardDark, Color(red: 0.09, green: 0.10, blue: 0.14)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View Modifiers

public struct AstorkaCardModifier: ViewModifier {
    var isHovered: Bool = false
    var cornerRadius: CGFloat = 12

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? AstorkaTheme.cardDarkHover : AstorkaTheme.cardDark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? AstorkaTheme.borderCyanGlow : AstorkaTheme.borderSubtle, lineWidth: isHovered ? 1.5 : 1)
            )
            .shadow(color: isHovered ? AstorkaTheme.cyanNeon.opacity(0.12) : Color.black.opacity(0.3), radius: isHovered ? 14 : 6, y: 3)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

public extension View {
    func astorkaCard(isHovered: Bool = false, cornerRadius: CGFloat = 12) -> some View {
        modifier(AstorkaCardModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }

    func astorkaBadge(color: Color = AstorkaTheme.cyanNeon) -> some View {
        self
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.14))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .foregroundStyle(color)
    }
}

// MARK: - Custom Button Styles

public struct AstorkaGlowButtonStyle: ButtonStyle {
    var color: Color = AstorkaTheme.cyanNeon
    @State private var isHovered: Bool = false

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(isHovered ? 0.95 : 0.8), color.opacity(isHovered ? 0.8 : 0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .foregroundColor(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(isHovered ? 0.45 : 0.2), radius: isHovered ? 12 : 4, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .onHover { h in isHovered = h }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

public struct AstorkaGlassButtonStyle: ButtonStyle {
    @State private var isHovered: Bool = false

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
            )
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.white.opacity(0.3) : AstorkaTheme.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .onHover { h in isHovered = h }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
