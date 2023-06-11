public enum Tool: CaseIterable, Identifiable {
    case htmlToSwift
    case jsonPretty
    case textCaseConverter

    public var id: Self { self }

    public var name: String {
        switch self {
        case .htmlToSwift:
            return "HTML to Swift"
        case .jsonPretty:
            return "JSON Formatter"
        case .textCaseConverter:
            return "Text Case Converter"
        }
    }
}
