import Foundation
import ComposableArchitecture

// MARK: - Storage Models

public struct ToolIOStorage: Codable, Equatable {
    public var input: String
    public var output: String

    public init(input: String = "", output: String = "") {
        self.input = input
        self.output = output
    }
}

// For RegexMatches which has two outputs
public struct ToolIOStorageDoubleOutput: Codable, Equatable {
    public var input: String
    public var output: String
    public var outputSecond: String

    public init(input: String = "", output: String = "", outputSecond: String = "") {
        self.input = input
        self.output = output
        self.outputSecond = outputSecond
    }
}

// MARK: - URL Extensions

extension URL {
    static var toolStorageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ToolStorage")
    }

    static func toolStorage(_ tool: String) -> URL {
        toolStorageDirectory.appendingPathComponent("\(tool).json")
    }
}

// MARK: - FileStorage Keys

extension SharedReaderKey where Self == FileStorageKey<ToolIOStorage> {
    public static var textCaseConverterIO: Self { .fileStorage(.toolStorage("textCaseConverter")) }
    public static var prefixSuffixIO: Self { .fileStorage(.toolStorage("prefixSuffix")) }
    public static var htmlToSwiftIO: Self { .fileStorage(.toolStorage("htmlToSwift")) }
    public static var htmlToMarkdownIO: Self { .fileStorage(.toolStorage("htmlToMarkdown")) }
    public static var urlToMarkdownIO: Self { .fileStorage(.toolStorage("urlToMarkdown")) }
    public static var swiftPrettyIO: Self { .fileStorage(.toolStorage("swiftPretty")) }
    public static var jsonPrettyIO: Self { .fileStorage(.toolStorage("jsonPretty")) }
}

extension SharedReaderKey where Self == FileStorageKey<ToolIOStorageDoubleOutput> {
    public static var regexMatchesIO: Self { .fileStorage(.toolStorage("regexMatches")) }
}
