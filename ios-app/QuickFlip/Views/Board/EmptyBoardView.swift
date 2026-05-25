import SwiftUI

struct EmptyBoardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("No flip boards yet")
            .font(.system(size: 17, weight: .medium))
            .kerning(-0.2)
            .foregroundStyle(colorScheme == .dark
                ? Color.white.opacity(0.40)
                : Color(hex: "0F1115").opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
