import AsciiToHexFeature
import BackslashEscapeFeature
import Base64Feature
import Base64ImageFeature
import CertificateDecoderFeature
import ColorConverterFeature
import ComposableArchitecture
import DSFQuickActionBar
import CssBeautifyFeature
import FileContentSearchFeature
import HashGeneratorFeature
import HexToAsciiFeature
import HtmlBeautifyFeature
import HtmlPreviewFeature
import HtmlToMarkdownFeature
import HtmlToSwiftFeature
import JsBeautifyFeature
import JsonPrettyFeature
import JsonToYamlFeature
import JwtDebuggerFeature
import LineSortDedupeFeature
import NameGeneratorFeature
import NumberBaseConverterFeature
import PrefixSuffixFeature
import QrCodeToolFeature
import RandomStringGeneratorFeature
import RegExpTesterFeature
import RegexMatchesFeature
import SharedModels
import StringInspectorFeature
import SvgToCssFeature
import SwiftPrettyFeature
import SwiftUI
import TextCaseConverterFeature
import UnixTimeFeature
import UrlEncodeFeature
import UrlParserFeature
import UrlToMarkdownFeature
import UuidUlidFeature
import XmlFormatFeature
import YamlToJsonFeature

// MARK: - Destination Reducer Enum

@Reducer
public enum Destination {
    case htmlToSwift(HtmlToSwiftReducer)
    case htmlToMarkdown(HtmlToMarkdownReducer)
    case urlToMarkdown(UrlToMarkdownReducer)
    case jsonPretty(JsonPrettyReducer)
    case htmlBeautify(HtmlBeautifyReducer)
    case cssBeautify(CssBeautifyReducer)
    case jsBeautify(JsBeautifyReducer)
    case textCaseConverter(TextCaseConverterReducer)
    case prefixSuffix(PrefixSuffixReducer)
    case lineSortDedupe(LineSortDedupeReducer)
    case asciiToHex(AsciiToHexReducer)
    case hexToAscii(HexToAsciiReducer)
    case colorConverter(ColorConverterReducer)
    case svgToCss(SvgToCssReducer)
    case backslashEscape(BackslashEscapeReducer)
    case xmlFormat(XmlFormatReducer)
    case regexMatches(RegexMatchesReducer)
    case regExpTester(RegExpTesterReducer)
    case swiftPrettyLockwood(SwiftPrettyReducer)
    case nameGenerator(NameGeneratorReducer)
    case randomStringGenerator(RandomStringGeneratorReducer)
    case hashGenerator(HashGeneratorReducer)
    case stringInspector(StringInspectorReducer)
    case numberBaseConverter(NumberBaseConverterReducer)
    case certificateDecoder(CertificateDecoderReducer)
    case qrCodeTool(QrCodeToolReducer)
    case jsonToYaml(JsonToYamlReducer)
    case yamlToJson(YamlToJsonReducer)
    case uuidUlid(UuidUlidReducer)
    case urlParser(UrlParserReducer)
    case htmlPreview(HtmlPreviewReducer)
    case base64(Base64Reducer)
    case base64Image(Base64ImageReducer)
    case unixTime(UnixTimeReducer)
    case urlEncode(UrlEncodeReducer)
    case jwtDebugger(JwtDebuggerReducer)
    #if os(macOS)
        case fileContentSearch(FileContentSearchReducer)
    #endif
}

// MARK: - App Reducer

@Reducer
public struct AppReducer {
    public init() {}

    @ObservableState
    public struct State {
        @Presents public var destination: Destination.State?
        public var isQuickActionBarVisible: Bool = false

