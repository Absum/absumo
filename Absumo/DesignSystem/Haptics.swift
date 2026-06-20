import UIKit

/// Lightweight haptic helpers used throughout the UI.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func notify(_ success: Bool) {
        UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
    }
}
