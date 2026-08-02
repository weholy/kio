import Foundation

// MARK: - State

/// Everything the fire screen and the chat-header badge need to render.
/// Counters start at zero when the fire is lit and are recomputed from the real
/// message history from that moment on — nothing is faked except the seeded
/// head start described in `MegramFireSeed`.
public struct MegramFireState: Equatable {
    public var isActive: Bool
    /// Unix timestamp of the moment the fire was lit. Statistics ignore
    /// everything older than this, which is what keeps a fresh fire at zero.
    public var activationTimestamp: Int32
    /// Head start granted by a seed, added on top of the earned days.
    public var bonusDays: Int
    /// Days earned since activation.
    public var earnedDays: Int
    public var bestStreak: Int
    public var totalMessages: Int
    public var outgoingMessages: Int
    public var incomingMessages: Int
    /// Message counts for the last 7 days, oldest first, last element is today.
    public var weekCounts: [Int]
    /// True when both sides have written at least once today.
    public var mutualToday: Bool
    /// Messages written today by the side that wrote least. A goal asking for
    /// five messages means five from each, not five between you.
    public var mutualMessagesToday: Int
    /// Which kinds of content were exchanged today, for goal checking.
    public var sentPhotoOrVideoToday: Bool
    public var sentRoundOrVoiceToday: Bool
    public var hadCallToday: Bool
    /// yyyy-MM-dd of the most recent day that counted towards the streak.
    public var lastStreakDay: String?

    public init(
        isActive: Bool = false,
        activationTimestamp: Int32 = 0,
        bonusDays: Int = 0,
        earnedDays: Int = 0,
        bestStreak: Int = 0,
        totalMessages: Int = 0,
        outgoingMessages: Int = 0,
        incomingMessages: Int = 0,
        weekCounts: [Int] = Array(repeating: 0, count: 7),
        mutualToday: Bool = false,
        mutualMessagesToday: Int = 0,
        sentPhotoOrVideoToday: Bool = false,
        sentRoundOrVoiceToday: Bool = false,
        hadCallToday: Bool = false,
        lastStreakDay: String? = nil
    ) {
        self.isActive = isActive
        self.activationTimestamp = activationTimestamp
        self.bonusDays = bonusDays
        self.earnedDays = earnedDays
        self.bestStreak = bestStreak
        self.totalMessages = totalMessages
        self.outgoingMessages = outgoingMessages
        self.incomingMessages = incomingMessages
        self.weekCounts = weekCounts
        self.mutualToday = mutualToday
        self.mutualMessagesToday = mutualMessagesToday
        self.sentPhotoOrVideoToday = sentPhotoOrVideoToday
        self.sentRoundOrVoiceToday = sentRoundOrVoiceToday
        self.hadCallToday = hadCallToday
        self.lastStreakDay = lastStreakDay
    }

    /// The number shown on the flame.
    public var days: Int {
        return self.bonusDays + self.earnedDays
    }

    public var level: MegramFireLevel {
        return MegramFireLevel.level(forDays: self.days)
    }

    public var todayMessages: Int {
        return self.weekCounts.last ?? 0
    }

    /// Progress towards the next level, as (current, target). Returns nil on the
    /// top tier, where there is nothing left to unlock.
    public var milestone: (current: Int, target: Int)? {
        guard let target = self.level.nextThreshold else {
            return nil
        }
        return (self.days, target)
    }

    /// Share of the conversation written by the account owner, 0...1.
    /// Defaults to a neutral half when nothing has been said yet.
    public var outgoingShare: Double {
        let total = self.outgoingMessages + self.incomingMessages
        guard total > 0 else {
            return 0.5
        }
        return Double(self.outgoingMessages) / Double(total)
    }
}

// MARK: - Seeds

/// Usernames that start with a head start instead of an empty flame.
/// Message counters still begin at zero for them.
public enum MegramFireSeed {
    public static let entries: [String: Int] = [
        "weholy": 4,
        "entwilsupport": 4
    ]

    public static func bonusDays(forUsername username: String?) -> Int {
        guard let username, !username.isEmpty else {
            return 0
        }
        return self.entries[username.lowercased()] ?? 0
    }
}

// MARK: - Store

