import Dependencies
import Foundation

public struct RegExpTesterClient {
    public var test: @Sendable (RegExpTestRequest) throws -> RegExpTestResult
}

public struct RegExpTestRequest: Equatable, Codable {
    public var pattern: String
    public var text: String
    public var replacement: String
    public var options: RegExpOptions

    public init(pattern: String, text: String, replacement: String, options: RegExpOptions) {
        self.pattern = pattern
        self.text = text
        self.replacement = replacement
        self.options = options
    }
}

public struct RegExpOptions: Equatable, Codable {
    public var caseInsensitive: Bool
    public var allowCommentsAndWhitespace: Bool
    public var dotMatchesLineSeparators: Bool
    public var anchorsMatchLines: Bool
    public var useUnicodeWordBoundaries: Bool

    public init(
        caseInsensitive: Bool = false,
        allowCommentsAndWhitespace: Bool = false,
        dotMatchesLineSeparators: Bool = false,
        anchorsMatchLines: Bool = false,
        useUnicodeWordBoundaries: Bool = false
    ) {
        self.caseInsensitive = caseInsensitive
        self.allowCommentsAndWhitespace = allowCommentsAndWhitespace
        self.dotMatchesLineSeparators = dotMatchesLineSeparators
        self.anchorsMatchLines = anchorsMatchLines
        self.useUnicodeWordBoundaries = useUnicodeWordBoundaries
    }
}

public struct RegExpMatch: Equatable, Codable, Identifiable {
    public var id: Int
    public var value: String
    public var range: NSRange
}

public struct RegExpTestResult: Equatable, Codable {
    public var matches: [RegExpMatch]
    public var replacedText: String
}

extension RegExpTesterClient: DependencyKey {
    public static let liveValue = Self(
        test: { request in
            let regex = try NSRegularExpression(pattern: request.pattern, options: request.options.nsOptions)
            let range = NSRange(request.text.startIndex..., in: request.text)
            let matches = regex.matches(in: request.text, range: range)

            let mappedMatches = matches.enumerated().map { index, match in
                let value = (request.text as NSString).substring(with: match.range)
                return RegExpMatch(id: index, value: value, range: match.range)
            }

            let replaced = regex.stringByReplacingMatches(
                in: request.text,
                range: range,
                withTemplate: request.replacement
            )

            return RegExpTestResult(matches: mappedMatches, replacedText: replaced)
        }
    )
}

extension DependencyValues {
    public var regExpTester: RegExpTesterClient {
        get { self[RegExpTesterClient.self] }
        set { self[RegExpTesterClient.self] = newValue }
    }
}

extension RegExpOptions {
    var nsOptions: NSRegularExpression.Options {
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        if allowCommentsAndWhitespace { options.insert(.allowCommentsAndWhitespace) }
        if dotMatchesLineSeparators { options.insert(.dotMatchesLineSeparators) }
        if anchorsMatchLines { options.insert(.anchorsMatchLines) }
        if useUnicodeWordBoundaries { options.insert(.useUnicodeWordBoundaries) }
        return options
    }
}
