import Foundation
import Postbox
import TelegramCore
import SwiftSignalKit

/// Recomputes a fire from the real message history.
///
/// Only messages newer than the activation timestamp count, which is what keeps
/// a freshly lit fire at zero while still counting genuine traffic from that
/// moment on. Both the fire screen and the chat-header badge go through here so
/// they can never disagree.
public struct MegramFireSnapshot {
    public let state: MegramFireState
    /// The two people this fire belongs to: the chat partner first, then the
    /// account owner. A fire is always a pair — never a roster of every chat
    /// that happens to have one burning.
    public let partners: [EnginePeer]

    public init(state: MegramFireState, partners: [EnginePeer]) {
        self.state = state
        self.partners = partners
    }
}

public enum MegramFireRefresh {
    /// Recomputes and persists the state for one peer.
    public static func refresh(postbox: Postbox, peerId: EnginePeer.Id, accountPeerId: EnginePeer.Id) -> Signal<MegramFireSnapshot, NoError> {
        let rawPeerId = peerId.toInt64()
        let stored = MegramFireStore.state(peerId: rawPeerId)
        return postbox.transaction { transaction -> MegramFireSnapshot in
            var partners: [EnginePeer] = []
            if let peer = transaction.getPeer(peerId) {
                partners.append(EnginePeer(peer))
            }
            if let accountPeer = transaction.getPeer(accountPeerId) {
                partners.append(EnginePeer(accountPeer))
            }

            guard stored.isActive else {
                return MegramFireSnapshot(state: stored, partners: partners)
            }

            let state = self.computeState(transaction: transaction, peerId: peerId, stored: stored)
            MegramFireStore.store(peerId: rawPeerId, state: state)
            return MegramFireSnapshot(state: state, partners: partners)
        }
    }

    /// Throttles the background refresh. `setPeer` runs on every theme change,
    /// presentation update and avatar reload, and a full history scan on each of
    /// those is what made the app fall over.
    private static var lastBackgroundRefresh: [Int64: Double] = [:]
    private static let backgroundRefreshInterval: Double = 300.0
    private static let backgroundRefreshLock = NSLock()

    /// Fire-and-forget refresh used when a chat is opened, so the header badge
    /// does not go stale for people who never open the fire screen.
    ///
    /// The badge already renders from the cached day count, so skipping a
    /// refresh costs nothing but a slightly stale number.
    public static func refreshInBackground(postbox: Postbox, peerId: EnginePeer.Id, accountPeerId: EnginePeer.Id, completion: @escaping (MegramFireState) -> Void) -> Disposable {
        let rawPeerId = peerId.toInt64()
        guard MegramFireStore.isActive(peerId: rawPeerId) else {
            return EmptyDisposable
        }

        let now = CFAbsoluteTimeGetCurrent()
        self.backgroundRefreshLock.lock()
        let previous = self.lastBackgroundRefresh[rawPeerId]
        let shouldRun = previous == nil || now - previous! > self.backgroundRefreshInterval
        if shouldRun {
            self.lastBackgroundRefresh[rawPeerId] = now
        }
        self.backgroundRefreshLock.unlock()

        guard shouldRun else {
            return EmptyDisposable
        }

        return (self.refresh(postbox: postbox, peerId: peerId, accountPeerId: accountPeerId)
        |> deliverOnMainQueue).start(next: { snapshot in
            completion(snapshot.state)
        })
    }

    private static func computeState(transaction: Transaction, peerId: EnginePeer.Id, stored: MegramFireState) -> MegramFireState {
        var total = 0
        var outgoing = 0
        var incoming = 0
        var perDayOutgoing: [String: Int] = [:]
        var perDayIncoming: [String: Int] = [:]
        var perDayTotal: [String: Int] = [:]

        let today = MegramFireStore.dayString(Date())
        var sentPhotoOrVideoToday = false
        var sentRoundOrVoiceToday = false
        var hadCallToday = false

        // Every message the scan touches is fully rendered out of the database,
        // so an unbounded walk over a long conversation is expensive enough to
        // matter. A year of history and 20k messages cover every figure this
        // screen shows; the streak cannot reach further back anyway.
        let scanLimit = 20000
        let oldestTimestamp = Int32(Date().timeIntervalSince1970) - 400 * 24 * 60 * 60
        var scanned = 0

        transaction.withAllMessages(peerId: peerId, namespace: Namespaces.Message.Cloud, reversed: true, { message in
            scanned += 1
            if scanned > scanLimit || message.timestamp < oldestTimestamp {
                return false
            }
            let day = MegramFireStore.dayString(Date(timeIntervalSince1970: Double(message.timestamp)))

            // Service events are not conversation, but a call leaves one and
            // that is the only trace a call has in the history.
            if let action = message.media.first(where: { $0 is TelegramMediaAction }) as? TelegramMediaAction {
                if day == today, case .phoneCall = action.action {
                    hadCallToday = true
                }
                return true
            }

            if day == today {
                for media in message.media {
                    if media is TelegramMediaImage {
                        sentPhotoOrVideoToday = true
                    } else if let file = media as? TelegramMediaFile {
                        if file.isInstantVideo || file.isVoice {
                            sentRoundOrVoiceToday = true
                        } else if file.isVideo {
                            sentPhotoOrVideoToday = true
                        }
                    }
                }
            }
            total += 1
            perDayTotal[day] = (perDayTotal[day] ?? 0) + 1
            if message.flags.contains(.Incoming) {
                incoming += 1
                perDayIncoming[day] = (perDayIncoming[day] ?? 0) + 1
            } else {
                outgoing += 1
                perDayOutgoing[day] = (perDayOutgoing[day] ?? 0) + 1
            }
            return true
        })

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        let isMutual: (Date) -> Bool = { date in
            let day = MegramFireStore.dayString(date)
            return (perDayIncoming[day] ?? 0) > 0 && (perDayOutgoing[day] ?? 0) > 0
        }

        // Walk backwards from today. Today is allowed to be incomplete — there
        // is still time left to answer — but any earlier gap ends the streak.
        var earnedDays = 0
        var lastStreakDay: String?
        var cursor = now
        var offset = 0
        while offset < 400 {
            if isMutual(cursor) {
                earnedDays += 1
                if lastStreakDay == nil {
                    lastStreakDay = MegramFireStore.dayString(cursor)
                }
            } else if offset > 0 {
                break
            }
            offset += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        var weekCounts: [Int] = []
        for dayOffset in stride(from: 6, through: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                weekCounts.append(perDayTotal[MegramFireStore.dayString(date)] ?? 0)
            } else {
                weekCounts.append(0)
            }
        }

        var state = stored
        state.earnedDays = earnedDays
        state.totalMessages = total
        state.outgoingMessages = outgoing
        state.incomingMessages = incoming
        state.weekCounts = weekCounts
        state.mutualToday = isMutual(now)
        // The weaker side sets the pace: "five each" is not satisfied by one
        // person writing ten times.
        state.mutualMessagesToday = min(perDayOutgoing[today] ?? 0, perDayIncoming[today] ?? 0)
        state.sentPhotoOrVideoToday = sentPhotoOrVideoToday
        state.sentRoundOrVoiceToday = sentRoundOrVoiceToday
        state.hadCallToday = hadCallToday
        state.lastStreakDay = lastStreakDay
        state.bestStreak = max(stored.bestStreak, stored.bonusDays + earnedDays)
        return state
    }
}
