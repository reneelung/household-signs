import SwiftUI

struct SignPalette {
    let offLight: Color
    let offDark: Color
    let onLight: Color
    let onDark: Color
}

extension Color {
    static let appBg = Color(red: 0.98, green: 0.96, blue: 0.94)
    static let appText = Color(red: 0.17, green: 0.15, blue: 0.13)
    static let appSecondary = Color(red: 0.48, green: 0.42, blue: 0.35)
    static let appBorder = Color(red: 0.91, green: 0.87, blue: 0.81)
    static let appAccent = Color(red: 0.55, green: 0.44, blue: 0.28)

    static let signActive = Color(red: 0.77, green: 0.30, blue: 0.22)
    static let signActiveBg = Color(red: 0.77, green: 0.30, blue: 0.22).opacity(0.1)
    static let signInactive = Color(red: 0.35, green: 0.49, blue: 0.35)
    static let signInactiveBg = Color(red: 0.35, green: 0.49, blue: 0.35).opacity(0.1)
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
