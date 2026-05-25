import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String

    private let emojis = ["📌", "🍽️", "🗑️", "🧺", "🛏️", "🐕", "🌡️", "🔒", "🌙", "☀️", "🍕", "🎬", "🎮", "📚", "🎵"]
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(emojis, id: \.self) { emoji in
                Button(action: {
                    selectedEmoji = emoji
                }) {
                    Text(emoji)
                        .font(.system(size: 32))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedEmoji == emoji ? Color.appAccent.opacity(0.2) : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedEmoji == emoji ? Color.appAccent : Color.appBorder, lineWidth: selectedEmoji == emoji ? 2 : 1)
                        )
                }
            }
        }
    }
}

#Preview {
    EmojiPickerView(selectedEmoji: .constant("📌"))
        .padding(20)
        .background(Color.appBg)
}
