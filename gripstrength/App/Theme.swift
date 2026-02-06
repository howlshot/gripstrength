//
//  Theme.swift
//  gripstrength
//
//  Design system for Grip Strength app
//

import SwiftUI

enum Theme {
    // MARK: - Colors

    // Backgrounds
    static let background = Color(hex: "0D0D0D")
    static let cardBackground = Color(hex: "1A1A1A")
    static let elevatedBackground = Color(hex: "242424")

    // Accent Colors
    static let gold = Color(hex: "FFD700")
    static let goldDark = Color(hex: "B8860B")
    static let success = Color(hex: "4ADE80")
    static let warning = Color(hex: "FBBF24")
    static let error = Color(hex: "F87171")

    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let textTertiary = Color(hex: "6B7280")

    // MARK: - Typography

    static let displayFont = Font.system(size: 72, weight: .bold, design: .rounded)
    static let displayFontLarge = Font.system(size: 96, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 24, weight: .semibold, design: .default)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .medium, design: .default)
    static let labelFont = Font.system(size: 14, weight: .medium, design: .default)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radius

    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24

    // MARK: - Shadows

    static let shadowColor = Color.black.opacity(0.3)
    static let shadowRadius: CGFloat = 10
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadiusLG)
    }
}

struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                    .fill(Theme.cardBackground.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                            .stroke(Theme.gold.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func glassCardStyle() -> some View {
        modifier(GlassCardStyle())
    }
}
