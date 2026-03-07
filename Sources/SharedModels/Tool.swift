import Foundation

public enum Tool: Int, CaseIterable, Identifiable {
    case htmlToSwift
    case htmlToMarkdown
    case urlToMarkdown
    case textCaseConverter
    case prefixSuffix
    case regexMatches
    case jsonPretty
    case htmlBeautify
    case cssBeautify
    case jsBeautify
    case swiftPrettyLockwood
    case fileContentSearch
    case nameGenerator
    case uuidGenerator
    case lineSortDedupe
    case asciiToHex
    case hexToAscii
    case colorConverter
    case svgToCss
    case backslashEscape
    case xmlFormat
    case randomStringGenerator
    case hashGenerator
    case stringInspector
    case numberBaseConverter
    case certificateDecoder
    case qrCodeTool
    case jsonToYaml
    case yamlToJson
    case uuidUlid
    case urlParser
    case regExpTester
    case htmlPreview
    case base64
    case base64Image
    case unixTime
    case urlEncode
    case jwtDebugger
    case stringDiff

    public var id: Self { self }

    public var name: String {
        switch self {
        case .htmlToSwift:
            return NSLocalizedString("HTML to Swift", bundle: Bundle.module, comment: "")
        case .htmlToMarkdown:
            return NSLocalizedString("HTML to Markdown", bundle: Bundle.module, comment: "")
        case .urlToMarkdown:
            return NSLocalizedString("URL to Markdown", bundle: Bundle.module, comment: "")
        case .jsonPretty:
            return NSLocalizedString("JSON Formatter", bundle: Bundle.module, comment: "")
        case .htmlBeautify:
            return NSLocalizedString("HTML Beautify", bundle: Bundle.module, comment: "")
        case .cssBeautify:
            return NSLocalizedString("CSS Beautify", bundle: Bundle.module, comment: "")
        case .jsBeautify:
            return NSLocalizedString("JS Beautify", bundle: Bundle.module, comment: "")
        case .textCaseConverter:
            return NSLocalizedString("Text Case Converter", bundle: Bundle.module, comment: "")
        case .uuidGenerator:
            return NSLocalizedString("UUID Generator", bundle: Bundle.module, comment: "")
        case .prefixSuffix:
            return NSLocalizedString("Prefix Suffix", bundle: Bundle.module, comment: "")
        case .regexMatches:
            return NSLocalizedString("Regex Matches", bundle: Bundle.module, comment: "")
        case .swiftPrettyLockwood:
            return NSLocalizedString("Swift Pretty", bundle: Bundle.module, comment: "")
        case .fileContentSearch:
            return NSLocalizedString("File Content Search", bundle: Bundle.module, comment: "")
        case .nameGenerator:
            return NSLocalizedString("Name Generator", bundle: Bundle.module, comment: "")
        case .lineSortDedupe:
            return NSLocalizedString("Line Sort/Dedupe", bundle: Bundle.module, comment: "")
        case .asciiToHex:
            return NSLocalizedString("ASCII to Hex", bundle: Bundle.module, comment: "")
        case .hexToAscii:
            return NSLocalizedString("Hex to ASCII", bundle: Bundle.module, comment: "")
        case .colorConverter:
            return NSLocalizedString("Color Converter", bundle: Bundle.module, comment: "")
        case .svgToCss:
            return NSLocalizedString("SVG to CSS", bundle: Bundle.module, comment: "")
        case .backslashEscape:
            return NSLocalizedString("Backslash Escape", bundle: Bundle.module, comment: "")
        case .xmlFormat:
            return NSLocalizedString("XML Formatter", bundle: Bundle.module, comment: "")
        case .randomStringGenerator:
            return NSLocalizedString("Random String", bundle: Bundle.module, comment: "")
        case .hashGenerator:
            return NSLocalizedString("Hash Generator", bundle: Bundle.module, comment: "")
        case .stringInspector:
            return NSLocalizedString("String Inspector", bundle: Bundle.module, comment: "")
        case .numberBaseConverter:
            return NSLocalizedString("Number Base Converter", bundle: Bundle.module, comment: "")
        case .certificateDecoder:
            return NSLocalizedString("Certificate Decoder", bundle: Bundle.module, comment: "")
        case .qrCodeTool:
            return NSLocalizedString("QR Code", bundle: Bundle.module, comment: "")
        case .jsonToYaml:
            return NSLocalizedString("JSON to YAML", bundle: Bundle.module, comment: "")
        case .yamlToJson:
            return NSLocalizedString("YAML to JSON", bundle: Bundle.module, comment: "")
        case .uuidUlid:
            return NSLocalizedString("UUID/ULID", bundle: Bundle.module, comment: "")
        case .urlParser:
            return NSLocalizedString("URL Parser", bundle: Bundle.module, comment: "")
        case .regExpTester:
            return NSLocalizedString("RegExp Tester", bundle: Bundle.module, comment: "")
        case .htmlPreview:
            return NSLocalizedString("HTML Preview", bundle: Bundle.module, comment: "")
        case .base64:
            return NSLocalizedString("Base64", bundle: Bundle.module, comment: "")
        case .base64Image:
            return NSLocalizedString("Base64 Image", bundle: Bundle.module, comment: "")
        case .unixTime:
            return NSLocalizedString("Unix Time", bundle: Bundle.module, comment: "")
        case .urlEncode:
            return NSLocalizedString("URL Encode", bundle: Bundle.module, comment: "")
        case .jwtDebugger:
            return NSLocalizedString("JWT Debugger", bundle: Bundle.module, comment: "")
        case .stringDiff:
            return NSLocalizedString("String Diff", bundle: Bundle.module, comment: "")
        }
    }

