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

// For Base64Image which stores image data and Base64 string
public struct Base64ImageStorage: Codable, Equatable {
    public var base64String: String
    public var imageData: Data?
    public var outputFormat: Base64ImageOutputFormat

    public init(
        base64String: String = "",
        imageData: Data? = nil,
        outputFormat: Base64ImageOutputFormat = .dataURL
    ) {
        self.base64String = base64String
        self.imageData = imageData
        self.outputFormat = outputFormat
    }
}

public enum Base64ImageOutputFormat: String, CaseIterable, Identifiable, Codable {
    case rawString = "Raw String"
    case dataURL = "Data URL"
    case cssAttribute = "CSS Attribute"

    public var id: Self { self }
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
    public static var base64IO: Self { .fileStorage(.toolStorage("base64")) }
    public static var unixTimeIO: Self { .fileStorage(.toolStorage("unixTime")) }
    public static var urlEncodeIO: Self { .fileStorage(.toolStorage("urlEncode")) }
}

extension SharedReaderKey where Self == FileStorageKey<ToolIOStorageDoubleOutput> {
    public static var regexMatchesIO: Self { .fileStorage(.toolStorage("regexMatches")) }
}

extension SharedReaderKey where Self == FileStorageKey<Base64ImageStorage> {
    public static var base64ImageIO: Self { .fileStorage(.toolStorage("base64Image")) }
}
