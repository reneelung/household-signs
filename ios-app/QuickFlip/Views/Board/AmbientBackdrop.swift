import SwiftUI

struct AmbientBackdrop: View {
    enum Palette { case cool, warm, forest, plum }

    var palette: Palette = .cool

    @Environment(\.colorScheme) private var colorScheme

    private let anchors: [(CGFloat, CGFloat)] = [
        (0.18, 0.12), (0.78, 0.30), (0.40, 0.75)
    ]

    private var colors: [Color] {
        let dark = colorScheme == .dark
        switch (palette, dark) {
        case (.cool,   true):  return [Color(hex: "3B5BFF"), Color(hex: "FF4DCB"), Color(hex: "22D3EE")]
        case (.cool,   false): return [Color(hex: "A9C4FF"), Color(hex: "FFB8E3"), Color(hex: "A6ECF4")]
        case (.warm,   true):  return [Color(hex: "FF8A3D"), Color(hex: "FFD600"), Color(hex: "FF3D7F")]
        case (.warm,   false): return [Color(hex: "FFCFA8"), Color(hex: "FFE680"), Color(hex: "FFB8C8")]
        case (.forest, true):  return [Color(hex: "1ED760"), Color(hex: "FFD600"), Color(hex: "3B5BFF")]
        case (.forest, false): return [Color(hex: "B8ECC4"), Color(hex: "FFE680"), Color(hex: "A9C4FF")]
        case (.plum,   true):  return [Color(hex: "9B5BFF"), Color(hex: "FF4DCB"), Color(hex: "FFD600")]
        case (.plum,   false): return [Color(hex: "D4BAFF"), Color(hex: "FFB8E3"), Color(hex: "FFE680")]
        }
    }

    private var baseColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F5F5F7")
    }

    private var washColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.45)
            : Color(hex: "EEEEF2").opacity(0.40)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                baseColor
                if #available(iOS 17, *) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { idx, color in
                        Circle()
                            .fill(color)
                            .frame(width: 280, height: 280)
                            .blur(radius: 60)
                            .opacity(colorScheme == .dark ? 0.55 : 0.60)
                            .position(
                                x: geo.size.width  * anchors[idx].0,
                                y: geo.size.height * anchors[idx].1
                            )
                    }
                    washColor
                }
            }
            .ignoresSafeArea()
        }
    }
}
