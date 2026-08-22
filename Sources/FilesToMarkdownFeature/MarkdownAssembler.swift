import Foundation

public struct CombineOptions: Equatable, Sendable {
    public var folderPath: String
    public var includeHidden: Bool
    public var respectGitignore: Bool
    public var includedExtensions: Set<String>
    public var includeFileList: Bool
    public var prefix: String
    public var suffix: String

    public init(
        folderPath: String = "",
        includeHidden: Bool = false,
        respectGitignore: Bool = true,
        includedExtensions: Set<String> = Set(defaultExtensions),
        includeFileList: Bool = false,
        prefix: String = "",
        suffix: String = ""
    ) {
        self.folderPath = folderPath
        self.includeHidden = includeHidden
        self.respectGitignore = respectGitignore
        self.includedExtensions = includedExtensions
        self.includeFileList = includeFileList
        self.prefix = prefix
        self.suffix = suffix
    }

    public static let defaultExtensions: [String] = [
        "swift", "m", "mm", "h", "c", "cc", "cpp", "hpp",
        "js", "jsx", "mjs", "cjs", "ts", "tsx",
        "py", "rb", "go", "rs", "java", "kt", "kts", "cs", "dart", "php", "lua",
        "sh", "bash", "zsh",
        "html", "htm", "css", "scss", "sass", "less",
        "json", "yaml", "yml", "xml", "plist", "sql",
        "md", "markdown", "txt", "toml", "ini", "cfg",
        "gradle", "groovy", "graphql", "proto", "env",
    ]
}

public struct DiscoveredFile: Equatable, Identifiable, Sendable {
    public let url: URL
    public let relativePath: String

    public init(url: URL, relativePath: String) {
        self.url = url
        self.relativePath = relativePath
    }

    public var id: String { relativePath }
}

public struct AssembledResult: Equatable, Sendable {
    public let markdown: String
    public let skippedCount: Int

    public init(markdown: String, skippedCount: Int) {
        self.markdown = markdown
        self.skippedCount = skippedCount
    }
}

public enum MarkdownAssembler {
    public static func assemble(
        files: [DiscoveredFile],
        contentProvider: @Sendable (DiscoveredFile) -> String?,
        options: CombineOptions,
        now: Date = Date()
    ) -> AssembledResult {
        let contents = files.map { file -> (DiscoveredFile, String?) in
            (file, contentProvider(file))
        }

        let included = contents.compactMap { pair -> (DiscoveredFile, String)? in
            guard let content = pair.1 else { return nil }
            return (pair.0, content)
        }
        let skippedCount = contents.count - included.count

        var longestBacktickRun = 0
        for (_, content) in included {
            longestBacktickRun = max(longestBacktickRun, longestRunOfBackticks(content))
        }
        let fence = String(repeating: "`", count: max(3, longestBacktickRun + 1))

        var parts: [String] = []

        let substitutedPrefix = substitutePlaceholders(
            in: options.prefix,
            folderName: folderName(from: options.folderPath),
            fileCount: included.count,
            date: now
        )
        if !substitutedPrefix.isEmpty {
            parts.append(substitutedPrefix)
        }

        if options.includeFileList, !included.isEmpty {
            let listItems = included.map { "- \($0.0.relativePath)" }.joined(separator: "\n")
            parts.append("## Files\n\n\(listItems)")
        }

        for (file, content) in included {
            let language = languageIdentifier(forURL: file.url)
            let info: String
            if let language {
                info = "\(language):\(file.relativePath)"
            } else {
                info = file.relativePath
            }
            parts.append("\(fence)\(info)\n\(content)\n\(fence)")
        }

        let substitutedSuffix = substitutePlaceholders(
            in: options.suffix,
            folderName: folderName(from: options.folderPath),
            fileCount: included.count,
            date: now
        )
        if !substitutedSuffix.isEmpty {
            parts.append(substitutedSuffix)
        }

        let markdown = parts.joined(separator: "\n\n")
        return AssembledResult(markdown: markdown, skippedCount: skippedCount)
    }

    public static func substitutePlaceholders(
        in text: String,
        folderName: String,
        fileCount: Int,
        date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        return text
            .replacingOccurrences(of: "{folderName}", with: folderName)
            .replacingOccurrences(of: "{fileCount}", with: String(fileCount))
            .replacingOccurrences(of: "{date}", with: formatter.string(from: date))
    }

    public static func longestRunOfBackticks(_ text: String) -> Int {
        var longest = 0
        var current = 0
        for character in text.utf8 {
            if character == UInt8(ascii: "`") {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    static func languageIdentifier(forURL url: URL) -> String? {
        LanguageMap.languageIdentifier(forExtension: url.pathExtension)
    }

    static func folderName(from path: String) -> String {
        guard !path.isEmpty else { return "" }
        return URL(fileURLWithPath: path).lastPathComponent
    }
}
