//
// https://github.com/atacan
// 16.06.23

import Dependencies
import Foundation

public struct PrefixSuffixClient {
    public var convert: @Sendable (String, PrefixSuffixConfig) async throws -> String
}

public struct PrefixSuffixConfig: Equatable {
    public var prefixReplace: String
    public var prefixReplaceWith: String
    public var prefixAdd: String
    public var suffixReplace: String
    public var suffixReplaceWith: String
    public var suffixAdd: String
    public var trimWhiteSpace: Bool

    public init(
        prefixReplace: String = .init(),
        prefixReplaceWith: String = .init(),
        prefixAdd: String = .init(),
        suffixReplace: String = .init(),
        suffixReplaceWith: String = .init(),
        suffixAdd: String = .init(),
        trimWhiteSpace: Bool = .init()
    ) {
        self.prefixReplace = prefixReplace
        self.prefixReplaceWith = prefixReplaceWith
        self.prefixAdd = prefixAdd
        self.suffixReplace = suffixReplace
        self.suffixReplaceWith = suffixReplaceWith
        self.suffixAdd = suffixAdd
        self.trimWhiteSpace = trimWhiteSpace
    }
}

extension PrefixSuffixClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            input.components(separatedBy: .newlines)
                .map { line in
                    convertLine(input: line, config: config)
                }
                .joined(separator: "\n")
        }
    )
}

extension DependencyValues {
   public var prefixSuffix: PrefixSuffixClient {
       get { self[PrefixSuffixClient.self] }
       set { self[PrefixSuffixClient.self] = newValue }
   }
}

extension String {
    fileprivate mutating func prepend(_ prefix: String) {
        self = prefix + self
    }

    fileprivate mutating func replace(prefix: String, with newValue: String) {
        if self.hasPrefix(prefix) {
            self = String(self.dropFirst(prefix.count))
            self.prepend(newValue)
        }
    }

    fileprivate mutating func replace(suffix: String, with newValue: String) {
        if self.hasSuffix(suffix) {
            self = String(self.dropLast(suffix.count))
            self.append(newValue)
        }
    }

    fileprivate func leadingWhiteSpace() -> Substring {
        let regexLeadingWhiteSpace = #"^\s*"#
        if let leadingWhiteRange = range(of: regexLeadingWhiteSpace, options: .regularExpression) {
            return self[leadingWhiteRange]
        }
        return ""
    }

    fileprivate func trailingWhiteSpace() -> Substring {
        let regexTrailingWhiteSpace = #"\s*$"#
        if let trailingWhiteRange = range(of: regexTrailingWhiteSpace, options: .regularExpression) {
            return self[trailingWhiteRange]
        }
        return ""
    }
}

private func convertLine(input: String, config: PrefixSuffixConfig) -> String {
    var output = input.trimmingCharacters(in: .whitespacesAndNewlines)
    output.replace(prefix: config.prefixReplace, with: config.prefixReplaceWith)
    output.prepend(config.prefixAdd)
    output.replace(suffix: config.suffixReplace, with: config.suffixReplaceWith)
    output.append(config.suffixAdd)
    if !config.trimWhiteSpace {
        let leading = input.leadingWhiteSpace()
        let trailing = input.trailingWhiteSpace()
        return leading + output + trailing
    }
    return output
}