/// Local, per-peer persistence. There is no Megram backend yet, so the fire
/// lives in `UserDefaults.standard` alongside the rest of the Nameless
/// settings, which use the same store.
public enum MegramFireStore {
    private static let peersKey = "megram.fire.peers"

    private static func prefix(_ peerId: Int64) -> String {
        return "megram.fire.\(peerId)"
    }

    private static var defaults: UserDefaults {
        return .standard
    }

    public static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func dayString(_ date: Date) -> String {
        return self.dayFormatter.string(from: date)
    }

    // MARK: Read

    public static func state(peerId: Int64) -> MegramFireState {
        let defaults = self.defaults
        let prefix = self.prefix(peerId)
        guard defaults.bool(forKey: "\(prefix).active") else {
            return MegramFireState()
        }
        var weekCounts = (defaults.array(forKey: "\(prefix).week") as? [Int]) ?? []
        if weekCounts.count != 7 {
            weekCounts = Array(repeating: 0, count: 7)
        }
        return MegramFireState(
            isActive: true,
            activationTimestamp: Int32(defaults.integer(forKey: "\(prefix).activatedAt")),
            bonusDays: defaults.integer(forKey: "\(prefix).bonusDays"),
            earnedDays: defaults.integer(forKey: "\(prefix).earnedDays"),
            bestStreak: defaults.integer(forKey: "\(prefix).bestStreak"),
            totalMessages: defaults.integer(forKey: "\(prefix).total"),
            outgoingMessages: defaults.integer(forKey: "\(prefix).outgoing"),
            incomingMessages: defaults.integer(forKey: "\(prefix).incoming"),
            weekCounts: weekCounts,
            mutualToday: defaults.bool(forKey: "\(prefix).mutualToday"),
            lastStreakDay: defaults.string(forKey: "\(prefix).lastStreakDay")
        )
    }

    public static func isActive(peerId: Int64) -> Bool {
        return self.defaults.bool(forKey: "\(self.prefix(peerId)).active")
    }

    /// Cheap read for the chat header badge: avoids decoding the whole state on
    /// every navigation-bar layout pass.
    public static func badgeDays(peerId: Int64) -> Int? {
        let defaults = self.defaults
        let prefix = self.prefix(peerId)
        guard defaults.bool(forKey: "\(prefix).active") else {
            return nil
        }
        let days = defaults.integer(forKey: "\(prefix).bonusDays") + defaults.integer(forKey: "\(prefix).earnedDays")
        return days > 0 ? days : nil
    }

    /// Peers that currently have a fire, most recently lit first.
    public static func activePeerIds() -> [Int64] {
        let raw = (self.defaults.array(forKey: self.peersKey) as? [NSNumber]) ?? []
        return raw.map { $0.int64Value }.filter { self.isActive(peerId: $0) }
    }

    // MARK: Write

    /// Lights the fire. Does nothing when it is already burning, so re-tapping
    /// "Предложить огонёк" never resets the streak.
    @discardableResult
    public static func activate(peerId: Int64, username: String?, timestamp: Int32) -> MegramFireState {
        if self.isActive(peerId: peerId) {
            return self.state(peerId: peerId)
        }
        let defaults = self.defaults
        let prefix = self.prefix(peerId)
        let bonus = MegramFireSeed.bonusDays(forUsername: username)
        defaults.set(true, forKey: "\(prefix).active")
        defaults.set(Int(timestamp), forKey: "\(prefix).activatedAt")
        defaults.set(bonus, forKey: "\(prefix).bonusDays")
        defaults.set(0, forKey: "\(prefix).earnedDays")
        defaults.set(bonus, forKey: "\(prefix).bestStreak")
        defaults.set(0, forKey: "\(prefix).total")
        defaults.set(0, forKey: "\(prefix).outgoing")
        defaults.set(0, forKey: "\(prefix).incoming")
        defaults.set(Array(repeating: 0, count: 7), forKey: "\(prefix).week")
        defaults.set(false, forKey: "\(prefix).mutualToday")
        defaults.removeObject(forKey: "\(prefix).lastStreakDay")
        self.registerPeer(peerId)
        return self.state(peerId: peerId)
    }

