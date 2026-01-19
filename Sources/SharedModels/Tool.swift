import Foundation

public enum Tool: Int, CaseIterable, Identifiable {
    case htmlToSwift
    case htmlToMarkdown
    case urlToMarkdown
    case textCaseConverter
    case prefixSuffix
    case regexMatches
    case jsonPretty
    case swiftPrettyLockwood
    case fileContentSearch
    case nameGenerator
    case uuidGenerator
    case base64
    case base64Image
    case unixTime
    case urlEncode

    public var id: Self { self }

    public var name: String {
        switch self {
        case .htmlToSwift:
            return NSLocalizedString("HTML to Swift", bundle: Bundle.module, comment: "")
        case .htmlToMarkdown:
            return NSLocalizedString("HTML to Markdown", bundle: Bundle.module, comment: "")
        case .urlToMarkdown:
            return NSLocalizedString("URL to Markdown", bundle: Bundle.module, comment: "")
        case .jsonPretty:
            return NSLocalizedString("JSON Formatter", bundle: Bundle.module, comment: "")
        case .textCaseConverter:
            return NSLocalizedString("Text Case Converter", bundle: Bundle.module, comment: "")
        case .uuidGenerator:
            return NSLocalizedString("UUID Generator", bundle: Bundle.module, comment: "")
        case .prefixSuffix:
            return NSLocalizedString("Prefix Suffix", bundle: Bundle.module, comment: "")
        case .regexMatches:
            return NSLocalizedString("Regex Matches", bundle: Bundle.module, comment: "")
        case .swiftPrettyLockwood:
            return NSLocalizedString("Swift Pretty", bundle: Bundle.module, comment: "")
        case .fileContentSearch:
            return NSLocalizedString("File Content Search", bundle: Bundle.module, comment: "")
        case .nameGenerator:
            return NSLocalizedString("Name Generator", bundle: Bundle.module, comment: "")
        case .base64:
            return NSLocalizedString("Base64", bundle: Bundle.module, comment: "")
        case .base64Image:
            return NSLocalizedString("Base64 Image", bundle: Bundle.module, comment: "")
        case .unixTime:
            return NSLocalizedString("Unix Time", bundle: Bundle.module, comment: "")
        case .urlEncode:
            return NSLocalizedString("URL Encode", bundle: Bundle.module, comment: "")
        }
    }

    public var isInputtable: Bool {
        switch self {
        case .htmlToSwift:
            return true
        case .htmlToMarkdown:
            return true
        case .urlToMarkdown:
            return false
        case .jsonPretty:
            return true
        case .textCaseConverter:
            return true
        case .uuidGenerator:
            return false
        case .prefixSuffix:
            return true
        case .regexMatches:
            return true
        case .swiftPrettyLockwood:
            return true
        case .fileContentSearch:
            return false
        case .nameGenerator:
            return false
        case .base64:
            return true
        case .base64Image:
            return true
        case .unixTime:
            return true
        case .urlEncode:
            return true
        }
    }

    var isActive: Bool {
        switch self {
        case .uuidGenerator:
            return false
        case .fileContentSearch:
            #if os(macOS)
                return true
            #else
                return false
            #endif
        default:
            return true
        }
    }

    public func previous() -> Self {
        let all = Self.allCases.filter(\.isActive)
        var idx = all.firstIndex(of: self)!
        if idx == all.startIndex {
            let lastIndex = all.index(all.endIndex, offsetBy: -1)
            return all[lastIndex]
        }
        else {
            all.formIndex(&idx, offsetBy: -1)
            return all[idx]
        }
    }

    public func next() -> Self {
        let all = Self.allCases.filter(\.isActive)
        let idx = all.firstIndex(of: self)!
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }
}

public enum SettingsKey {
    public enum PrefixSuffix {
        public static var prefixReplace = "PrefixSuffix_prefixReplace"
        public static var prefixReplaceWith = "PrefixSuffix_prefixReplaceWith"
        public static var prefixAdd = "PrefixSuffix_prefixAdd"
        public static var suffixReplace = "PrefixSuffix_suffixReplace"
        public static var suffixReplaceWith = "PrefixSuffix_suffixReplaceWith"
        public static var suffixAdd = "PrefixSuffix_suffixAdd"
        public static var trimWhiteSpace = "PrefixSuffix_trimWhiteSpace"
        public static var splitViewFraction = "PrefixSuffix_splitViewFraction"
        public static var splitViewLayout = "PrefixSuffix_splitViewLayout"
    }

    public enum JsonPretty {
        public static var splitViewFraction = "JsonPretty_splitViewFraction"
        public static var splitViewLayout = "JsonPretty_splitViewLayout"
    }

    public enum HtmlToSwift {
        public static var dsl = "HtmlToSwift_dsl"
        public static var component = "HtmlToSwift_component"
        public static var splitViewFraction = "HtmlToSwift_splitViewFraction"
        public static var splitViewLayout = "HtmlToSwift_splitViewLayout"
    }

    public enum TextCaseConverter {
        public static var sourceCase = "TextCaseConverter_sourceCase"
        public static var targetCase = "TextCaseConverter_targetCase"
        public static var textSeperator = "TextCaseConverter_textSeperator"

        public static var splitViewFraction = "TextCaseConverter_splitViewFraction"
        public static var splitViewLayout = "TextCaseConverter_splitViewLayout"
    }

    public enum SwiftPretty {
        public static var lockwoodConfig = "SwiftPretty_lockwoodConfig"
        public static var splitViewFraction = "SwiftPretty_splitViewFraction"
        public static var splitViewLayout = "SwiftPretty_splitViewLayout"
    }

    public enum HtmlToMarkdown {
        public static var splitViewFraction = "HtmlToMarkdown_splitViewFraction"
        public static var splitViewLayout = "HtmlToMarkdown_splitViewLayout"
    }

    public enum Base64 {
        public static var mode = "Base64_mode"
        public static var autoDetect = "Base64_autoDetect"
        public static var autoRemoveDataURLPrefix = "Base64_autoRemoveDataURLPrefix"
        public static var autoRemoveNullBytes = "Base64_autoRemoveNullBytes"
        public static var splitViewFraction = "Base64_splitViewFraction"
        public static var splitViewLayout = "Base64_splitViewLayout"
    }

    public enum UnixTime {
        public static var splitViewFraction = "UnixTime_splitViewFraction"
        public static var splitViewLayout = "UnixTime_splitViewLayout"
    }

    public enum Base64Image {
        public static var splitViewFraction = "Base64Image_splitViewFraction"
        public static var splitViewLayout = "Base64Image_splitViewLayout"
    }
}
