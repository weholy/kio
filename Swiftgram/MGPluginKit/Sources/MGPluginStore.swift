import Foundation

/// One installed plugin: its file on disk plus the state the host keeps about it.
public struct MGInstalledPlugin: Equatable {
    public let manifest: MGPluginManifest
    public let fileURL: URL
    public let isEnabled: Bool
    /// Built-in plugins ship inside the binary. They are always loaded, never listed, and cannot
    /// be disabled or removed — the plugin list must not even hint that they exist.
    public let isBuiltIn: Bool

    public init(manifest: MGPluginManifest, fileURL: URL, isEnabled: Bool, isBuiltIn: Bool) {
        self.manifest = manifest
        self.fileURL = fileURL
        self.isEnabled = isEnabled
        self.isBuiltIn = isBuiltIn
    }

    public var id: String {
        return self.manifest.id
    }
}

public enum MGPluginInstallError: LocalizedError {
    case unreadableFile
    case unsupportedExtension(String)
    case missingName
    case noRuntime(MGPluginFormat)
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "Не удалось прочитать файл плагина"
        case let .unsupportedExtension(ext):
            let supported = MGPluginFormat.supportedExtensions.map { ".\($0)" }.joined(separator: ", ")
            return "Расширение .\(ext) не поддерживается. Допустимые: \(supported)"
        case .missingName:
            return "В файле нет заголовка @name — это не плагин Megram"
        case let .noRuntime(format):
            return "Megram выполняет плагины на JavaScript, а \(format.displayName)-рантайма нет. Сохраните плагин как .js"
        case let .writeFailed(reason):
            return "Не удалось установить плагин: \(reason)"
        }
    }
}

