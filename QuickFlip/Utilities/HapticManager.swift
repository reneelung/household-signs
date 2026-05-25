import UIKit

class HapticManager {
    static func trigger(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: type).impactOccurred()
    }

    static func light() {
        trigger(.light)
    }

    static func medium() {
        trigger(.medium)
    }

    static func heavy() {
        trigger(.heavy)
    }
}
