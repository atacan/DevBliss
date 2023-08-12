public enum Tool: CaseIterable, Identifiable {
    case htmlToSwift
    case jsonPretty
    case textCaseConverter
    case uuidGenerator
    case prefixSuffix
    case regexMatches
    case swiftPrettyLockwood
    case fileContentSearch
    case nameGenerator

    public var id: Self { self }

    public var name: String {
        switch self {
        case .htmlToSwift:
            return "HTML to Swift"
        case .jsonPretty:
            return "JSON Formatter"
        case .textCaseConverter:
            return "Text Case Converter"
        case .uuidGenerator:
            return "UUID Generator"
        case .prefixSuffix:
            return "Prefix Suffix"
        case .regexMatches:
            return "Regex Matches"
        case .swiftPrettyLockwood:
            return "Swift Pretty"
        case .fileContentSearch:
            return "File Content Search"
        case .nameGenerator:
            return "Name Generator"
        }
    }

    public var isInputtable: Bool {
        switch self {
        case .htmlToSwift:
            return true
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
        }
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
}