        // Derive currentTool from destination instead of separate state
        public var currentTool: Tool? {
            switch destination {
            case .htmlToSwift: return .htmlToSwift
            case .htmlToMarkdown: return .htmlToMarkdown
            case .urlToMarkdown: return .urlToMarkdown
            case .jsonPretty: return .jsonPretty
            case .htmlBeautify: return .htmlBeautify
            case .cssBeautify: return .cssBeautify
            case .jsBeautify: return .jsBeautify
            case .textCaseConverter: return .textCaseConverter
            case .prefixSuffix: return .prefixSuffix
            case .lineSortDedupe: return .lineSortDedupe
            case .asciiToHex: return .asciiToHex
            case .hexToAscii: return .hexToAscii
            case .colorConverter: return .colorConverter
            case .svgToCss: return .svgToCss
            case .backslashEscape: return .backslashEscape
            case .xmlFormat: return .xmlFormat
            case .regexMatches: return .regexMatches
            case .regExpTester: return .regExpTester
            case .swiftPrettyLockwood: return .swiftPrettyLockwood
            case .nameGenerator: return .nameGenerator
            case .randomStringGenerator: return .randomStringGenerator
            case .hashGenerator: return .hashGenerator
            case .stringInspector: return .stringInspector
            case .numberBaseConverter: return .numberBaseConverter
            case .certificateDecoder: return .certificateDecoder
            case .qrCodeTool: return .qrCodeTool
            case .jsonToYaml: return .jsonToYaml
            case .yamlToJson: return .yamlToJson
            case .uuidUlid: return .uuidUlid
            case .urlParser: return .urlParser
            case .htmlPreview: return .htmlPreview
            case .base64: return .base64
            case .base64Image: return .base64Image
            case .unixTime: return .unixTime
            case .urlEncode: return .urlEncode
            case .jwtDebugger: return .jwtDebugger
            #if os(macOS)
                case .fileContentSearch: return .fileContentSearch
            #endif
            case .none: return nil
            }
        }

        public init(destination: Destination.State? = nil) {
            self.destination = destination
        }
    }

    public enum Action {
        case destination(PresentationAction<Destination.Action>)
        case navigationLinkTouched(Tool)
        case setCurrentTool(Tool?)
        case setQuickActionBarVisible(Bool)
    }

    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .destination(.presented(let destinationAction)):
                return handleDestinationAction(destinationAction, state: &state)

            case .navigationLinkTouched(let tool):
                handleNavigation(tool: tool, state: &state)
                return .none

            case .setCurrentTool(let tool):
                if let tool = tool {
                    handleNavigation(tool: tool, state: &state)
                }
                return .none

            case .setQuickActionBarVisible(let visible):
                state.isQuickActionBarVisible = visible
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Destination Action Handling

