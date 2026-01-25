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

// Keep JSON for Base64Image metadata (binary + enum)
public struct Base64ImageMeta: Codable, Equatable {
    public var imageData: Data?
    public var outputFormat: Base64ImageOutputFormat

    public init(imageData: Data? = nil, outputFormat: Base64ImageOutputFormat = .dataURL) {
        self.imageData = imageData
        self.outputFormat = outputFormat
    }
}

// MARK: - URL Extensions

extension URL {
    public static var toolStorageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ToolStorage")
    }

    public static func toolStorage(_ tool: String) -> URL {
        toolStorageDirectory.appendingPathComponent("\(tool).json")
    }

    public static func plainTextStorage(_ tool: String, _ field: String) -> URL {
        toolStorageDirectory.appendingPathComponent("\(tool)_\(field).txt")
    }
}

// MARK: - Plain Text Storage Keys (Factory Pattern)

extension SharedReaderKey where Self == FileStorageKey<String> {
    public static func toolInput(_ tool: String) -> Self {
        .fileStorage(
            .plainTextStorage(tool, "input"),
            decode: { data in String(decoding: data, as: UTF8.self) },
            encode: { string in Data(string.utf8) }
        )
    }

    public static func toolOutput(_ tool: String) -> Self {
        .fileStorage(
            .plainTextStorage(tool, "output"),
            decode: { data in String(decoding: data, as: UTF8.self) },
            encode: { string in Data(string.utf8) }
        )
    }

    // For RegexMatches third output
    public static func toolOutputSecond(_ tool: String) -> Self {
        .fileStorage(
            .plainTextStorage(tool, "outputSecond"),
            decode: { data in String(decoding: data, as: UTF8.self) },
            encode: { string in Data(string.utf8) }
        )
    }

    // For Base64Image string storage
    public static var base64ImageString: Self {
        .fileStorage(
            .plainTextStorage("base64Image", "string"),
            decode: { data in String(decoding: data, as: UTF8.self) },
            encode: { string in Data(string.utf8) }
        )
    }
}

extension SharedReaderKey where Self == FileStorageKey<Base64ImageMeta> {
    public static var base64ImageMeta: Self { .fileStorage(.toolStorage("base64ImageMeta")) }
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

// MARK: - Migration Helper

public enum ToolStorageMigration {
    public static func migrateIfNeeded(tool: String) {
        let jsonURL = URL.toolStorage(tool)
        let inputURL = URL.plainTextStorage(tool, "input")

        // Skip if no old file or new file already exists
        guard FileManager.default.fileExists(atPath: jsonURL.path),
              !FileManager.default.fileExists(atPath: inputURL.path) else { return }

        do {
            let data = try Data(contentsOf: jsonURL)
            let storage = try JSONDecoder().decode(ToolIOStorage.self, from: data)

            // Create directory if needed
            try FileManager.default.createDirectory(
                at: URL.toolStorageDirectory,
                withIntermediateDirectories: true
            )

            // Write new text files
            try Data(storage.input.utf8).write(to: inputURL)
            try Data(storage.output.utf8).write(to: URL.plainTextStorage(tool, "output"))
        } catch {
            // Log but don't crash - user just loses saved state
        }
    }

    public static func migrateAllTools() {
        let tools = [
            "certificateDecoder", "qrCodeTool", "jsonToYaml", "yamlToJson",
            "uuidUlid", "colorConverter", "svgToCss", "backslashEscape",
            "xmlFormat", "htmlBeautify", "cssBeautify", "jsBeautify",
            "lineSortDedupe", "asciiToHex", "hexToAscii", "randomStringGenerator",
            "hashGenerator", "stringInspector", "numberBaseConverter", "urlParser",
            "regExpTester", "htmlPreview", "textCaseConverter", "prefixSuffix",
            "htmlToSwift", "htmlToMarkdown", "urlToMarkdown", "swiftPretty",
            "jsonPretty", "base64", "unixTime", "urlEncode", "jwtDebugger"
        ]
        tools.forEach { migrateIfNeeded(tool: $0) }

        // Special: RegexMatches (3 fields)
        migrateRegexMatchesIfNeeded()

        // Special: Base64Image
        migrateBase64ImageIfNeeded()
    }

    private static func migrateRegexMatchesIfNeeded() {
        let jsonURL = URL.toolStorage("regexMatches")
        let inputURL = URL.plainTextStorage("regexMatches", "input")

        guard FileManager.default.fileExists(atPath: jsonURL.path),
              !FileManager.default.fileExists(atPath: inputURL.path) else { return }

        do {
            let data = try Data(contentsOf: jsonURL)
            let storage = try JSONDecoder().decode(ToolIOStorageDoubleOutput.self, from: data)

            try FileManager.default.createDirectory(
                at: URL.toolStorageDirectory,
                withIntermediateDirectories: true
            )

            try Data(storage.input.utf8).write(to: inputURL)
            try Data(storage.output.utf8).write(to: URL.plainTextStorage("regexMatches", "output"))
            try Data(storage.outputSecond.utf8).write(to: URL.plainTextStorage("regexMatches", "outputSecond"))
        } catch {}
    }

    private static func migrateBase64ImageIfNeeded() {
        let jsonURL = URL.toolStorage("base64Image")
        let stringURL = URL.plainTextStorage("base64Image", "string")

        guard FileManager.default.fileExists(atPath: jsonURL.path),
              !FileManager.default.fileExists(atPath: stringURL.path) else { return }

        do {
            let data = try Data(contentsOf: jsonURL)
            let storage = try JSONDecoder().decode(Base64ImageStorage.self, from: data)

            try FileManager.default.createDirectory(
                at: URL.toolStorageDirectory,
                withIntermediateDirectories: true
            )

            // Write base64String to text file
            try Data(storage.base64String.utf8).write(to: stringURL)

            // Write meta to new JSON
            let meta = Base64ImageMeta(imageData: storage.imageData, outputFormat: storage.outputFormat)
            let metaData = try JSONEncoder().encode(meta)
            try metaData.write(to: URL.toolStorage("base64ImageMeta"))
        } catch {}
    }
}