    public var isInputtable: Bool {
        switch self {
        case .htmlToSwift:
            return true
        case .htmlToMarkdown:
            return true
        case .urlToMarkdown:
            return false
        case .jsonPretty:
            return true
        case .htmlBeautify:
            return true
        case .cssBeautify:
            return true
        case .jsBeautify:
            return true
        case .textCaseConverter:
            return true
        case .uuidGenerator:
            return false
        case .prefixSuffix:
            return true
        case .regexMatches:
            return true
        case .swiftPrettyLockwood:
            return true
        case .fileContentSearch:
            return false
        case .nameGenerator:
            return false
        case .lineSortDedupe:
            return true
        case .asciiToHex:
            return true
        case .hexToAscii:
            return true
        case .colorConverter:
            return true
        case .svgToCss:
            return true
        case .backslashEscape:
            return true
        case .xmlFormat:
            return true
        case .randomStringGenerator:
            return false
        case .hashGenerator:
            return true
        case .stringInspector:
            return true
        case .numberBaseConverter:
            return true
        case .certificateDecoder:
            return true
        case .qrCodeTool:
            return true
        case .jsonToYaml:
            return true
        case .yamlToJson:
            return true
        case .uuidUlid:
            return true
        case .urlParser:
            return true
        case .regExpTester:
            return true
        case .htmlPreview:
            return true
        case .base64:
            return true
        case .base64Image:
            return true
        case .unixTime:
            return true
        case .urlEncode:
            return true
        case .jwtDebugger:
            return true
        case .stringDiff:
            return true
        }
    }

    public var isActive: Bool {
        switch self {
        case .uuidGenerator:
            return false
        case .fileContentSearch:
            #if os(macOS)
                return true
            #else
                return false
            #endif
        default:
            return true
        }
    }

}

public enum SettingsKey {
    public enum PrefixSuffix {
        public static var prefixReplace = "PrefixSuffix_prefixReplace"
        public static var prefixReplaceWith = "PrefixSuffix_prefixReplaceWith"
        public static var prefixAdd = "PrefixSuffix_prefixAdd"
        public static var suffixReplace = "PrefixSuffix_suffixReplace"
        public static var suffixReplaceWith = "PrefixSuffix_suffixReplaceWith"
        public static var suffixAdd = "PrefixSuffix_suffixAdd"
        public static var trimWhiteSpace = "PrefixSuffix_trimWhiteSpace"
        public static var splitViewFraction = "PrefixSuffix_splitViewFraction"
        public static var splitViewLayout = "PrefixSuffix_splitViewLayout"
    }

    public enum JsonPretty {
        public static var splitViewFraction = "JsonPretty_splitViewFraction"
        public static var splitViewLayout = "JsonPretty_splitViewLayout"
    }

    public enum HtmlBeautify {
        public static var splitViewFraction = "HtmlBeautify_splitViewFraction"
        public static var splitViewLayout = "HtmlBeautify_splitViewLayout"
    }

    public enum CssBeautify {
        public static var splitViewFraction = "CssBeautify_splitViewFraction"
        public static var splitViewLayout = "CssBeautify_splitViewLayout"
    }

    public enum JsBeautify {
        public static var splitViewFraction = "JsBeautify_splitViewFraction"
        public static var splitViewLayout = "JsBeautify_splitViewLayout"
    }

    public enum HtmlToSwift {
        public static var dsl = "HtmlToSwift_dsl"
        public static var component = "HtmlToSwift_component"
        public static var splitViewFraction = "HtmlToSwift_splitViewFraction"
        public static var splitViewLayout = "HtmlToSwift_splitViewLayout"
    }

    public enum TextCaseConverter {
        public static var sourceCase = "TextCaseConverter_sourceCase"
        public static var targetCase = "TextCaseConverter_targetCase"
        public static var textSeperator = "TextCaseConverter_textSeperator"

