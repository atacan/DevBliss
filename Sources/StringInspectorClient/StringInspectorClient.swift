import Dependencies
import Foundation

public struct StringInspectorClient {
    public var inspect: @Sendable (String) -> StringInspectorResult
}

public struct StringInspectorResult: Equatable, Codable {
    public var characters: Int
    public var unicodeScalars: Int
    public var words: Int
    public var lines: Int
    public var bytesUTF8: Int
    public var whitespace: Int
    public var isASCII: Bool
    public var isEmpty: Bool
}

extension StringInspectorClient: DependencyKey {
    public static let liveValue = Self(
        inspect: { input in
            let words = input.split { $0.isWhitespace }.count
            let lines = input.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
            let whitespace = input.filter { $0.isWhitespace }.count
            let isASCII = input.unicodeScalars.allSatisfy { $0.value <= 0x7F }

            return StringInspectorResult(
                characters: input.count,
                unicodeScalars: input.unicodeScalars.count,
                words: words,
                lines: input.isEmpty ? 0 : lines,
                bytesUTF8: input.utf8.count,
                whitespace: whitespace,
                isASCII: isASCII,
                isEmpty: input.isEmpty
            )
        }
    )
}

extension DependencyValues {
    public var stringInspector: StringInspectorClient {
        get { self[StringInspectorClient.self] }
        set { self[StringInspectorClient.self] = newValue }
    }
}
