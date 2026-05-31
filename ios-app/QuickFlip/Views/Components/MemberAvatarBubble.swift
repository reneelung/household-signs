import SwiftUI

struct MemberAvatarBubble: View {
    let name: String
    let size: CGFloat

    private var initial: String { String(name.prefix(1)).uppercased() }

    private var color: Color {
        let palette: [Color] = [
            Color(hex: "FF8A3D"),
            Color(hex: "22D3EE"),
            Color(hex: "9B5BFF"),
            Color(hex: "1ED760"),
            Color(hex: "FF4DCB"),
        ]
        let stableHash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[stableHash % palette.count]
    }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
    }
}
