import Foundation
import Sharing

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
    public static var stringDiffIO: Self { .fileStorage(.toolStorage("stringDiff")) }
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

#if DEBUG
public enum ToolDebugSamples {
    public static func resetAllSamples() throws {
        try FileManager.default.createDirectory(
            at: URL.toolStorageDirectory,
            withIntermediateDirectories: true
        )

        for sample in singleOutputSamples {
            try write(sample.input, tool: sample.tool, field: "input")
            try write("", tool: sample.tool, field: "output")
        }

        try write(regexMatchesInput, tool: "regexMatches", field: "input")
        try write("", tool: "regexMatches", field: "output")
        try write("", tool: "regexMatches", field: "outputSecond")

        try write(stringDiffOldText, tool: "stringDiff", field: "input")
        try write(stringDiffNewText, tool: "stringDiff", field: "output")

        try write(base64ImageSample, to: URL.plainTextStorage("base64Image", "string"))
        let base64ImageMeta = Base64ImageMeta(imageData: nil, outputFormat: .dataURL)
        try JSONEncoder().encode(base64ImageMeta).write(to: URL.toolStorage("base64ImageMeta"))

        UserDefaults.standard.set(#"\b[\w.%+-]+@[\w.-]+\.[A-Za-z]{2,}\b"#, forKey: "RegexMatches_regexPattern")
        UserDefaults.standard.set(#"\b[\w.%+-]+@[\w.-]+\.[A-Za-z]{2,}\b"#, forKey: "RegExpTester_pattern")
        UserDefaults.standard.set("[email]", forKey: "RegExpTester_replacement")
    }

    private static let singleOutputSamples: [(tool: String, input: String)] = [
        ("htmlToSwift", """
        <article class="card">
          <h1>DevBliss</h1>
          <p>Convert HTML into SwiftUI views.</p>
          <a href="https://example.com">Read more</a>
        </article>
        """),
        ("htmlToMarkdown", """
        <h1>Release Notes</h1>
        <p>DevBliss now includes <strong>sample inputs</strong>.</p>
        <ul><li>Open a tool</li><li>Press convert</li></ul>
        """),
        ("urlToMarkdown", "https://example.com/articles/devbliss-samples"),
        ("textCaseConverter", "sample HTTP response parser"),
        ("prefixSuffix", """
        alpha
        beta
        gamma
        """),
        ("jsonPretty", #"{"app":"DevBliss","features":["format","convert","inspect"],"debug":true}"#),
        ("htmlBeautify", #"<main><h1>DevBliss</h1><p>Beautify compact HTML.</p></main>"#),
        ("cssBeautify", #"body{font:16px system-ui;color:#222}.card{padding:16px;border:1px solid #ddd}"#),
        ("jsBeautify", #"const tools=["json","base64","regex"];tools.forEach((tool)=>console.log(tool));"#),
        ("swiftPretty", #"struct User{let id:UUID;let name:String;func greeting()->String{"Hello, \(name)"}}"#),
        ("lineSortDedupe", """
        beta
        alpha
        gamma
        alpha
        beta
        """),
        ("asciiToHex", "DevBliss"),
        ("hexToAscii", "44 65 76 42 6c 69 73 73"),
        ("colorConverter", "#2F80ED"),
        ("svgToCss", """
        <svg width="24" height="24" viewBox="0 0 24 24">
          <path fill="#2F80ED" d="M12 2l9 5v10l-9 5-9-5V7z"/>
        </svg>
        """),
        ("backslashEscape", "Line 1\n\"Quoted\" path: C:\\DevBliss\\Samples"),
        ("xmlFormat", #"<catalog><tool id="json"><name>JSON Formatter</name></tool></catalog>"#),
        ("randomStringGenerator", "debug sample"),
        ("hashGenerator", "Hash this DevBliss sample"),
        ("stringInspector", "DevBliss 👩‍💻\nTabs\tSpaces  Unicode"),
        ("numberBaseConverter", "255"),
        ("certificateDecoder", sampleCertificate),
        ("qrCodeTool", "https://devbliss.example/tools?debug=true"),
        ("jsonToYaml", #"{"name":"DevBliss","tools":[{"id":"json","active":true},{"id":"base64","active":true}]}"#),
        ("yamlToJson", """
        name: DevBliss
        tools:
          - id: yaml
            active: true
          - id: json
            active: true
        """),
        ("uuidUlid", "550e8400-e29b-41d4-a716-446655440000"),
        ("urlParser", "https://docs.example.com:8443/tools/json?format=pretty&debug=true#samples"),
        ("regExpTester", """
        Regex samples:
        user@example.com
        support@devbliss.app
        invalid-email
        """),
        ("htmlPreview", """
        <!doctype html>
        <html>
          <body><h1>Preview</h1><button>Sample Button</button></body>
        </html>
        """),
        ("base64", "DevBliss sample text"),
        ("unixTime", "1704067200"),
        ("urlEncode", "https://example.com/search?q=dev bliss&sort=latest"),
        ("jwtDebugger", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZXZibGlzcyIsIm5hbWUiOiJEZWJ1ZyBTYW1wbGUiLCJpYXQiOjE3MDQwNjcyMDB9.signature")
    ]

    private static let regexMatchesInput = """
    Pattern: \\b[\\w.%+-]+@[\\w.-]+\\.[A-Za-z]{2,}\\b

    Contact alex@example.com, sam@devbliss.app, or invalid-email for details.
    """

    private static let stringDiffOldText = """
    DevBliss formats JSON.
    DevBliss converts Base64.
    DevBliss tests regular expressions.
    """

    private static let stringDiffNewText = """
    DevBliss formats JSON and YAML.
    DevBliss converts Base64.
    DevBliss previews HTML.
    """

    private static let base64ImageSample = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lbQCJwAAAABJRU5ErkJggg=="

    private static let sampleCertificate = """
    -----BEGIN CERTIFICATE-----
    MIIDITCCAgmgAwIBAgIUf04wFuy2ZBTIrsm5dhQG8bNuXkMwDQYJKoZIhvcNAQEL
    BQAwIDEeMBwGA1UEAwwVRGV2Qmxpc3MgRGVidWcgU2FtcGxlMB4XDTI2MDUxNzEz
    MTQxOVoXDTI3MDUxNzEzMTQxOVowIDEeMBwGA1UEAwwVRGV2Qmxpc3MgRGVidWcg
    U2FtcGxlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyzAprzJO4syT
    K2EwdvmNCO6d9OFHSqaJATyytiX7+EAg62tcWZG2S51qBBBSOcc3UCytiGOtIPm1
    +fGyh8O3AthJ2CyEawBAv5V8RCZwjoXkvSx7FxjZgY6lWeuAKkmoSfHz3PPBY9yY
    Knqtdy44e0Ea9oJxakxLTGQK5TnQIv0OUWPgLo9BWQiSnhQCVdvGinVN79Itb9At
    82nerzc8qUhOwoaK+Dq9TFKpO5WEprq/yfCtO9+1929LHsg1jsBPMsqEoPXGoXB8
    ME2PvkfqW908QSpuUWWMNlSE+BWC3cgWA+rbbMdpisJtSwjfj5xCPx4lcnj+6HLk
    yBrijokgzQIDAQABo1MwUTAdBgNVHQ4EFgQUNoYFZqtnbs85T9h5dKbCF5PTrmcw
    HwYDVR0jBBgwFoAUNoYFZqtnbs85T9h5dKbCF5PTrmcwDwYDVR0TAQH/BAUwAwEB
    /zANBgkqhkiG9w0BAQsFAAOCAQEAZEYJW0hmYIfQK98MYyRclIifOF1xEJA8Uuxu
    CHoh8IFL4OgAbemJKYJmB0gTGGWgC1kOsSA2OiqTL9BncYALkPku/D3KEvyA+VKt
    zefFdyED9qVDHLahvEBD+6cBRH5cLpt8lOdDARYBq1LJiLYVrOa55e6J8zEwWu22
    zkzsheIQIMLhy7np/V3YBZqgUbtFxnKAEEjI5v1c3I2no60slxV6AWsE/wCvsmg/
    Rvf1O/nBFrEsJXzi1nPIqNXCDojzHksGCSbTZCIvg8tMb9A/udTRD5LA7GNj0Y+I
    BQyliUaICFveVeJJnH7vhZMSB+II+Up9qDsuK15W85O0m8J4rw==
    -----END CERTIFICATE-----
    """

    private static func write(_ value: String, tool: String, field: String) throws {
        try write(value, to: URL.plainTextStorage(tool, field))
    }

    private static func write(_ value: String, to url: URL) throws {
        try Data(value.utf8).write(to: url, options: .atomic)
    }
}
#endif
