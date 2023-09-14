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
    var matchesOutput: [RegexMatchesOutput] = []

    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsString = attributedString.string as NSString

        let matches = regex.matches(
            in: attributedString.string,
            options: [],
            range: NSRange(location: 0, length: nsString.length)
        )

        for match in matches {
            let wholeMatchRange = match.range(at: 0)
            let wholeMatch = nsString.substring(with: wholeMatchRange)

            var capturedGroups: [String] = []
            var capturedGroupRanges: [NSRange] = []

            for i in 1 ..< match.numberOfRanges {
                let capturedGroupRange = match.range(at: i)
                if capturedGroupRange.location != NSNotFound {
                    let capturedGroup = nsString.substring(with: capturedGroupRange)
                    capturedGroups.append(capturedGroup)
                    capturedGroupRanges.append(capturedGroupRange)
                }
            }

            let matchOutput = RegexMatchesOutput(
                wholeMatch: wholeMatch,
                capturedGroups: capturedGroups,
                wholeMatchRange: wholeMatchRange,
                capturedGroupRanges: capturedGroupRanges
            )

            matchesOutput.append(matchOutput)
        }

    } catch {
        // Handle errors here if necessary
//            print("Error creating regex: \(error)")
        return matchesOutput
    }

    return matchesOutput
}

extension NSRegularExpression {
    func captureGroups(in string: String, range: NSRange) -> [NSTextCheckingResult] {
        let matches = matches(in: string, options: [], range: range)
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else {
                return nil
            }
            return match.range(at: 1) == NSRange(location: NSNotFound, length: 0) ? nil : match
        }
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
            .backgroundColor: wholeMatchColor,
        ]
        mutableAttributedString.addAttributes(wholeMatchAttributes, range: matchOutput.wholeMatchRange)
        matchOutput.capturedGroupRanges.forEach { range in
            let captureAttributes: [NSAttributedString.Key: Any] = [
                .backgroundColor: captureColor,
            ]
            mutableAttributedString.addAttributes(captureAttributes, range: range)
        }
    }

    return .init(highlighted: mutableAttributedString, output: matchOutputs)
}
