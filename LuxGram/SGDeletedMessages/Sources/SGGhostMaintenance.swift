import Foundation
import Postbox
import SwiftSignalKit
import SGSimpleSettings

/// Housekeeping that ghost mode promises but nothing performed: pruning the
/// saved-deleted archive, and screening incoming messages.
public enum SGGhostMaintenance {

    // MARK: - Archive pruning

    private static var lastPruneTimestamp: Double = 0.0
    /// Once an hour is plenty for a rule measured in days, and it keeps the
    /// scan off the path of anything the user is waiting for.
    private static let pruneInterval: Double = 3600.0

    /// Drops saved copies of deleted messages older than the configured age.
    ///
    /// Only Megram's own archive is touched — the real conversation is never
    /// deleted here. Losing an archived copy costs the user nothing they still
    /// have elsewhere.
    public static func pruneSavedDeletedIfNeeded(postbox: Postbox) -> Signal<Never, NoError> {
        let settings = SGSimpleSettings.shared
        guard settings.ghostModeEnabled, settings.ghostModeAutoCleanHistory else {
            return .complete()
        }
        let days = max(1, Int(settings.ghostModeAutoCleanDays))

        let now = CFAbsoluteTimeGetCurrent()
        guard now - self.lastPruneTimestamp > self.pruneInterval else {
            return .complete()
        }
        self.lastPruneTimestamp = now

        let cutoff = Int32(Date().timeIntervalSince1970) - Int32(days) * 24 * 60 * 60
        return postbox.transaction { transaction -> Void in
            var expired: [MessageId] = []
            // The archive lives in its own namespace, so this walks only
            // Megram's saved copies and can never reach the real conversation.
            for peerId in transaction.chatListGetAllPeerIds() {
                transaction.scanMessageAttributes(peerId: peerId, namespace: messageNamespaceSavedDeleted, limit: Int.max) { messageId, _ in
                    if let message = transaction.getMessage(messageId), message.timestamp < cutoff {
                        expired.append(messageId)
                    }
                    return true
                }
            }
            if !expired.isEmpty {
                transaction.deleteMessages(expired, forEachMedia: nil)
            }
        }
        |> ignoreValues
    }

    // MARK: - Incoming screening

    /// Phrases that mark a message as abuse rather than conversation. Matching
    /// is on a normalised copy of the text, so spacing and case do not matter.
    ///
    /// Kept deliberately narrow: a false positive blocks a real person, so only
    /// phrases with no innocent reading belong here.
    public static let abusePhrases: [String] = [
        "жди сват",
        "жди сватов",
        "сваты выехали",
        "докс",
        "задоксю",
        "задокшу",
        "деанон",
        "деаноню",
        "пробью",
        "пробив по",
        "мать шлюха",
        "мамка шлюха",
        "твоя мать",
        "сдохни",
        "убью тебя",
        "найду тебя",
        "приеду к тебе",
        "адрес твой знаю",
        "сливаю тебя",
        "слив данных"
    ]

    /// Strips everything but letters, digits and single spaces, so that
    /// "д о к с", "Д0КС" and "докс!!!" all reduce to the same needle.
    private static func normalised(_ text: String) -> String {
        let lowered = text.lowercased()
            .replacingOccurrences(of: "0", with: "о")
            .replacingOccurrences(of: "3", with: "з")
            .replacingOccurrences(of: "4", with: "ч")
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }
            return " "
        }
        return String(scalars).split(separator: " ").joined(separator: " ")
    }

    public static func containsAbuse(_ text: String) -> Bool {
        guard !text.isEmpty else {
            return false
        }
        let haystack = self.normalised(text)
        // Spaces are collapsed on both sides so a phrase split across odd
        // spacing still matches.
        for phrase in self.abusePhrases where haystack.contains(self.normalised(phrase)) {
            return true
        }
        return false
    }

    /// Whether an incoming message should have its sender blocked outright.
    ///
    /// Two separate reasons: abuse from anyone, and anything at all from a
    /// stranger. The second is deliberately blunt — it is what the user asked
    /// for — so it only applies to one-to-one chats, never groups or channels,
    /// where "not a contact" describes almost everyone.
    public static func shouldBlockSender(
        isContact: Bool,
        isPrivateChat: Bool,
        isIncoming: Bool,
        text: String
    ) -> Bool {
        let settings = SGSimpleSettings.shared
        guard settings.ghostModeEnabled, settings.ghostModeAntiSpam, isIncoming, isPrivateChat else {
            return false
        }
        if self.containsAbuse(text) {
            return true
        }
        return !isContact
    }
}
