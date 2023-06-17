public enum Tool: CaseIterable, Identifiable {
    case htmlToSwift
    case jsonPretty
    case textCaseConverter
    case uuidGenerator
    case prefixSuffix
    case regexMatches

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
        }
    }
}
