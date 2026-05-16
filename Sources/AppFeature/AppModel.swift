import Observation
import SharedModels
import JsonPrettyFeature
import Base64Feature
import AsciiToHexFeature
import CssBeautifyFeature
import BackslashEscapeFeature
import HashGeneratorFeature
import LineSortDedupeFeature
import HtmlBeautifyFeature
import JsBeautifyFeature
import SvgToCssFeature
import PrefixSuffixFeature
import NumberBaseConverterFeature
import TextCaseConverterFeature
import YamlToJsonFeature
import JsonToYamlFeature
import UrlEncodeFeature
import JwtDebuggerFeature
import UrlParserFeature
import HexToAsciiFeature
import XmlFormatFeature
import UuidUlidFeature
import RandomStringGeneratorFeature
import HtmlPreviewFeature
import ColorConverterFeature
import HtmlToMarkdownFeature
import UrlToMarkdownFeature
import HtmlToSwiftFeature
import SwiftPrettyFeature
import Base64ImageFeature
import UnixTimeFeature
import UUIDGeneratorFeature
import CertificateDecoderFeature
import QrCodeToolFeature
import RegExpTesterFeature
import RegexMatchesFeature
import NameGeneratorFeature
import StringDiffFeature
import FileContentSearchFeature
import StringInspectorFeature

    @MainActor
    @Observable
    public final class AppModel {
    public var destination: AppDestination = .none
    #if os(macOS)
    public var isQuickActionBarVisible: Bool = false
    #endif

    public var currentTool: Tool? {
        get {
        switch destination {
        case .htmlToSwift:
            return .htmlToSwift
        case .jwtDebugger:
            return .jwtDebugger
        case .colorConverter:
            return .colorConverter
        case .base64:
            return .base64
        case .base64Image:
            return .base64Image
        case .backslashEscape:
            return .backslashEscape
        case .textCaseConverter:
            return .textCaseConverter
        case .prefixSuffix:
            return .prefixSuffix
        case .urlEncode:
            return .urlEncode
        case .urlParser:
            return .urlParser
        case .numberBaseConverter:
            return .numberBaseConverter
        case .asciiToHex:
            return .asciiToHex
        case .hexToAscii:
            return .hexToAscii
        case .cssBeautify:
            return .cssBeautify
        case .htmlBeautify:
            return .htmlBeautify
        case .hashGenerator:
            return .hashGenerator
        case .lineSortDedupe:
            return .lineSortDedupe
        case .svgToCss:
            return .svgToCss
        case .htmlPreview:
            return .htmlPreview
        case .certificateDecoder:
            return .certificateDecoder
        case .qrCodeTool:
            return .qrCodeTool
        case .yamlToJson:
            return .yamlToJson
        case .jsonToYaml:
            return .jsonToYaml
        case .jsBeautify:
            return .jsBeautify
        case .xmlFormat:
            return .xmlFormat
        case .uuidUlid:
            return .uuidUlid
        case .regexMatches:
            return .regexMatches
        case .stringDiff:
            return .stringDiff
        case .regExpTester:
            return .regExpTester
        case .nameGenerator:
            return .nameGenerator
        case .randomStringGenerator:
            return .randomStringGenerator
        case .uuidGenerator:
            return .uuidGenerator
        case .stringInspector:
            return .stringInspector
        case .htmlToMarkdown:
            return .htmlToMarkdown
        #if os(macOS)
        case .fileContentSearch:
            return .fileContentSearch
        #endif
        case .urlToMarkdown:
            return .urlToMarkdown
        case .jsonPretty:
            return .jsonPretty
        case .swiftPrettyLockwood:
            return .swiftPrettyLockwood
        case .unixTime:
            return .unixTime
        case .none:
            return nil
        }
        }
        set {
            guard let tool = newValue else {
                destination = .none
                return
            }
            handleNavigation(tool: tool)
        }
    }

    public init() {}

    public func setCurrentTool(_ tool: Tool?) {
        guard let tool else { return }
        destination = destinationForTool(tool)
    }

    public func handleNavigation(tool: Tool) {
        destination = destinationForTool(tool)
    }

    public func sendOutputToOtherTool(_ outputText: String, _ tool: Tool) {
        switch destination {
        case .jsonPretty(let model):
            model.inputText = outputText
        case .asciiToHex(let model):
            model.inputText = outputText
        case .hexToAscii(let model):
            model.inputText = outputText
        case .colorConverter(let model):
            model.inputText = outputText
        case .textCaseConverter(let model):
            model.inputText = outputText
        case .prefixSuffix(let model):
            model.inputText = outputText
        case .numberBaseConverter(let model):
            model.inputText = outputText
        case .base64(let model):
            model.inputText = outputText
        case .base64Image(let model):
            model.base64String = outputText
            model.setBase64String(outputText)
        #if os(macOS)
        case .fileContentSearch:
        #endif
        case .htmlToSwift(let model):
            model.inputText = outputText
        case .backslashEscape(let model):
            model.inputText = outputText
        case .svgToCss(let model):
            model.inputText = outputText
        case .htmlPreview(let model):
            model.inputText = outputText
        case .urlEncode(let model):
            model.inputText = outputText
        case .urlParser(let model):
            model.setInputTextFromOtherTool(outputText)
        case .cssBeautify(let model):
            model.inputText = outputText
        case .htmlBeautify(let model):
            model.inputText = outputText
        case .hashGenerator(let model):
            model.inputText = outputText
        case .lineSortDedupe(let model):
            model.inputText = outputText
        case .jsBeautify(let model):
            model.inputText = outputText
        case .yamlToJson(let model):
            model.inputText = outputText
        case .jsonToYaml(let model):
            model.inputText = outputText
        case .xmlFormat(let model):
            model.inputText = outputText
        case .uuidUlid(let model):
            model.inputText = outputText
        case .regexMatches(let model):
            model.inputText = outputText
        case .regExpTester(let model):
            model.inputText = outputText
        case .stringDiff(let model):
            model.setOldText(outputText)
        case .nameGenerator(let model):
            model.outputText = outputText
        case .certificateDecoder(let model):
            model.inputText = outputText
        case .qrCodeTool(let model):
            model.inputText = outputText
        case .randomStringGenerator:
            break
        case .htmlToMarkdown(let model):
            model.inputText = outputText
        case .urlToMarkdown(let model):
            model.inputText = outputText
        case .swiftPrettyLockwood(let model):
            model.inputText = outputText
        case .unixTime(let model):
            model.inputText = outputText
        case .jwtDebugger(let model):
            model.inputText = outputText
        case .uuidGenerator:
            break
        case .stringInspector(let model):
            model.setInputText(outputText)
        case .none:
            break
        }
    }

    private func destinationForTool(_ tool: Tool) -> AppDestination {
        switch tool {
        case .base64: return .base64(Base64Model())
        case .base64Image: return .base64Image(Base64ImageModel())
        case .urlEncode: return .urlEncode(UrlEncodeModel())
        case .urlParser: return .urlParser(UrlParserModel())
        case .asciiToHex: return .asciiToHex(AsciiToHexModel())
        case .hexToAscii: return .hexToAscii(HexToAsciiModel())
        case .colorConverter: return .colorConverter(ColorConverterModel())
        case .cssBeautify: return .cssBeautify(CssBeautifyModel())
        case .htmlBeautify: return .htmlBeautify(HtmlBeautifyModel())
        case .hashGenerator: return .hashGenerator(HashGeneratorModel())
        case .lineSortDedupe: return .lineSortDedupe(LineSortDedupeModel())
        case .svgToCss: return .svgToCss(SvgToCssModel())
        case .backslashEscape: return .backslashEscape(BackslashEscapeModel())
        case .htmlPreview: return .htmlPreview(HtmlPreviewModel())
        case .xmlFormat: return .xmlFormat(XmlFormatModel())
        case .yamlToJson: return .yamlToJson(YamlToJsonModel())
        case .jsonToYaml: return .jsonToYaml(JsonToYamlModel())
        case .jsBeautify: return .jsBeautify(JsBeautifyModel())
        case .htmlToSwift: return .htmlToSwift(HtmlToSwiftModel())
        case .uuidUlid: return .uuidUlid(UuidUlidModel())
        case .regexMatches: return .regexMatches(RegexMatchesModel())
        case .stringDiff: return .stringDiff(StringDiffModel())
        case .regExpTester: return .regExpTester(RegExpTesterModel())
        case .nameGenerator: return .nameGenerator(NameGeneratorModel())
        case .randomStringGenerator: return .randomStringGenerator(RandomStringGeneratorModel())
        case .uuidGenerator: return .uuidGenerator(UUIDGeneratorModel())
        case .stringInspector: return .stringInspector(StringInspectorModel())
        case .htmlToMarkdown: return .htmlToMarkdown(HtmlToMarkdownModel())
        case .urlToMarkdown: return .urlToMarkdown(UrlToMarkdownModel())
        case .jsonPretty: return .jsonPretty(JsonPrettyModel())
        case .swiftPrettyLockwood: return .swiftPrettyLockwood(SwiftPrettyModel())
        case .jwtDebugger: return .jwtDebugger(JwtDebuggerModel())
        case .unixTime: return .unixTime(UnixTimeModel())
        case .textCaseConverter: return .textCaseConverter(TextCaseConverterModel())
        case .prefixSuffix: return .prefixSuffix(PrefixSuffixModel())
        case .numberBaseConverter: return .numberBaseConverter(NumberBaseConverterModel())
        case .certificateDecoder: return .certificateDecoder(CertificateDecoderModel())
        case .qrCodeTool: return .qrCodeTool(QrCodeToolModel())
        case .fileContentSearch:
            #if os(macOS)
            return .fileContentSearch(FileContentSearchModel())
            #else
            return .none
            #endif
        }
    }
}