    private func handleDestinationAction(_ action: Destination.Action, state: inout State) -> Effect<Action> {
        switch action {
        // Standard tools with single output
        case .htmlToSwift(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .htmlToSwift(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .htmlToMarkdown(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .htmlToMarkdown(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .urlToMarkdown(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .urlToMarkdown(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .jsonPretty(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .jsonPretty(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .htmlBeautify(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .htmlBeautify(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .cssBeautify(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .cssBeautify(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .jsBeautify(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .jsBeautify(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .textCaseConverter(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .textCaseConverter(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .prefixSuffix(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .prefixSuffix(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .lineSortDedupe(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .lineSortDedupe(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .asciiToHex(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .asciiToHex(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .hexToAscii(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .hexToAscii(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .colorConverter(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .colorConverter(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .svgToCss(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .svgToCss(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .backslashEscape(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .backslashEscape(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .xmlFormat(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .xmlFormat(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .swiftPrettyLockwood(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .swiftPrettyLockwood(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        // RegexMatches has TWO outputs
        case .regexMatches(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .regexMatches(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .regexMatches(.inputOutput(.outputSecond(.outputControls(.otherToolSelected(let tool))))):
            if case .regexMatches(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputSecondText, otherTool: tool, state: &state)
            }

        case .base64(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .base64(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .hashGenerator(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .hashGenerator(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .numberBaseConverter(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .numberBaseConverter(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .certificateDecoder(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .certificateDecoder(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .qrCodeTool(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .qrCodeTool(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .jsonToYaml(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .jsonToYaml(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .yamlToJson(.inputOutput(.output(.outputControls(.otherToolSelected(let tool))))):
            if case .yamlToJson(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .uuidUlid(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .uuidUlid(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        // Generators (output-only tools)
        case .nameGenerator(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .nameGenerator(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .randomStringGenerator(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .randomStringGenerator(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case .regExpTester(.output(.outputControls(.otherToolSelected(let tool)))):
            if case .regExpTester(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        #if os(macOS)
            case .fileContentSearch(.output(.outputControls(.otherToolSelected(let tool)))):
                if case .fileContentSearch(let s) = state.destination {
                    handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
                }
        #endif

        default:
            break
        }
        return .none
    }

    // MARK: - Other Tool Navigation (Output -> Input Transfer)

    private func handleOtherTool(thisToolOutput: String?, otherTool: Tool, state: inout State) {
        let outputText = thisToolOutput ?? ""

        switch otherTool {
        case .htmlToSwift:
            state.destination = .htmlToSwift(HtmlToSwiftReducer.State())
            if case .htmlToSwift(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .htmlToMarkdown:
            state.destination = .htmlToMarkdown(HtmlToMarkdownReducer.State())
            if case .htmlToMarkdown(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .urlToMarkdown:
            state.destination = .urlToMarkdown(UrlToMarkdownReducer.State())
        case .jsonPretty:
            state.destination = .jsonPretty(JsonPrettyReducer.State())
            if case .jsonPretty(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .htmlBeautify:
            state.destination = .htmlBeautify(HtmlBeautifyReducer.State())
            if case .htmlBeautify(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .cssBeautify:
            state.destination = .cssBeautify(CssBeautifyReducer.State())
            if case .cssBeautify(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .jsBeautify:
            state.destination = .jsBeautify(JsBeautifyReducer.State())
            if case .jsBeautify(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .textCaseConverter:
            state.destination = .textCaseConverter(TextCaseConverterReducer.State())
            if case .textCaseConverter(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .prefixSuffix:
            state.destination = .prefixSuffix(PrefixSuffixReducer.State())
            if case .prefixSuffix(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .lineSortDedupe:
            state.destination = .lineSortDedupe(LineSortDedupeReducer.State())
            if case .lineSortDedupe(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .asciiToHex:
            state.destination = .asciiToHex(AsciiToHexReducer.State())
            if case .asciiToHex(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .hexToAscii:
            state.destination = .hexToAscii(HexToAsciiReducer.State())
            if case .hexToAscii(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .colorConverter:
            state.destination = .colorConverter(ColorConverterReducer.State())
            if case .colorConverter(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .svgToCss:
            state.destination = .svgToCss(SvgToCssReducer.State())
            if case .svgToCss(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .backslashEscape:
            state.destination = .backslashEscape(BackslashEscapeReducer.State())
            if case .backslashEscape(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .xmlFormat:
            state.destination = .xmlFormat(XmlFormatReducer.State())
            if case .xmlFormat(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .regexMatches:
            state.destination = .regexMatches(RegexMatchesReducer.State())
            if case .regexMatches(var s) = state.destination {
                s.$storedInput.withLock { $0 = outputText }
                // Must also update the display text since it's a separate NSMutableAttributedString copy
                _ = s.inputOutput.input.updateText(outputText)
                state.destination = .regexMatches(s)
            }
        case .swiftPrettyLockwood:
            state.destination = .swiftPrettyLockwood(SwiftPrettyReducer.State())
            if case .swiftPrettyLockwood(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .uuidGenerator:
            break  // Inactive tool
        case .fileContentSearch:
            #if os(macOS)
                state.destination = .fileContentSearch(FileContentSearchReducer.State())
            #endif
        case .nameGenerator:
            state.destination = .nameGenerator(NameGeneratorReducer.State())
        case .randomStringGenerator:
            state.destination = .randomStringGenerator(RandomStringGeneratorReducer.State())
        case .hashGenerator:
            state.destination = .hashGenerator(HashGeneratorReducer.State())
            if case .hashGenerator(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .stringInspector:
            state.destination = .stringInspector(StringInspectorReducer.State())
            if case .stringInspector(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .numberBaseConverter:
            state.destination = .numberBaseConverter(NumberBaseConverterReducer.State())
            if case .numberBaseConverter(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .certificateDecoder:
            state.destination = .certificateDecoder(CertificateDecoderReducer.State())
            if case .certificateDecoder(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .qrCodeTool:
            state.destination = .qrCodeTool(QrCodeToolReducer.State())
            if case .qrCodeTool(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .jsonToYaml:
            state.destination = .jsonToYaml(JsonToYamlReducer.State())
            if case .jsonToYaml(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .yamlToJson:
            state.destination = .yamlToJson(YamlToJsonReducer.State())
            if case .yamlToJson(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .uuidUlid:
            state.destination = .uuidUlid(UuidUlidReducer.State())
            if case .uuidUlid(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .urlParser:
            state.destination = .urlParser(UrlParserReducer.State())
            if case .urlParser(var s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
                s.input = outputText
                state.destination = .urlParser(s)
            }
        case .regExpTester:
            state.destination = .regExpTester(RegExpTesterReducer.State())
            if case .regExpTester(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .htmlPreview:
            state.destination = .htmlPreview(HtmlPreviewReducer.State())
            if case .htmlPreview(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .base64:
            state.destination = .base64(Base64Reducer.State())
            if case .base64(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .base64Image:
            state.destination = .base64Image(Base64ImageReducer.State())
            // Base64Image stores base64String in a different structure, pass it there
            if case .base64Image(var s) = state.destination {
                s.$base64StringStorage.withLock { $0 = outputText }
                s.base64String = outputText
                state.destination = .base64Image(s)
            }
        case .unixTime:
            state.destination = .unixTime(UnixTimeReducer.State())
            if case .unixTime(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .urlEncode:
            state.destination = .urlEncode(UrlEncodeReducer.State())
            if case .urlEncode(let s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
            }
        case .jwtDebugger:
            state.destination = .jwtDebugger(JwtDebuggerReducer.State())
            if case .jwtDebugger(var s) = state.destination {
                s.$inputText.withLock { $0 = outputText }
                _ = s.input.updateText(outputText)
                state.destination = .jwtDebugger(s)
            }
        }
    }

    // MARK: - Navigation Helpers

    private func handleNavigation(tool: Tool, state: inout State) {
        switch tool {
        case .htmlToSwift:
            state.destination = .htmlToSwift(HtmlToSwiftReducer.State())
        case .htmlToMarkdown:
            state.destination = .htmlToMarkdown(HtmlToMarkdownReducer.State())
        case .urlToMarkdown:
            state.destination = .urlToMarkdown(UrlToMarkdownReducer.State())
        case .jsonPretty:
            state.destination = .jsonPretty(JsonPrettyReducer.State())
        case .htmlBeautify:
            state.destination = .htmlBeautify(HtmlBeautifyReducer.State())
        case .cssBeautify:
            state.destination = .cssBeautify(CssBeautifyReducer.State())
        case .jsBeautify:
            state.destination = .jsBeautify(JsBeautifyReducer.State())
        case .textCaseConverter:
            state.destination = .textCaseConverter(TextCaseConverterReducer.State())
        case .prefixSuffix:
            state.destination = .prefixSuffix(PrefixSuffixReducer.State())
        case .lineSortDedupe:
            state.destination = .lineSortDedupe(LineSortDedupeReducer.State())
        case .asciiToHex:
            state.destination = .asciiToHex(AsciiToHexReducer.State())
        case .hexToAscii:
            state.destination = .hexToAscii(HexToAsciiReducer.State())
        case .colorConverter:
            state.destination = .colorConverter(ColorConverterReducer.State())
        case .svgToCss:
            state.destination = .svgToCss(SvgToCssReducer.State())
        case .backslashEscape:
            state.destination = .backslashEscape(BackslashEscapeReducer.State())
        case .xmlFormat:
            state.destination = .xmlFormat(XmlFormatReducer.State())
        case .regexMatches:
            state.destination = .regexMatches(RegexMatchesReducer.State())
        case .regExpTester:
            state.destination = .regExpTester(RegExpTesterReducer.State())
        case .swiftPrettyLockwood:
            state.destination = .swiftPrettyLockwood(SwiftPrettyReducer.State())
        case .nameGenerator:
            state.destination = .nameGenerator(NameGeneratorReducer.State())
        case .randomStringGenerator:
            state.destination = .randomStringGenerator(RandomStringGeneratorReducer.State())
        case .hashGenerator:
            state.destination = .hashGenerator(HashGeneratorReducer.State())
        case .stringInspector:
            state.destination = .stringInspector(StringInspectorReducer.State())
        case .numberBaseConverter:
            state.destination = .numberBaseConverter(NumberBaseConverterReducer.State())
        case .certificateDecoder:
            state.destination = .certificateDecoder(CertificateDecoderReducer.State())
        case .qrCodeTool:
            state.destination = .qrCodeTool(QrCodeToolReducer.State())
        case .jsonToYaml:
            state.destination = .jsonToYaml(JsonToYamlReducer.State())
        case .yamlToJson:
            state.destination = .yamlToJson(YamlToJsonReducer.State())
        case .uuidUlid:
            state.destination = .uuidUlid(UuidUlidReducer.State())
        case .urlParser:
            state.destination = .urlParser(UrlParserReducer.State())
        case .htmlPreview:
            state.destination = .htmlPreview(HtmlPreviewReducer.State())
        case .base64:
            state.destination = .base64(Base64Reducer.State())
        case .base64Image:
            state.destination = .base64Image(Base64ImageReducer.State())
        case .unixTime:
            state.destination = .unixTime(UnixTimeReducer.State())
        case .urlEncode:
            state.destination = .urlEncode(UrlEncodeReducer.State())
        case .jwtDebugger:
            state.destination = .jwtDebugger(JwtDebuggerReducer.State())
        case .fileContentSearch:
            #if os(macOS)
            state.destination = .fileContentSearch(FileContentSearchReducer.State())
            #else
            break  // Not available on iOS
            #endif
        case .uuidGenerator:
            break  // Inactive tool
        }
    }

}

// MARK: - App View

public struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>
    @State private var quickActionBarSelectedTool: Tool?

    public init(store: StoreOf<AppReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .overlay {
            quickActionBarView
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    store.send(.setQuickActionBarVisible(true))
                } label: {
                    Label("Go to Tool", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .onChange(of: quickActionBarSelectedTool) { _, newValue in
            if let tool = newValue {
                store.send(.setCurrentTool(tool))
                quickActionBarSelectedTool = nil
            }
        }
    }

    // MARK: - Quick Action Bar

    @ViewBuilder
    private var quickActionBarView: some View {
        QuickActionBar<Tool, Text>(
            location: .window,
            visible: $store.isQuickActionBarVisible.sending(\.setQuickActionBarVisible),
            requiredClickCount: .single,
            selectedItem: $quickActionBarSelectedTool,
            placeholderText: "Search tools…",
            itemsForSearchTerm: { task in
                let searchTerm = task.searchTerm
                let results: [Tool]
                if searchTerm.isEmpty {
                    results = Tool.allCases.filter(\.isActive)
                } else {
                    results = Tool.allCases
                        .filter(\.isActive)
                        .compactMap { tool -> (Tool, Int)? in
                            guard let score = tool.name.fuzzyMatchScore(searchTerm) else {
                                return nil
                            }
                            return (tool, score)
                        }
                        .sorted { $0.1 < $1.1 }
                        .map(\.0)
                }
                task.complete(with: results)
            },
            viewForItem: { tool, _ in
                Text(tool.name)
            }
        )
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        List(selection: $store.currentTool.sending(\.setCurrentTool)) {
            // Sort by name inside sections
            Section(
                NSLocalizedString(
                    "Converters",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.asciiToHex, label: "ASCII to Hex") {
                    Text("0x").font(.monospaced(Font.system(size: 10))())
                }
                toolRow(.backslashEscape, label: "Backslash Escape") {
                    Text("\\\\").font(.monospaced(Font.system(size: 10))())
                }
                toolRow(.base64, label: "Base64") {
                    Text("B64").font(.monospaced(Font.system(size: 10))())
                }
                toolRow(.base64Image, label: "Base64 Image") {
                    Image(systemName: "photo")
                }
                toolRow(.colorConverter, label: "Color Converter") {
                    Image(systemName: "paintpalette")
                }
                toolRow(.hexToAscii, label: "Hex to ASCII") {
                    Text("x→A").font(.monospaced(Font.system(size: 8))())
                }
                toolRow(.htmlToMarkdown, label: "HTML to Markdown") {
                    ZStack(alignment: .leading) {
                        Text("M↓").font(.monospaced(Font.system(size: 14))()).fontWeight(.medium)
                            .offset(CGSize(width: 5, height: 0))
                        Text("<>").font(.monospaced(Font.system(size: 14))()).fontWeight(.thin)
                            .offset(CGSize(width: 0, height: -7))
                    }
                }
                toolRow(.htmlToSwift, label: "Html to Swift") {
                    ZStack(alignment: .leading) {
                        Image(systemName: "swift").offset(CGSize(width: 5, height: 0))
                        Text("<>").font(.monospaced(Font.system(size: 14))()).fontWeight(.thin)
                            .offset(CGSize(width: 0, height: -7))
                    }
                }
                toolRow(.jsonToYaml, label: "JSON to YAML") {
                    Text("J→Y").font(.monospaced(Font.system(size: 8))())
                }
                toolRow(.jwtDebugger, label: "JWT Debugger") {
                    Image(systemName: "signature")
                }
                toolRow(.lineSortDedupe, label: "Line Sort/Dedupe") {
                    Image(systemName: "arrow.up.arrow.down")
                }
                toolRow(.numberBaseConverter, label: "Number Base") {
                    Image(systemName: "number")
                }
                toolRow(.prefixSuffix, label: "Prefix Suffix") {
                    Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")
                }
                toolRow(.qrCodeTool, label: "QR Code") {
                    Image(systemName: "qrcode")
                }
                toolRow(.regexMatches, label: "Regex Matches") {
                    Text("(.*)").font(.monospaced(Font.system(size: 8))())
                }
                toolRow(.svgToCss, label: "SVG to CSS") {
                    Image(systemName: "square.and.arrow.down")
                }
                toolRow(.textCaseConverter, label: "Text Case") {
                    Text("Aa")
                }
                toolRow(.unixTime, label: "Unix Time") {
                    Image(systemName: "clock")
                }
                toolRow(.urlEncode, label: "URL Encode") {
                    Image(systemName: "link")
                }
                toolRow(.urlToMarkdown, label: "URL to Markdown") {
                    ZStack(alignment: .leading) {
                        Text("M↓").font(.monospaced(Font.system(size: 14))()).fontWeight(.medium)
                            .offset(CGSize(width: 5, height: 0))
                        Image(systemName: "link").font(.system(size: 10)).offset(CGSize(width: 0, height: -7))
                    }
                }
                toolRow(.yamlToJson, label: "YAML to JSON") {
                    Text("Y→J").font(.monospaced(Font.system(size: 8))())
                }
            }

            Section(
                NSLocalizedString(
                    "Formatters",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.cssBeautify, label: "CSS") {
                    Text("CSS").font(.monospaced(Font.system(size: 8))())
                }
                toolRow(.htmlBeautify, label: "HTML") {
                    Text("HTML").font(.monospaced(Font.system(size: 8))())
                }
                toolRow(.jsBeautify, label: "JS") {
                    Text("JS").font(.monospaced(Font.system(size: 10))())
                }
                toolRow(.jsonPretty, label: "Json") {
                    Text("{.,}").font(.monospaced(Font.system(size: 8))())
                }
                toolRow(.swiftPrettyLockwood, label: "Swift") {
                    Image(systemName: "swift")
                }
                toolRow(.xmlFormat, label: "XML Formatter") {
                    Text("</>").font(.monospaced(Font.system(size: 8))())
                }
            }

            #if os(macOS)
                Section(
                    NSLocalizedString(
                        "File",
                        bundle: Bundle.module,
                        comment: "sidebar section name for a group of tools"
                    )
                ) {
                    toolRow(.fileContentSearch, label: "File Search") {
                        Image(systemName: "doc.text.magnifyingglass")
                    }
                }
            #endif

            Section(
                NSLocalizedString(
                    "Generators",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.hashGenerator, label: "Hash Generator") {
                    Image(systemName: "lock.shield")
                }
                toolRow(.nameGenerator, label: "Name") {
                    Image(systemName: "person")
                }
                toolRow(.randomStringGenerator, label: "Random String") {
                    Image(systemName: "shuffle")
                }
                toolRow(.uuidUlid, label: "UUID/ULID") {
                    Image(systemName: "number.circle")
                }
            }

            Section(
                NSLocalizedString(
                    "Utilities",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.certificateDecoder, label: "Certificate Decoder") {
                    Image(systemName: "shield.checkered")
                }
                toolRow(.htmlPreview, label: "HTML Preview") {
                    Image(systemName: "safari")
                }
                toolRow(.regExpTester, label: "RegExp Tester") {
                    Text(".*").font(.monospaced(Font.system(size: 10))())
                }
                toolRow(.stringInspector, label: "String Inspector") {
                    Image(systemName: "text.magnifyingglass")
                }
                toolRow(.urlParser, label: "URL Parser") {
                    Image(systemName: "link.badge.plus")
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150)
        .accessibilityLabel(NSLocalizedString("Sidebar with the list of tools", bundle: Bundle.module, comment: ""))
    }

    // MARK: - Tool Row Helper

    @ViewBuilder
    private func toolRow<Icon: View>(
        _ tool: Tool,
        label: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Label {
            Text(NSLocalizedString(label, bundle: Bundle.module, comment: "tool name on the sidebar"))
        } icon: {
            icon()
        }
        .tag(tool)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if let store = store.scope(state: \.destination, action: \.destination.presented) {
            switch store.case {
            case .htmlToSwift(let childStore):
                HtmlToSwiftView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert Html code to a DSL in Swift",
                            bundle: Bundle.module,
                            comment: "a navigationTitle"
                        )
                    )
                    .padding(.top)

            case .htmlToMarkdown(let childStore):
                HtmlToMarkdownView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert HTML to Markdown",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .urlToMarkdown(let childStore):
                UrlToMarkdownView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert URL to Markdown",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .jsonPretty(let childStore):
                JsonPrettyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Format and Highlight Json",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .htmlBeautify(let childStore):
                HtmlBeautifyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "HTML Beautify / Minify",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .cssBeautify(let childStore):
                CssBeautifyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "CSS Beautify / Minify",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .jsBeautify(let childStore):
                JsBeautifyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "JS Beautify / Minify",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .textCaseConverter(let childStore):
                TextCaseConverterView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert case of list of words",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .prefixSuffix(let childStore):
                PrefixSuffixView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Change prefix or suffix of each line",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .lineSortDedupe(let childStore):
                LineSortDedupeView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Sort and dedupe lines",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .asciiToHex(let childStore):
                AsciiToHexView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert ASCII to Hex",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .hexToAscii(let childStore):
                HexToAsciiView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert Hex to ASCII",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .colorConverter(let childStore):
                ColorConverterView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Color Converter",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .svgToCss(let childStore):
                SvgToCssView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert SVG to CSS",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .backslashEscape(let childStore):
                BackslashEscapeView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Backslash Escape",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .xmlFormat(let childStore):
                XmlFormatView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "XML Beautify / Minify",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .regexMatches(let childStore):
                RegexMatchesView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Regex Matches",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .regExpTester(let childStore):
                RegExpTesterView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "RegExp Tester",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .swiftPrettyLockwood(let childStore):
                SwiftPrettyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Format Swift code",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .nameGenerator(let childStore):
                NameGeneratorView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Generate names or words",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .randomStringGenerator(let childStore):
                RandomStringGeneratorView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Generate random strings",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .base64(let childStore):
                Base64View(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Base64 Encode / Decode",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .hashGenerator(let childStore):
                HashGeneratorView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Hash Generator",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .base64Image(let childStore):
                Base64ImageView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Base64 Image Encode / Decode",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .stringInspector(let childStore):
                StringInspectorView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "String Inspector",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .numberBaseConverter(let childStore):
                NumberBaseConverterView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Number Base Converter",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .certificateDecoder(let childStore):
                CertificateDecoderView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Certificate Decoder",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .qrCodeTool(let childStore):
                QrCodeToolView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "QR Code Generator/Reader",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .jsonToYaml(let childStore):
                JsonToYamlView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "JSON to YAML",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .yamlToJson(let childStore):
                YamlToJsonView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "YAML to JSON",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .uuidUlid(let childStore):
                UuidUlidView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "UUID/ULID Generator/Decoder",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .unixTime(let childStore):
                UnixTimeView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Unix Time Converter",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .urlEncode(let childStore):
                UrlEncodeView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "URL Encode / Decode",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .urlParser(let childStore):
                UrlParserView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "URL Parser",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .jwtDebugger(let childStore):
                JwtDebuggerView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "JWT Debugger",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .htmlPreview(let childStore):
                HtmlPreviewView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "HTML Preview",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            #if os(macOS)
                case .fileContentSearch(let childStore):
                    FileContentSearchView(store: childStore)
                        .navigationTitle(
                            NSLocalizedString(
                                "Search inside files",
                                bundle: Bundle.module,
                                comment: "navigation title on top of the window"
                            )
                        )
                        .padding(.top)
            #endif
            }
        }
        else {
            HomeStartView()
        }
    }
}

// MARK: - Fuzzy Match

extension String {
    /// Returns a score if `query` fuzzy-matches this string (characters appear in order),
    /// or nil if there's no match. Lower score = better match.
    func fuzzyMatchScore(_ query: String) -> Int? {
        let haystack = self.lowercased()
        let needle = query.lowercased()
        var score = 0
        var haystackIndex = haystack.startIndex
        var previousMatchIndex: String.Index?

        for char in needle {
            guard let found = haystack[haystackIndex...].firstIndex(of: char) else {
                return nil
            }
            // Penalize gaps between matched characters
            if let prev = previousMatchIndex {
                score += haystack.distance(from: prev, to: found)
            }
            previousMatchIndex = found
            haystackIndex = haystack.index(after: found)
        }
        return score
    }
}

// MARK: - Preview

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: Store(initialState: AppReducer.State()) {
                AppReducer()
            }
        )
    }
}
