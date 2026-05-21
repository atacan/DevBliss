import SwiftUI
import AsciiToHexFeature
import Base64Feature
import Base64ImageFeature
import ColorConverterFeature
import CssBeautifyFeature
import HtmlToMarkdownFeature
import PrefixSuffixFeature
import BackslashEscapeFeature
import HashGeneratorFeature
import HexToAsciiFeature
import LineSortDedupeFeature
import NumberBaseConverterFeature
import TextCaseConverterFeature
import YamlToJsonFeature
import JsonToYamlFeature
import XmlFormatFeature
import HtmlPreviewFeature
import HtmlBeautifyFeature
import JsBeautifyFeature
import SvgToCssFeature
import UrlEncodeFeature
import UrlParserFeature
import UrlToMarkdownFeature
import UnixTimeFeature
import SwiftPrettyFeature
import JwtDebuggerFeature
import HtmlToSwiftFeature
import FileContentSearchFeature
import UuidUlidFeature
import RandomStringGeneratorFeature
import NameGeneratorFeature
import UUIDGeneratorFeature
import RegExpTesterFeature
import RegexMatchesFeature
import StringInspectorFeature
import StringDiffFeature
import JsonPrettyFeature
import CertificateDecoderFeature
import QrCodeToolFeature
import SharedModels
import Foundation
#if os(macOS)
import DSFQuickActionBar
#endif

public struct AppModelView: View {
    @Bindable var model: AppModel
    #if os(macOS)
    @State private var quickActionBarSelectedTool: Tool?
    #endif

    public init(model: AppModel) {
        self.model = model
    }

