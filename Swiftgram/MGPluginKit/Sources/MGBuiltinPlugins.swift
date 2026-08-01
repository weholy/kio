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
    /// Nothing ships built in right now.
    ///
    /// The notifications plugin used to live here, but a plugin that raises system notifications
    /// the user never asked for and cannot switch off is the wrong default: iOS already delivers
    /// Telegram's own pushes, so ours only ever duplicated them. It remains available as an
    /// installable plugin (`docs/plugins/megram-notifications.plugin`) for anyone who wants it.
    ///
    /// The mechanism stays: adding a descriptor here is all it takes to ship behaviour written
    /// against the same API third-party plugins use.
    public static var all: [MGBuiltinPluginDescriptor] {
        return []
    }
}