/// Owns the plugins directory and the per-plugin state. Pure filesystem + `UserDefaults`: no JS,
/// no UI, so the installer and the list screen can both use it without pulling in the runtime.
public final class MGPluginStore {
    public static let shared = MGPluginStore()

    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let disabledPluginIds = "megram.plugins.disabled"
        static func setting(pluginId: String, key: String) -> String {
            return "megram.plugins.storage.\(pluginId).\(key)"
        }
        static func settingPrefix(pluginId: String) -> String {
            return "megram.plugins.storage.\(pluginId)."
        }
    }

    private init() {}

    // MARK: - Locations

    /// `Documents/MegramPlugins`. Inside Documents so the user can drop files in over USB/Files
    /// and see what is installed, which is how every other plugin host on iOS behaves.
    public var pluginsDirectory: URL {
        let documents = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("MegramPlugins", isDirectory: true)
    }

    public func dataDirectory(pluginId: String) -> URL {
        return self.pluginsDirectory.appendingPathComponent("data_\(pluginId)", isDirectory: true)
    }

    private func ensureDirectory(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        if self.fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return
            }
            try self.fileManager.removeItem(at: url)
        }
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    // MARK: - Listing

    /// Installed plugins, newest first. Files that no longer parse are skipped rather than shown
    /// as broken rows — a half-written file in the directory is not something the user did.
    public func installedPlugins() -> [MGInstalledPlugin] {
        guard let entries = try? self.fileManager.contentsOfDirectory(
            at: self.pluginsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let disabled = Set(self.defaults.stringArray(forKey: Keys.disabledPluginIds) ?? [])
        var result: [(plugin: MGInstalledPlugin, date: Date)] = []

        for url in entries {
            guard let format = MGPluginFormat(fileExtension: url.pathExtension) else {
                continue
            }
            guard let source = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }
            guard let manifest = MGPluginManifestParser.parse(
                source: source,
                fileName: url.lastPathComponent,
                format: format
            ) else {
                continue
            }
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            result.append((
                MGInstalledPlugin(
                    manifest: manifest,
                    fileURL: url,
                    isEnabled: !disabled.contains(manifest.id),
                    isBuiltIn: false
                ),
                modified
            ))
        }

        return result.sorted { $0.date > $1.date }.map { $0.plugin }
    }

    public func source(of plugin: MGInstalledPlugin) -> String? {
        return try? String(contentsOf: plugin.fileURL, encoding: .utf8)
    }

    // MARK: - Install / remove

    /// Copies a plugin file into the plugins directory. `.py` is rejected here rather than at the
    /// picker so the user gets a sentence explaining why instead of a file that silently never runs.
    @discardableResult
    public func install(from sourceURL: URL) throws -> MGInstalledPlugin {
        guard let format = MGPluginFormat(fileExtension: sourceURL.pathExtension) else {
            throw MGPluginInstallError.unsupportedExtension(sourceURL.pathExtension)
        }
        guard format.isJavaScript else {
            throw MGPluginInstallError.noRuntime(format)
        }

        // Files handed over by UIDocumentPicker live outside our sandbox.
        let needsScopedAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let source = try? String(contentsOf: sourceURL, encoding: .utf8) else {
            throw MGPluginInstallError.unreadableFile
        }
        return try self.install(source: source, fileName: sourceURL.lastPathComponent)
    }

    @discardableResult
    public func install(source: String, fileName: String) throws -> MGInstalledPlugin {
        guard let format = MGPluginFormat(fileExtension: (fileName as NSString).pathExtension) else {
            throw MGPluginInstallError.unsupportedExtension((fileName as NSString).pathExtension)
        }
        guard format.isJavaScript else {
            throw MGPluginInstallError.noRuntime(format)
        }
        guard let manifest = MGPluginManifestParser.parse(source: source, fileName: fileName, format: format) else {
            throw MGPluginInstallError.missingName
        }

        do {
            try self.ensureDirectory(self.pluginsDirectory)
            // Reinstalling replaces in place, keyed by id, so an update does not leave the old
            // copy behind under a slightly different file name.
            for existing in self.installedPlugins() where existing.id == manifest.id {
                try? self.fileManager.removeItem(at: existing.fileURL)
            }
            let destination = self.pluginsDirectory.appendingPathComponent(fileName)
            try source.write(to: destination, atomically: true, encoding: .utf8)
            self.setEnabled(true, pluginId: manifest.id)
            return MGInstalledPlugin(manifest: manifest, fileURL: destination, isEnabled: true, isBuiltIn: false)
        } catch let error as MGPluginInstallError {
            throw error
        } catch {
            throw MGPluginInstallError.writeFailed(error.localizedDescription)
        }
    }

    public func remove(pluginId: String) {
        for plugin in self.installedPlugins() where plugin.id == pluginId {
            try? self.fileManager.removeItem(at: plugin.fileURL)
        }
        try? self.fileManager.removeItem(at: self.dataDirectory(pluginId: pluginId))
        self.clearSettings(pluginId: pluginId)

        var disabled = self.defaults.stringArray(forKey: Keys.disabledPluginIds) ?? []
        disabled.removeAll { $0 == pluginId }
        self.defaults.set(disabled, forKey: Keys.disabledPluginIds)
    }

    // MARK: - Enabled state

    public func isEnabled(pluginId: String) -> Bool {
        let disabled = self.defaults.stringArray(forKey: Keys.disabledPluginIds) ?? []
        return !disabled.contains(pluginId)
    }

    public func setEnabled(_ enabled: Bool, pluginId: String) {
        var disabled = self.defaults.stringArray(forKey: Keys.disabledPluginIds) ?? []
        if enabled {
            disabled.removeAll { $0 == pluginId }
        } else if !disabled.contains(pluginId) {
            disabled.append(pluginId)
        }
        self.defaults.set(disabled, forKey: Keys.disabledPluginIds)
    }

    // MARK: - Per-plugin storage

    public func setting(pluginId: String, key: String) -> String? {
        return self.defaults.string(forKey: Keys.setting(pluginId: pluginId, key: key))
    }

    public func setSetting(pluginId: String, key: String, value: String?) {
        let storageKey = Keys.setting(pluginId: pluginId, key: key)
        if let value {
            self.defaults.set(value, forKey: storageKey)
        } else {
            self.defaults.removeObject(forKey: storageKey)
        }
    }

    public func clearSettings(pluginId: String) {
        let prefix = Keys.settingPrefix(pluginId: pluginId)
        for key in self.defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            self.defaults.removeObject(forKey: key)
        }
    }

    /// Creates the plugin's own writable directory on first use and returns its path.
    public func ensuredDataDirectoryPath(pluginId: String) -> String {
        let url = self.dataDirectory(pluginId: pluginId)
        try? self.ensureDirectory(url)
        return url.path
    }
}
