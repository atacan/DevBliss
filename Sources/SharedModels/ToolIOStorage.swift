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
    public static var certificateDecoderIO: Self { .fileStorage(.toolStorage("certificateDecoder")) }
    public static var qrCodeToolIO: Self { .fileStorage(.toolStorage("qrCodeTool")) }
    public static var jsonToYamlIO: Self { .fileStorage(.toolStorage("jsonToYaml")) }
    public static var yamlToJsonIO: Self { .fileStorage(.toolStorage("yamlToJson")) }
    public static var uuidUlidIO: Self { .fileStorage(.toolStorage("uuidUlid")) }
    public static var colorConverterIO: Self { .fileStorage(.toolStorage("colorConverter")) }
    public static var svgToCssIO: Self { .fileStorage(.toolStorage("svgToCss")) }
    public static var backslashEscapeIO: Self { .fileStorage(.toolStorage("backslashEscape")) }
    public static var xmlFormatIO: Self { .fileStorage(.toolStorage("xmlFormat")) }
    public static var htmlBeautifyIO: Self { .fileStorage(.toolStorage("htmlBeautify")) }
    public static var cssBeautifyIO: Self { .fileStorage(.toolStorage("cssBeautify")) }
    public static var jsBeautifyIO: Self { .fileStorage(.toolStorage("jsBeautify")) }
    public static var lineSortDedupeIO: Self { .fileStorage(.toolStorage("lineSortDedupe")) }
    public static var asciiToHexIO: Self { .fileStorage(.toolStorage("asciiToHex")) }
    public static var hexToAsciiIO: Self { .fileStorage(.toolStorage("hexToAscii")) }
    public static var randomStringGeneratorIO: Self { .fileStorage(.toolStorage("randomStringGenerator")) }
    public static var hashGeneratorIO: Self { .fileStorage(.toolStorage("hashGenerator")) }
    public static var stringInspectorIO: Self { .fileStorage(.toolStorage("stringInspector")) }
    public static var numberBaseConverterIO: Self { .fileStorage(.toolStorage("numberBaseConverter")) }
    public static var urlParserIO: Self { .fileStorage(.toolStorage("urlParser")) }
    public static var regExpTesterIO: Self { .fileStorage(.toolStorage("regExpTester")) }
    public static var htmlPreviewIO: Self { .fileStorage(.toolStorage("htmlPreview")) }
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
    public static var jwtDebuggerIO: Self { .fileStorage(.toolStorage("jwtDebugger")) }
}

extension SharedReaderKey where Self == FileStorageKey<ToolIOStorageDoubleOutput> {
    public static var regexMatchesIO: Self { .fileStorage(.toolStorage("regexMatches")) }
}

extension SharedReaderKey where Self == FileStorageKey<Base64ImageStorage> {
    public static var base64ImageIO: Self { .fileStorage(.toolStorage("base64Image")) }
}
