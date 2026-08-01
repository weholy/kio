import Foundation

// MARK: - Plugin file format
//
// A plugin is a plain text file whose extension selects nothing but the icon we show: every
// supported extension carries JavaScript, executed by the system JavaScriptCore. The header is
// a run of leading comment lines carrying `@key value` pairs; everything after it is the code.
//
//     // @name        My plugin
//     // @version     1.0
//     // @description Does a thing
//     //
//     // @readme_start
//     // <h2>My plugin</h2>
//     // @readme_end
//
//     mg.on("onAppStart", function () { mg.toast("hello") })
//
// Both `//` and `#` comment markers are accepted so a file written for a Python-flavoured host
// still parses; the body is always JavaScript.

public enum MGPluginFormat: String, CaseIterable {
    case plugin
    case mgplugin
    case js
    case mjs
    case py

    public static let supportedExtensions: [String] = MGPluginFormat.allCases.map { $0.rawValue }

    public init?(fileExtension: String) {
        self.init(rawValue: fileExtension.lowercased())
    }

    /// Every supported extension is executed as JavaScript. `.py` is accepted by the importer so
    /// a mistyped extension produces a readable message rather than a silent failure, but it has
    /// no interpreter behind it — see `MGPluginValidation`.
    public var isJavaScript: Bool {
        switch self {
        case .plugin, .mgplugin, .js, .mjs:
            return true
        case .py:
            return false
        }
    }

    public var displayName: String {
        switch self {
        case .plugin, .mgplugin:
            return "Megram"
        case .js:
            return "JavaScript"
        case .mjs:
            return "JavaScript (ESM)"
        case .py:
            return "Python"
        }
    }
}

public struct MGPluginManifest: Equatable {
    /// Stable identity derived from the file name, not from `@name` — renaming a plugin in its
    /// header must not orphan its stored settings.
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let summary: String
    /// HTML shown on long-press. Nil when the file carries no `@readme` block.
    public let readmeHTML: String?
    /// Raw `@icon` value: a `data:` URI, a bare base64 payload, or a file reference.
    public let iconSource: String?
    public let format: MGPluginFormat

    public init(
        id: String,
        name: String,
        version: String,
        author: String,
        summary: String,
        readmeHTML: String?,
        iconSource: String?,
        format: MGPluginFormat
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.summary = summary
        self.readmeHTML = readmeHTML
        self.iconSource = iconSource
        self.format = format
    }
}

public struct MGPluginValidation {
    public enum Level {
        case ok
        case warning
        case failure
    }

    public struct Check {
        public let title: String
        public let level: Level
        public let detail: String?

        public init(title: String, level: Level, detail: String? = nil) {
            self.title = title
            self.level = level
            self.detail = detail
        }
    }

    public let checks: [Check]

    public init(checks: [Check]) {
        self.checks = checks
    }

    /// A plugin installs in one tap only when nothing failed. Warnings still install, they just
    /// mean the file may not be a plugin at all (no API calls anywhere in it).
    public var canInstallDirectly: Bool {
        return !self.checks.contains { check in
            if case .failure = check.level {
                return true
            }
            return false
        }
    }
}

public enum MGPluginManifestParser {
    private static let headerKeyPrefixes = ["//", "#"]

    /// Parses the header of a plugin file. Returns nil only when the file has no `@name`, which
    /// is the one field we cannot invent.
    public static func parse(source: String, fileName: String, format: MGPluginFormat) -> MGPluginManifest? {
        var values: [String: String] = [:]
        var readmeLines: [String] = []
        var inReadme = false

        for rawLine in source.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let body = strippedComment(line) else {
                // The header is the leading comment block. A blank line inside it is fine; the
                // first line of real code ends it.
                if line.isEmpty {
                    continue
                }
                break
            }

            if body == "@readme_start" {
                inReadme = true
                continue
            }
            if body == "@readme_end" {
                inReadme = false
                continue
            }
            if inReadme {
                readmeLines.append(body)
                continue
            }

            guard body.hasPrefix("@") else {
                continue
            }
            let withoutAt = String(body.dropFirst())
            guard let separator = withoutAt.rangeOfCharacter(from: .whitespaces) else {
                values[withoutAt.lowercased()] = ""
                continue
            }
            let key = String(withoutAt[withoutAt.startIndex ..< separator.lowerBound]).lowercased()
            let value = String(withoutAt[separator.upperBound...]).trimmingCharacters(in: .whitespaces)
            values[key] = value
        }

        guard let name = values["name"], !name.isEmpty else {
            return nil
        }