    private var activeTools: [Tool] {
        Tool.allCases
            .filter(\.isActive)
            .sortedByName()
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $model.currentTool) {
                ForEach(activeTools, id: \.self) { tool in
                    NavigationLink(value: tool) {
                        toolLabel(for: tool)
                    }
                }
            }
            .navigationTitle("Tools")
        } detail: {
            detailView
        }
        #if os(macOS)
        .overlay {
            quickActionBarView
        }
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .automatic) {
                Button {
                    model.resetToolsWithDebugSamples()
                } label: {
                    Label("Load Sample Inputs", systemImage: "wand.and.stars")
                }
                .help("Reset all tools with debug sample inputs")
            }
            #endif

            ToolbarItem(placement: .automatic) {
                Button {
                    model.isQuickActionBarVisible = true
                } label: {
                    Label("Go to Tool", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .onChange(of: quickActionBarSelectedTool) { _, newValue in
            if let tool = newValue {
                model.setCurrentTool(tool)
                quickActionBarSelectedTool = nil
            }
        }
        #endif
    }

    @ViewBuilder
    private var quickActionBarView: some View {
        #if os(macOS)
            QuickActionBar<Tool, Text>(
                location: .window,
                visible: $model.isQuickActionBarVisible,
                requiredClickCount: .single,
                selectedItem: $quickActionBarSelectedTool,
                placeholderText: "Search tools…",
                itemsForSearchTerm: { task in
                    let searchTerm = task.searchTerm
                    let results: [Tool]
                    if searchTerm.isEmpty {
                        results = activeTools
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
        #else
            EmptyView()
        #endif
    }

    @ViewBuilder
    private var detailView: some View {
        switch model.destination {
        case .none:
            HomeStartView()
        case .urlEncode(let model):
            UrlEncodeModelView(model: model)
                .padding(.top)
        case .urlParser(let model):
            UrlParserModelView(model: model)
                .padding(.top)
        case .base64(let model):
            Base64ModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .asciiToHex(let model):
            AsciiToHexModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .hexToAscii(let model):
            HexToAsciiModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .cssBeautify(let model):
            CssBeautifyModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .htmlBeautify(let model):
            HtmlBeautifyModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .hashGenerator(let model):
            HashGeneratorModelView(model: model)
                .padding(.top)
        case .colorConverter(let model):
            ColorConverterView(model: model)
                .padding(.top)
        case .lineSortDedupe(let model):
            LineSortDedupeModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .numberBaseConverter(let model):
            NumberBaseConverterModelView(model: model)
                .padding(.top)
        case .textCaseConverter(let model):
            TextCaseConverterModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .prefixSuffix(let model):
            PrefixSuffixModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .yamlToJson(let model):
            YamlToJsonModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .jsonToYaml(let model):
            JsonToYamlModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .jsBeautify(let model):
            JsBeautifyModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .xmlFormat(let model):
            XmlFormatModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .svgToCss(let model):
            SvgToCssModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .htmlPreview(let model):
            HtmlPreviewModelView(model: model)
                .padding(.top)
        case .htmlToMarkdown(let model):
            HtmlToMarkdownModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .urlToMarkdown(let model):
            UrlToMarkdownModelView(model: model)
                .padding(.top)
        case .htmlToSwift(let model):
            HtmlToSwiftModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .swiftPrettyLockwood(let model):
            SwiftPrettyModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .jwtDebugger(let model):
            JwtDebuggerModelView(model: model)
                .padding(.top)
        case .backslashEscape(let model):
            BackslashEscapeModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        case .uuidUlid(let model):
            UuidUlidModelView(model: model)
                .padding(.top)
        case .randomStringGenerator(let model):
            RandomStringGeneratorModelView(model: model)
                .padding(.top)
        case .nameGenerator(let model):
            NameGeneratorModelView(model: model)
                .padding(.top)
        case .uuidGenerator(let model):
            UUIDGeneratorModelView(model: model)
                .padding(.top)
        case .regExpTester(let model):
            RegExpTesterModelView(model: model)
                .padding(.top)
        case .regexMatches(let model):
            RegexMatchesModelView(model: model)
                .padding(.top)
        case .stringDiff(let model):
            StringDiffModelView(model: model)
                .padding(.top)
        case .unixTime(let model):
            UnixTimeModelView(model: model)
                .padding(.top)
        case .base64Image(let model):
            Base64ImageModelView(model: model)
                .padding(.top)
        case .stringInspector(let model):
            StringInspectorModelView(model: model)
                .padding(.top)
        case .certificateDecoder(let model):
            CertificateDecoderView(model: model)
                .padding(.top)
        case .qrCodeTool(let model):
            QrCodeToolView(model: model)
                .padding(.top)
        case .jsonPretty(let model):
            JsonPrettyModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
                .padding(.top)
        #if os(macOS)
        case .fileContentSearch(let model):
            FileContentSearchView(model: model)
                .padding(.top)
        #endif
        }
    }

    private func toolLabel(for tool: Tool) -> some View {
        Label {
            Text(tool.name)
        } icon: {
            toolIcon(for: tool)
                .frame(width: 22, height: 18)
        }
    }

    @ViewBuilder
    private func toolIcon(for tool: Tool) -> some View {
        switch tool {
        case .asciiToHex:
            Text("0x")
                .font(.system(size: 10, design: .monospaced))
        case .backslashEscape:
            Text("\\\\")
                .font(.system(size: 10, design: .monospaced))
        case .base64:
            Text("B64")
                .font(.system(size: 10, design: .monospaced))
        case .base64Image:
            Image(systemName: "photo")
        case .certificateDecoder:
            Image(systemName: "shield.checkered")
        case .colorConverter:
            Image(systemName: "paintpalette")
        case .cssBeautify:
            Text("CSS")
                .font(.system(size: 8, design: .monospaced))
        case .fileContentSearch:
            Image(systemName: "doc.text.magnifyingglass")
        case .hashGenerator:
            Image(systemName: "lock.shield")
        case .hexToAscii:
            Text("x→A")
                .font(.system(size: 8, design: .monospaced))
        case .htmlBeautify:
            Text("HTML")
                .font(.system(size: 8, design: .monospaced))
        case .htmlPreview:
            Image(systemName: "safari")
        case .htmlToMarkdown:
            ZStack(alignment: .leading) {
                Text("M↓")
                    .font(.monospaced(Font.system(size: 14))())
                    .fontWeight(.medium)
                    .offset(CGSize(width: 5, height: 0))
                Text("<>")
                    .font(.monospaced(Font.system(size: 14))())
                    .fontWeight(.thin)
                    .offset(CGSize(width: 0, height: -7))
            }
        case .htmlToSwift:
            ZStack(alignment: .leading) {
                Image(systemName: "swift")
                    .offset(CGSize(width: 5, height: 0))
                Text("<>")
                    .font(.monospaced(Font.system(size: 14))())
                    .fontWeight(.thin)
                    .offset(CGSize(width: 0, height: -7))
            }
        case .jsBeautify:
            Text("JS")
                .font(.system(size: 10, design: .monospaced))
        case .jsonToYaml:
            Text("J→Y")
                .font(.system(size: 8, design: .monospaced))
        case .jsonPretty:
            Text("{.,}")
                .font(.system(size: 8, design: .monospaced))
        case .jwtDebugger:
            Image(systemName: "signature")
        case .lineSortDedupe:
            Image(systemName: "arrow.up.arrow.down")
        case .nameGenerator:
            Image(systemName: "person")
        case .numberBaseConverter:
            Image(systemName: "number")
        case .prefixSuffix:
            Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")
        case .qrCodeTool:
            Image(systemName: "qrcode")
        case .randomStringGenerator:
            Image(systemName: "shuffle")
        case .regExpTester:
            Text(".*")
                .font(.system(size: 10, design: .monospaced))
        case .regexMatches:
            Text("(.*)")
                .font(.system(size: 8, design: .monospaced))
        case .stringDiff:
            Image(systemName: "arrow.triangle.2.circlepath")
        case .stringInspector:
            Image(systemName: "text.magnifyingglass")
        case .svgToCss:
            Image(systemName: "square.and.arrow.down")
        case .swiftPrettyLockwood:
            Image(systemName: "swift")
        case .textCaseConverter:
            Text("Aa")
        case .unixTime:
            Image(systemName: "clock")
        case .urlEncode:
            Text("%")
                .font(.system(size: 12, design: .monospaced))
        case .urlParser:
            Image(systemName: "link.badge.plus")
        case .urlToMarkdown:
            ZStack(alignment: .leading) {
                Text("M↓")
                    .font(.monospaced(Font.system(size: 14))())
                    .fontWeight(.medium)
                    .offset(CGSize(width: 5, height: 0))
                Image(systemName: "link")
                    .font(.system(size: 10))
                    .offset(CGSize(width: 0, height: -7))
            }
        case .uuidGenerator:
            Text("ID")
                .font(.system(size: 10, design: .monospaced))
        case .uuidUlid:
            Image(systemName: "number.circle")
        case .xmlFormat:
            Text("</>")
                .font(.system(size: 8, design: .monospaced))
        case .yamlToJson:
            Text("Y→J")
                .font(.system(size: 8, design: .monospaced))
        }
    }
}

private extension Array where Element == Tool {
    func sortedByName() -> Self {
        sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}

private extension String {
    func fuzzyMatchScore(_ searchTerm: String) -> Int? {
        let haystack = lowercased()
        let needle = searchTerm.lowercased()
        guard !needle.isEmpty else { return 0 }

        var score = 0
        var searchIndex = haystack.startIndex

        for character in needle {
            guard let matchIndex = haystack[searchIndex...].firstIndex(of: character) else {
                return nil
            }
            score += haystack.distance(from: searchIndex, to: matchIndex)
            searchIndex = haystack.index(after: matchIndex)
        }

        score += max(0, haystack.count - needle.count)
        return score
    }
}
