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
    /// Peers that currently have a fire, for the avatar row on the fire screen.
    public let partners: [EnginePeer]

    public init(state: MegramFireState, partners: [EnginePeer]) {
        self.state = state
        self.partners = partners
    }
}

public enum MegramFireRefresh {
    /// Recomputes and persists the state for one peer.
    public static func refresh(postbox: Postbox, peerId: EnginePeer.Id) -> Signal<MegramFireSnapshot, NoError> {
        let rawPeerId = peerId.toInt64()
        let stored = MegramFireStore.state(peerId: rawPeerId)
        return postbox.transaction { transaction -> MegramFireSnapshot in
            var partners: [EnginePeer] = []
            for otherId in MegramFireStore.activePeerIds().prefix(6) {
                if let peer = transaction.getPeer(PeerId(otherId)) {
                    partners.append(EnginePeer(peer))
                }
            }

            guard stored.isActive else {
                return MegramFireSnapshot(state: stored, partners: partners)
            }

            let state = self.computeState(transaction: transaction, peerId: peerId, stored: stored)
            MegramFireStore.store(peerId: rawPeerId, state: state)
            return MegramFireSnapshot(state: state, partners: partners)
        }
    }

    /// Fire-and-forget refresh used when a chat is opened, so the header badge
    /// does not go stale for people who never open the fire screen.
    public static func refreshInBackground(postbox: Postbox, peerId: EnginePeer.Id, completion: @escaping (MegramFireState) -> Void) -> Disposable {
        guard MegramFireStore.isActive(peerId: peerId.toInt64()) else {
            return EmptyDisposable
        }
        return (self.refresh(postbox: postbox, peerId: peerId)
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

        // The whole conversation counts, not just what arrived after the fire
        // was lit — a fresh fire showing zero messages next to a chat with
        // thousands of them reads as broken.
        transaction.withAllMessages(peerId: peerId, namespace: Namespaces.Message.Cloud, reversed: true, { message in
            // Joins, pins and other service events are not conversation.
            if message.media.contains(where: { $0 is TelegramMediaAction }) {
                return true
            }
            let day = MegramFireStore.dayString(Date(timeIntervalSince1970: Double(message.timestamp)))
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
        state.lastStreakDay = lastStreakDay
        state.bestStreak = max(stored.bestStreak, stored.bonusDays + earnedDays)
        return state
    }
}