        let readmeHTML = readmeLines.isEmpty ? nil : readmeLines.joined(separator: "\n")

        return MGPluginManifest(
            id: self.identifier(forFileName: fileName),
            name: name,
            version: values["version"] ?? "1.0",
            author: values["author"] ?? "",
            summary: values["description"] ?? "",
            readmeHTML: readmeHTML,
            iconSource: values["icon"],
            format: format
        )
    }

    /// Returns the text of a header comment line, or nil when the line is not a comment (which
    /// ends the header). `//` and `#` are both accepted so a file authored for a Python-flavoured
    /// host still yields its metadata.
    private static func strippedComment(_ line: String) -> String? {
        for prefix in self.headerKeyPrefixes where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    /// `My Plugin v2.js` → `my_plugin_v2`. Lowercased ASCII so the id can be a directory name and
    /// a `UserDefaults` key suffix on every filesystem.
    public static func identifier(forFileName fileName: String) -> String {
        let base = (fileName as NSString).deletingPathExtension
        var result = ""
        var lastWasSeparator = false
        for character in base.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(character), character.isASCII {
                result.unicodeScalars.append(character)
                lastWasSeparator = false
            } else if !lastWasSeparator, !result.isEmpty {
                result.append("_")
                lastWasSeparator = true
            }
        }
        while result.hasSuffix("_") {
            result.removeLast()
        }
        return result.isEmpty ? "plugin" : result
    }

    /// Static analysis shown in the install sheet. Deliberately cheap and syntactic — the point is
    /// to catch "this is not a plugin" and "this will not parse", not to sandbox anything.
    public static func validate(source: String, format: MGPluginFormat) -> MGPluginValidation {
        var checks: [MGPluginValidation.Check] = []

        let hasName = source.range(of: "@name", options: [.caseInsensitive]) != nil
        checks.append(MGPluginValidation.Check(
            title: "Метаданные",
            level: hasName ? .ok : .failure,
            detail: hasName ? nil : "В файле нет заголовка @name"
        ))

        let usesAPI = source.contains("mg.") || source.contains("mg[") || source.contains("wg.") || source.contains("wg[")
        checks.append(MGPluginValidation.Check(
            title: "Megram API",
            level: usesAPI ? .ok : .warning,
            detail: usesAPI ? nil : "Файл не обращается к API — возможно, это не плагин"
        ))

        if format.isJavaScript {
            if let error = self.javaScriptSyntaxError(in: source) {
                checks.append(MGPluginValidation.Check(title: "Синтаксис", level: .failure, detail: error))
            } else {
                checks.append(MGPluginValidation.Check(title: "Синтаксис", level: .ok, detail: nil))
            }
        } else {
            checks.append(MGPluginValidation.Check(
                title: "Рантайм",
                level: .failure,
                detail: "Megram выполняет плагины на JavaScript. Python-рантайма нет — сохраните плагин как .js"
            ))
        }

        return MGPluginValidation(checks: checks)
    }

    /// Bracket/quote balance. A real parse happens in `MGPluginRuntime` when the plugin loads; this
    /// only has to be good enough to reject a truncated download before we write it to disk.
    private static func javaScriptSyntaxError(in source: String) -> String? {
        enum State {
            case code
            case lineComment
            case blockComment
            case string(terminator: Character)
        }

        var state = State.code
        var stack: [Character] = []
        var isEscaped = false
        var previous: Character?

        for character in source {
            switch state {
            case .lineComment:
                if character == "\n" {
                    state = .code
                }
                previous = character
            case .blockComment:
                if previous == "*", character == "/" {
                    state = .code
                    // Cleared so the closing slash cannot pair with the next character into a
                    // second comment marker.
                    previous = nil
                } else {
                    previous = character
                }
            case let .string(terminator):
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == terminator {
                    state = .code
                }
                previous = character
            case .code:
                switch character {
                case "/":
                    if previous == "/" {
                        state = .lineComment
                    }
                case "*":
                    if previous == "/" {
                        state = .blockComment
                    }
                case "\"", "'", "`":
                    state = .string(terminator: character)
                case "(", "[", "{":
                    stack.append(character)
                case ")", "]", "}":
                    let expected: Character = character == ")" ? "(" : (character == "]" ? "[" : "{")
                    guard stack.last == expected else {
                        return "Лишняя закрывающая скобка «\(character)»"
                    }
                    stack.removeLast()
                default:
                    break
                }
                previous = character
            }
        }

        if case .string = state {
            return "Незакрытая кавычка"
        }

        if let unclosed = stack.last {
            return "Незакрытая скобка «\(unclosed)»"
        }
        return nil
    }
}
