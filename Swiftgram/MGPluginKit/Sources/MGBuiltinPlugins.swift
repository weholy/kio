import Foundation

/// A plugin compiled into the client.
///
/// Built-ins are loaded on every launch, are never listed on the Plugins screen, and cannot be
/// disabled or removed. They exist so behaviour that *is* the product can be written against the
/// same API third-party plugins use — if the API cannot express a shipping feature, the API is
/// not good enough.
public struct MGBuiltinPluginDescriptor {
    public let id: String
    public let name: String
    public let version: String
    public let source: String

    var installedPlugin: MGInstalledPlugin {
        return MGInstalledPlugin(
            manifest: MGPluginManifest(
                id: self.id,
                name: self.name,
                version: self.version,
                author: "Megram",
                summary: "",
                readmeHTML: nil,
                iconSource: nil,
                format: .js
            ),
            // Built-ins have no file. The URL only ever reaches JSContext as a source name in
            // stack traces, so a synthetic one is both harmless and more readable than a real path.
            fileURL: URL(string: "megram-builtin://\(self.id).js") ?? URL(fileURLWithPath: "/"),
            isEnabled: true,
            isBuiltIn: true
        )
    }
}

public enum MGBuiltinPlugins {
    public static var all: [MGBuiltinPluginDescriptor] {
        return [
            MGBuiltinPluginDescriptor(
                id: "megram_notifications",
                name: "Megram Notifications",
                version: "1.0",
                source: self.notificationsSource
            )
        ]
    }

    /// Local notifications for incoming messages while the app is in the background.
    ///
    /// A port of the Whitegram Notifications plugin onto the Megram API, and the reference for
    /// what a non-trivial plugin looks like: state in `mg.getStorage`, filtering, de-duplication,
    /// scheduling through `mg.notifications`, and `onNotificationTap` routing back into a chat.
    ///
    /// Written as a raw string so JS escape sequences (`\s`, `\n`) survive verbatim.
    private static let notificationsSource = #"""
    // @name        Megram Notifications
    // @version     1.0
    // @author      Megram
    // @description Локальные уведомления о входящих, пока приложение свёрнуто.

    (function () {
        "use strict";

        var STORAGE_STATE = "state_v1";

        var CONFIG = {
            skipMutedChats: true,
            skipSelfMessages: true,
            onlyActiveAccount: true,
            sound: true,
            maxTitleLength: 64,
            maxBodyLength: 160,
            dedupTtlMs: 5 * 60 * 1000,
            dedupMaxItems: 400
        };

        // true  = app is on screen, notifications stay silent (Telegram itself is the notification)
        // false = app is backgrounded, notifications are useful
        var inForeground = true;
        var permissionGranted = false;
        var dedup = {};

        function now() {
            return Date.now ? Date.now() : new Date().getTime();
        }

        function isBlank(value) {
            return value === undefined || value === null || value === "";
        }

        function text(value, fallback) {
            if (isBlank(value)) {
                return fallback || "";
            }
            var s = String(value).replace(/^\s+|\s+$/g, "");
            return s.length > 0 ? s : (fallback || "");
        }

        function crop(value, maxLength, fallback) {
            var s = text(value, fallback);
            if (!maxLength || s.length <= maxLength) {
                return s;
            }
            return s.substring(0, maxLength - 1) + "…";
        }

        function loadState() {
            var raw = mg.getStorage(STORAGE_STATE);
            if (!raw) {
                return;
            }
            try {
                var parsed = JSON.parse(raw);
                dedup = parsed && parsed.dedup ? parsed.dedup : {};
            } catch (e) {
                dedup = {};
            }
        }

        function saveState() {
            try {
                mg.setStorage(STORAGE_STATE, JSON.stringify({ dedup: dedup }));
            } catch (e) {
                mg.log("state save failed");
            }
        }

        // Drops entries past their TTL, then trims the oldest until the map fits the cap. Without
        // this the dedup map is an unbounded leak for a busy account.
        function pruneDedup() {
            var current = now();
            var entries = [];
            var key;

            for (key in dedup) {
                if (!Object.prototype.hasOwnProperty.call(dedup, key)) {
                    continue;
                }
                var stamp = dedup[key] || 0;
                if ((current - stamp) > CONFIG.dedupTtlMs) {
                    delete dedup[key];
                } else {
                    entries.push({ key: key, stamp: stamp });
                }
            }

            if (entries.length > CONFIG.dedupMaxItems) {
                entries.sort(function (a, b) { return a.stamp - b.stamp; });
                var excess = entries.length - CONFIG.dedupMaxItems;
                for (var i = 0; i < excess; i++) {
                    delete dedup[entries[i].key];
                }
            }
        }

        function isDuplicate(message) {
            pruneDedup();
            var key = message.peerId + ":" + message.messageId;
            var stamp = dedup[key];
            if (stamp && (now() - stamp) < CONFIG.dedupTtlMs) {
                return true;
            }
            dedup[key] = now();
            return false;
        }

        function shouldNotify(message) {
            if (inForeground) {
                return false;
            }
            if (isBlank(message.peerId) || isBlank(message.messageId)) {
                return false;
            }
            if (CONFIG.skipSelfMessages && message.isOutgoing) {
                return false;
            }
            if (CONFIG.skipMutedChats && message.isMuted) {
                return false;
            }
            if (CONFIG.onlyActiveAccount && !isBlank(message.accountId)) {
                var active = mg.getAccountId();
                if (active && String(message.accountId) !== String(active)) {
                    return false;
                }
            }
            return !isDuplicate(message);
        }

        function buildTitle(message) {
            var title = text(message.senderName, "");
            if (!title) {
                title = text(message.chatName, "");
            }
            return crop(title, CONFIG.maxTitleLength, "Новое сообщение");
        }

        function buildBody(message) {
            var body = text(message.text, "");
            if (!body && !isBlank(message.mediaType)) {
                body = "[" + message.mediaType + "]";
            }
            return crop(body, CONFIG.maxBodyLength, "Новое сообщение");
        }

        // The peer id travels in the notification id so a tap can route back to the chat without
        // keeping any state across a cold launch.
        function notificationId(message) {
            return "mgn|" + encodeURIComponent(message.peerId) + "|" + encodeURIComponent(message.messageId);
        }

        function peerIdFromNotificationId(value) {
            var parts = String(value || "").split("|");
            if (parts.length < 3 || parts[0] !== "mgn") {
                return "";
            }
            try {
                return decodeURIComponent(parts[1]);
            } catch (e) {
                return parts[1];
            }
        }

        mg.on("onAppStart", function () {
            inForeground = true;
            loadState();
            mg.notifications.requestPermission(function (granted) {
                permissionGranted = !!granted;
                mg.log("notification permission: " + (permissionGranted ? "granted" : "denied"));
            });
        });

        mg.on("onAppForeground", function () {
            inForeground = true;
        });

        mg.on("onAppBackground", function () {
            inForeground = false;
            saveState();
        });

        mg.on("onMessageReceive", function (message) {
            if (!message || !permissionGranted) {
                return;
            }
            if (!shouldNotify(message)) {
                return;
            }
            mg.notifications.schedule({
                id: notificationId(message),
                title: buildTitle(message),
                body: buildBody(message),
                delay: 1,
                repeating: false,
                sound: CONFIG.sound
            });
        });

        mg.on("onNotificationTap", function (notification) {
            inForeground = true;
            var peerId = peerIdFromNotificationId(notification && notification.id);
            if (peerId) {
                mg.openChat(peerId);
            }
        });

        loadState();
        mg.log("loaded");
    })();
    """#
}
