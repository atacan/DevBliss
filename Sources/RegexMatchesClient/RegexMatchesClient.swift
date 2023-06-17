import CoreGraphics
import Dependencies
import Foundation
import SwiftUI

public struct RegexMatchesClient {
    public var matches:
        @Sendable (NSAttributedString, String, RegexMatchesConfig) async throws -> RegexMatchesHighlightOutput
}

extension RegexMatchesClient: DependencyKey {
    public static let liveValue = Self(matches: { input, pattern, config in
        highlightRegexMatches(in: input, pattern: pattern, config: config)
    })
}

extension DependencyValues {
    public var regexMatches: RegexMatchesClient {
        get { self[RegexMatchesClient.self] }
        set { self[RegexMatchesClient.self] = newValue }
    }
}

func matchRegex(
    in attributedString: NSAttributedString,
    pattern: String
) -> [RegexMatchesOutput] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return []
    }

    let string = attributedString.string
    let range = NSRange(location: 0, length: string.utf16.count)
    let matches = regex.matches(in: string, options: [], range: range)

    return matches.map { match in
        let matchString = (string as NSString).substring(with: match.range)
        let groupRanges = (0 ..< match.numberOfRanges)
            .map { index in
                match.range(at: index)
            }
        let groups = groupRanges.dropFirst()
            .map { range in
                (string as NSString).substring(with: range)
            }
        return RegexMatchesOutput(
            wholeMatch: matchString,
            capturedGroups: groups,
            wholeMatchRange: match.range,
            capturedGroupRanges: .init(groupRanges.dropFirst())
        )
    }
}

public struct RegexMatchesOutput: Equatable {
    public let wholeMatch: String
    public let capturedGroups: [String]
    public let wholeMatchRange: NSRange
    public let capturedGroupRanges: [NSRange]
}

public struct RegexMatchesHighlightOutput: Equatable {
    public let highlighted: NSMutableAttributedString
    public let output: [RegexMatchesOutput]
}

public struct RegexMatchesConfig: Equatable {
    let wholeMatchColor: CGColor
    let capturedGroupColor: CGColor

    public init(
        wholeMatchColor: CGColor,
        capturedGroupColor: CGColor
    ) {
        self.wholeMatchColor = wholeMatchColor
        self.capturedGroupColor = capturedGroupColor
    }
}

func highlightRegexMatches(
    in attributedString: NSAttributedString,
    pattern: String,
    config: RegexMatchesConfig
) -> RegexMatchesHighlightOutput {
    let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
    let matchOutputs = matchRegex(in: attributedString, pattern: pattern)

    for matchOutput in matchOutputs {
        #if os(macOS)
            let wholeMatchColor = NSColor(cgColor: config.wholeMatchColor)
            let captureColor = NSColor(cgColor: config.capturedGroupColor)
        #else
            let wholeMatchColor = UIColor(cgColor: config.wholeMatchColor)
            let captureColor = UIColor(cgColor: config.capturedGroupColor)
        #endif
        let wholeMatchAttributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: wholeMatchColor
        ]
        mutableAttributedString.addAttributes(wholeMatchAttributes, range: matchOutput.wholeMatchRange)
        matchOutput.capturedGroupRanges.forEach { range in
            let captureAttributes: [NSAttributedString.Key: Any] = [
                .backgroundColor: captureColor
            ]
            mutableAttributedString.addAttributes(captureAttributes, range: range)
        }
    }

    return .init(highlighted: mutableAttributedString, output: matchOutputs)
}
