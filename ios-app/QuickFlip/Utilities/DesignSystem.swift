import SwiftUI
import UIKit

struct SignPalette {
    let offLight: Color
    let offDark: Color
    let onLight: Color
    let onDark: Color
}

extension Color {
    static let appBg = Color(uiColor: .systemBackground)
    static let appText = Color(uiColor: .label)
    static let appSecondary = Color(uiColor: .secondaryLabel)
    static let appBorder = Color(uiColor: .systemGray4)
    static let appAccent = Color(red: 1.0, green: 0.8, blue: 0.0)

    static let signActive = Color(red: 0.77, green: 0.30, blue: 0.22)
    static let signActiveBg = Color(red: 0.77, green: 0.30, blue: 0.22).opacity(0.1)
    static let signInactive = Color(red: 0.35, green: 0.49, blue: 0.35)
    static let signInactiveBg = Color(red: 0.35, green: 0.49, blue: 0.35).opacity(0.1)

    // Redesigned SignCard tokens (iOS 26)
    // Brand colors
    static let qfYellow = Color(hex: "FFD600")
    static let qfYellowDeep = Color(hex: "9A7B00")

    // Dark mode
    static let qfDarkGlassTint = Color.white.opacity(0.08)
    static let qfDarkGlassBorder = Color.white.opacity(0.18)
    static let qfDarkActiveTint = Color(hex: "FFD600").opacity(0.12)
    static let qfDarkActiveBorder = Color(hex: "FFD600").opacity(0.45)
    static let qfDarkTextStrong = Color.white.opacity(0.85)
    static let qfDarkTextMuted = Color.white.opacity(0.55)
    static let qfCanvasBg = Color.black

    // Light mode
    static let qfLightGlassTint = Color.white.opacity(0.62)
    static let qfLightGlassBorder = Color.black.opacity(0.08)
    static let qfLightActiveTint = Color(hex: "FFD600").opacity(0.32)
    static let qfLightActiveBorder = Color(hex: "9A7B00").opacity(0.55)
    static let qfLightTextStrong = Color(hex: "0F1115").opacity(0.90)
    static let qfLightTextMuted = Color(hex: "0F1115").opacity(0.60)
}

let SIGN_PALETTES = [
    SignPalette(offLight: Color(hex: "93C5FD"), offDark: Color(hex: "3B82F6"), onLight: Color(hex: "3B82F6"), onDark: Color(hex: "1E40AF")),
    SignPalette(offLight: Color(hex: "D8B4FE"), offDark: Color(hex: "A855F7"), onLight: Color(hex: "A855F7"), onDark: Color(hex: "6D28D9")),
    SignPalette(offLight: Color(hex: "A5F3FC"), offDark: Color(hex: "06B6D4"), onLight: Color(hex: "06B6D4"), onDark: Color(hex: "0E7490")),
    SignPalette(offLight: Color(hex: "86EFAC"), offDark: Color(hex: "10B981"), onLight: Color(hex: "10B981"), onDark: Color(hex: "047857")),
    SignPalette(offLight: Color(hex: "FDBA74"), offDark: Color(hex: "F97316"), onLight: Color(hex: "F97316"), onDark: Color(hex: "B45309")),
]

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct Typography {
    static let heading = Font.system(size: 28, weight: .semibold)
    static let headingSmall = Font.system(size: 20, weight: .semibold)
    static let labelLarge = Font.system(size: 17, weight: .semibold)
    static let labelMedium = Font.system(size: 15, weight: .medium)
    static let labelSmall = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
}

struct SignCardDesign {
    static let cardRadius: CGFloat = 22
    static let cardPadding: CGFloat = 14
    static let cardMinHeight: CGFloat = 168
    static let gridGutter: CGFloat = 12
    static let gridRowSpacing: CGFloat = 12

    static let emojiSize: CGFloat = 30
    static let eyebrowFont = Font.system(size: 10.5, weight: .bold)
    static let stateFont = Font.system(size: 23, weight: .bold)
    static let metaFont = Font.system(size: 11)
}