public enum AppDestination: Equatable {
    case none
    case base64(Base64Model)
    case base64Image(Base64ImageModel)
    case urlEncode(UrlEncodeModel)
    case urlParser(UrlParserModel)
    case asciiToHex(AsciiToHexModel)
    case cssBeautify(CssBeautifyModel)
    case htmlBeautify(HtmlBeautifyModel)
    case hashGenerator(HashGeneratorModel)
    case hexToAscii(HexToAsciiModel)
    case backslashEscape(BackslashEscapeModel)
    case lineSortDedupe(LineSortDedupeModel)
    case svgToCss(SvgToCssModel)
    case htmlPreview(HtmlPreviewModel)
    case colorConverter(ColorConverterModel)
    case regexMatches(RegexMatchesModel)
    case stringInspector(StringInspectorModel)
    case nameGenerator(NameGeneratorModel)
    case prefixSuffix(PrefixSuffixModel)
    case numberBaseConverter(NumberBaseConverterModel)
    case textCaseConverter(TextCaseConverterModel)
    case yamlToJson(YamlToJsonModel)
    case jsonToYaml(JsonToYamlModel)
    case jsBeautify(JsBeautifyModel)
    case xmlFormat(XmlFormatModel)
    case uuidUlid(UuidUlidModel)
    case stringDiff(StringDiffModel)
    case randomStringGenerator(RandomStringGeneratorModel)
    case regExpTester(RegExpTesterModel)
    case certificateDecoder(CertificateDecoderModel)
    case qrCodeTool(QrCodeToolModel)
    case jsonPretty(JsonPrettyModel)
    case htmlToMarkdown(HtmlToMarkdownModel)
    case urlToMarkdown(UrlToMarkdownModel)
    case htmlToSwift(HtmlToSwiftModel)
    case swiftPrettyLockwood(SwiftPrettyModel)
    case jwtDebugger(JwtDebuggerModel)
    case unixTime(UnixTimeModel)
    case uuidGenerator(UUIDGeneratorModel)
    #if os(macOS)
    case fileContentSearch(FileContentSearchModel)
    #endif
}
