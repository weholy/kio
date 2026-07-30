import Foundation
import UIKit

// MARK: - nameless runtime helpers (80% wiring for stubs)

public enum NamelessFeatureRuntime {
    /// Effective JPEG quality 1…100 for outgoing photos.
    public static var effectiveOutgoingPhotoQuality: Int {
        let s = SGSimpleSettings.shared
        if s.cameraAlwaysSendHD || s.cameraSendHDPhoto || s.sendLargePhotos {
            return 100
        }
        let q = Int(s.outgoingPhotoQuality)
        let jpeg = Int(s.cameraJpegQuality)
        let best = max(q, jpeg)
        return min(100, max(1, best > 0 ? best : 85))
    }

    /// OLED aggressive: pure black backgrounds
    public static var oledBlack: Bool {
        SGSimpleSettings.shared.oledMode
    }

    public static var oledBackgroundColor: UIColor {
        UIColor(white: 0.0, alpha: 1.0)
    }

    /// Simple anti-scam heuristics for URLs / text
    public static func looksSuspicious(urlOrText: String) -> Bool {
        guard SGSimpleSettings.shared.antiScamEnabled else { return false }
        let t = urlOrText.lowercased()
        let bad = [
            "t.me/bitcoin", "free-ton", "double your", "claim prize",
            "wallet-verify", "seed phrase", "mnemonic", "airdrop-claim",
            "telegram-login.", "tg-premium.free", "verify-account."
        ]
        for b in bad where t.contains(b) {
            return true
        }
        if let host = URL(string: urlOrText)?.host ?? URL(string: "https://\(urlOrText)")?.host {
            let digits = host.filter { $0.isNumber }.count
            if digits >= 4 && host.count < 20 { return true }
        }
        return false
    }

    /// Call confirmation uses either legacy confirmCalls or warnBeforeCall
    public static var shouldWarnBeforeCall: Bool {
        let s = SGSimpleSettings.shared
        return s.confirmCalls || s.warnBeforeCall
    }
}