        public static var splitViewFraction = "TextCaseConverter_splitViewFraction"
        public static var splitViewLayout = "TextCaseConverter_splitViewLayout"
    }

    public enum SwiftPretty {
        public static var lockwoodConfig = "SwiftPretty_lockwoodConfig"
        public static var splitViewFraction = "SwiftPretty_splitViewFraction"
        public static var splitViewLayout = "SwiftPretty_splitViewLayout"
    }

    public enum HtmlToMarkdown {
        public static var splitViewFraction = "HtmlToMarkdown_splitViewFraction"
        public static var splitViewLayout = "HtmlToMarkdown_splitViewLayout"
    }

    public enum Base64 {
        public static var mode = "Base64_mode"
        public static var autoDetect = "Base64_autoDetect"
        public static var autoRemoveDataURLPrefix = "Base64_autoRemoveDataURLPrefix"
        public static var autoRemoveNullBytes = "Base64_autoRemoveNullBytes"
        public static var splitViewFraction = "Base64_splitViewFraction"
        public static var splitViewLayout = "Base64_splitViewLayout"
    }

    public enum UnixTime {
        public static var splitViewFraction = "UnixTime_splitViewFraction"
        public static var splitViewLayout = "UnixTime_splitViewLayout"
    }

    public enum Base64Image {
        public static var splitViewFraction = "Base64Image_splitViewFraction"
        public static var splitViewLayout = "Base64Image_splitViewLayout"
    }

    public enum LineSortDedupe {
        public static var splitViewFraction = "LineSortDedupe_splitViewFraction"
        public static var splitViewLayout = "LineSortDedupe_splitViewLayout"
    }

    public enum AsciiToHex {
        public static var splitViewFraction = "AsciiToHex_splitViewFraction"
        public static var splitViewLayout = "AsciiToHex_splitViewLayout"
    }

    public enum HexToAscii {
        public static var splitViewFraction = "HexToAscii_splitViewFraction"
        public static var splitViewLayout = "HexToAscii_splitViewLayout"
    }

    public enum ColorConverter {
        public static var splitViewFraction = "ColorConverter_splitViewFraction"
        public static var splitViewLayout = "ColorConverter_splitViewLayout"
    }

    public enum SvgToCss {
        public static var splitViewFraction = "SvgToCss_splitViewFraction"
        public static var splitViewLayout = "SvgToCss_splitViewLayout"
    }

    public enum BackslashEscape {
        public static var splitViewFraction = "BackslashEscape_splitViewFraction"
        public static var splitViewLayout = "BackslashEscape_splitViewLayout"
    }

    public enum XmlFormat {
        public static var splitViewFraction = "XmlFormat_splitViewFraction"
        public static var splitViewLayout = "XmlFormat_splitViewLayout"
    }

    public enum CertificateDecoder {
        public static var splitViewFraction = "CertificateDecoder_splitViewFraction"
        public static var splitViewLayout = "CertificateDecoder_splitViewLayout"
    }

    public enum QrCodeTool {
        public static var splitViewFraction = "QrCodeTool_splitViewFraction"
        public static var splitViewLayout = "QrCodeTool_splitViewLayout"
    }

    public enum JsonToYaml {
        public static var splitViewFraction = "JsonToYaml_splitViewFraction"
        public static var splitViewLayout = "JsonToYaml_splitViewLayout"
    }

    public enum YamlToJson {
        public static var splitViewFraction = "YamlToJson_splitViewFraction"
        public static var splitViewLayout = "YamlToJson_splitViewLayout"
    }

    public enum UuidUlid {
        public static var splitViewFraction = "UuidUlid_splitViewFraction"
        public static var splitViewLayout = "UuidUlid_splitViewLayout"
    }

    public enum HashGenerator {
        public static var splitViewFraction = "HashGenerator_splitViewFraction"
        public static var splitViewLayout = "HashGenerator_splitViewLayout"
    }

    public enum NumberBaseConverter {
        public static var splitViewFraction = "NumberBaseConverter_splitViewFraction"
        public static var splitViewLayout = "NumberBaseConverter_splitViewLayout"
    }

    public enum RegExpTester {
        public static var splitViewFraction = "RegExpTester_splitViewFraction"
        public static var splitViewLayout = "RegExpTester_splitViewLayout"
    }

    public enum HtmlPreview {
        public static var splitViewFraction = "HtmlPreview_splitViewFraction"
        public static var splitViewLayout = "HtmlPreview_splitViewLayout"
    }

    public enum StringDiff {
        public static var splitViewFraction = "StringDiff_splitViewFraction"
        public static var splitViewLayout = "StringDiff_splitViewLayout"
    }
}
