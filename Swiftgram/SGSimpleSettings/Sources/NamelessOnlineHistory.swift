import Foundation

/// Local online/offline history for contacts (Whitegram-style «История онлайна»).
public struct NamelessOnlineHistoryEntry: Codable, Equatable {
    public let peerId: Int64
    public let name: String
    public let isOnline: Bool
    public let timestamp: TimeInterval

    public init(peerId: Int64, name: String, isOnline: Bool, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.peerId = peerId
        self.name = name
        self.isOnline = isOnline
        self.timestamp = timestamp
    }

    public var date: Date { Date(timeIntervalSince1970: timestamp) }
}

public enum NamelessOnlineHistory {
    private static let key = "nameless.onlineHistory.v1"
    private static let maxEntries = 500

    public static func all() -> [NamelessOnlineHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([NamelessOnlineHistoryEntry].self, from: data) else {
            return []
        }
        return list
    }

    public static func append(peerId: Int64, name: String, isOnline: Bool) {
        guard SGSimpleSettings.shared.enableOnlineStatusRecording else { return }
        var list = all()
        // Dedup rapid flips for same peer within 15s
        if let last = list.first, last.peerId == peerId, last.isOnline == isOnline,
           Date().timeIntervalSince1970 - last.timestamp < 15 {
            return
        }
        list.insert(NamelessOnlineHistoryEntry(peerId: peerId, name: name, isOnline: isOnline), at: 0)
        if list.count > maxEntries {
            list = Array(list.prefix(maxEntries))
        }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