    public static func deactivate(peerId: Int64) {
        let defaults = self.defaults
        let prefix = self.prefix(peerId)
        for suffix in ["active", "activatedAt", "bonusDays", "earnedDays", "bestStreak", "total", "outgoing", "incoming", "week", "mutualToday", "lastStreakDay"] {
            defaults.removeObject(forKey: "\(prefix).\(suffix)")
        }
        var peers = self.storedPeerIds()
        peers.removeAll(where: { $0 == peerId })
        defaults.set(peers.map { NSNumber(value: $0) }, forKey: self.peersKey)
    }

    /// Persists a freshly computed snapshot. `bonusDays` and `activationTimestamp`
    /// are owned by `activate` and are never overwritten here.
    public static func store(peerId: Int64, state: MegramFireState) {
        let defaults = self.defaults
        let prefix = self.prefix(peerId)
        guard defaults.bool(forKey: "\(prefix).active") else {
            return
        }
        let previousBest = defaults.integer(forKey: "\(prefix).bestStreak")
        defaults.set(state.earnedDays, forKey: "\(prefix).earnedDays")
        defaults.set(max(previousBest, state.days), forKey: "\(prefix).bestStreak")
        defaults.set(state.totalMessages, forKey: "\(prefix).total")
        defaults.set(state.outgoingMessages, forKey: "\(prefix).outgoing")
        defaults.set(state.incomingMessages, forKey: "\(prefix).incoming")
        defaults.set(state.weekCounts, forKey: "\(prefix).week")
        defaults.set(state.mutualToday, forKey: "\(prefix).mutualToday")
        if let lastStreakDay = state.lastStreakDay {
            defaults.set(lastStreakDay, forKey: "\(prefix).lastStreakDay")
        } else {
            defaults.removeObject(forKey: "\(prefix).lastStreakDay")
        }
    }

    private static func storedPeerIds() -> [Int64] {
        let raw = (self.defaults.array(forKey: self.peersKey) as? [NSNumber]) ?? []
        return raw.map { $0.int64Value }
    }

    private static func registerPeer(_ peerId: Int64) {
        var peers = self.storedPeerIds()
        peers.removeAll(where: { $0 == peerId })
        peers.insert(peerId, at: 0)
        self.defaults.set(peers.map { NSNumber(value: $0) }, forKey: self.peersKey)
    }
}

// MARK: - Daily goals

/// The day's task. Every case is checked against what actually happened in the
/// chat today — nothing here is decorative.
public enum MegramFireGoal: CaseIterable {
    /// Both sides wrote at least once.
    case reply
    /// Both sides wrote at least three times.
    case messages3
    /// Both sides wrote at least five times.
    case messages5
    case photoOrVideo
    case roundOrVoice
    case call

    public var titleRu: String {
        switch self {
        case .reply: return "Ответьте друг другу сегодня"
        case .messages3: return "Напишите друг другу по 3 сообщения"
        case .messages5: return "Напишите друг другу по 5 сообщений"
        case .photoOrVideo: return "Отправьте фото или видео"
        case .roundOrVoice: return "Запишите кружок или голосовое"
        case .call: return "Созвонитесь сегодня"
        }
    }

    /// Progress towards the goal as (done, target). Boolean goals report 0 or 1
    /// out of 1, so the caller can render every case the same way.
    public func progress(state: MegramFireState) -> (done: Int, target: Int) {
        switch self {
        case .reply:
            return (state.mutualToday ? 1 : 0, 1)
        case .messages3:
            return (min(state.mutualMessagesToday, 3), 3)
        case .messages5:
            return (min(state.mutualMessagesToday, 5), 5)
        case .photoOrVideo:
            return (state.sentPhotoOrVideoToday ? 1 : 0, 1)
        case .roundOrVoice:
            return (state.sentRoundOrVoiceToday ? 1 : 0, 1)
        case .call:
            return (state.hadCallToday ? 1 : 0, 1)
        }
    }

    public func isComplete(state: MegramFireState) -> Bool {
        let progress = self.progress(state: state)
        return progress.done >= progress.target
    }

    /// Derived from the day itself, so the goal stays put for 24 hours.
    public static func goal(for date: Date) -> MegramFireGoal {
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .era, for: date) ?? 0
        let all = MegramFireGoal.allCases
        return all[abs(day) % all.count]
    }
}
