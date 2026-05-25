import SwiftUI

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

struct Typography {
    static let heading = Font.system(size: 28, weight: .semibold)
    static let headingSmall = Font.system(size: 20, weight: .semibold)
    static let labelLarge = Font.system(size: 17, weight: .semibold)
    static let labelMedium = Font.system(size: 15, weight: .medium)
    static let labelSmall = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
}
