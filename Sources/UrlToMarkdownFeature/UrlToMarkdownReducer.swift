import BlissTheme
import Dependencies
import Demark
import Foundation
import HtmlToMarkdownFeature
import MarkdownUI
import SharedModels
import Sharing
import SwiftUI

// MARK: - FileStorage Keys for Configuration

extension URL {
    fileprivate static var urlToMarkdownConfigStorage: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ToolStorage")
            .appendingPathComponent("urlToMarkdownConfig.json")
    }

    fileprivate static var urlLoadingConfigStorage: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ToolStorage")
            .appendingPathComponent("urlLoadingConfig.json")
    }
}

extension SharedReaderKey where Self == FileStorageKey<HtmlToMarkdownConfig> {
    public static var urlToMarkdownConfig: Self {
        .fileStorage(.urlToMarkdownConfigStorage)
    }
}

extension SharedReaderKey where Self == FileStorageKey<UrlLoadingConfig> {
    public static var urlLoadingConfig: Self {
        .fileStorage(.urlLoadingConfigStorage)
    }
}

@MainActor
@Observable
public final class UrlToMarkdownModel {
    @ObservationIgnored
    @Shared(.toolInput("urlToMarkdown")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("urlToMarkdown")) public var outputText = ""

    @ObservationIgnored
    @Shared(.urlToMarkdownConfig) public var configuration = HtmlToMarkdownConfig()

    @ObservationIgnored
    @Shared(.urlLoadingConfig) public var loadingConfiguration = UrlLoadingConfig()

    public var isConversionRequestInFlight = false
    public var errorMessage: String?
    public var showMarkdownPreview = false

    private var conversionTask: Task<Void, Never>?

    @ObservationIgnored
    @Dependency(\.urlToMarkdown) private var urlToMarkdown

    public var urlInput: String {
        get { inputText }
        set { setInputText(newValue) }
    }

    public init(
        configuration: HtmlToMarkdownConfig = .init(),
        loadingConfiguration: UrlLoadingConfig = .init()
    ) {
        let inputText = Shared(wrappedValue: "", .toolInput("urlToMarkdown"))
        let outputText = Shared(wrappedValue: "", .toolOutput("urlToMarkdown"))
        self._inputText = inputText
        self._outputText = outputText
        self.isConversionRequestInFlight = false
        self.showMarkdownPreview = false
        self.$configuration.withLock { $0 = configuration }
        self.$loadingConfiguration.withLock { $0 = loadingConfiguration }
    }

    public init(input: String, output: String = "") {
        let outputText = Shared(wrappedValue: output, .toolOutput("urlToMarkdown"))
        self._inputText = Shared(wrappedValue: input, .toolInput("urlToMarkdown"))
        self._outputText = outputText
        self.isConversionRequestInFlight = false
        self.showMarkdownPreview = false
    }

    public func setInputText(_ value: String) {
        $inputText.withLock { $0 = value }
    }

    public func setEngine(_ value: ConversionEngine) {
        var configuration = configuration
        configuration.engine = value
        $configuration.withLock { $0 = configuration }
    }

    public func setHeadingStyle(_ value: DemarkHeadingStyle) {
        var configuration = configuration
        configuration.headingStyle = value
        $configuration.withLock { $0 = configuration }
    }

    public func setBulletListMarker(_ value: String) {
        var configuration = configuration
        configuration.bulletListMarker = value
        $configuration.withLock { $0 = configuration }
    }

    public func setCodeBlockStyle(_ value: DemarkCodeBlockStyle) {
        var configuration = configuration
        configuration.codeBlockStyle = value
        $configuration.withLock { $0 = configuration }
    }

    public func setContentSelector(_ value: String) {
        var loadingConfiguration = loadingConfiguration
        loadingConfiguration.contentSelector = value
        $loadingConfiguration.withLock { $0 = loadingConfiguration }
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        conversionTask = nil

        errorMessage = nil
        guard !inputText.isEmpty else {
            errorMessage = "URL must not be empty"
            return
        }

        guard let url = URL(string: inputText) else {
            errorMessage = "Invalid URL"
            return
        }

        isConversionRequestInFlight = true
        let config = configuration
        let loadingConfig = loadingConfiguration
        let urlToMarkdown = urlToMarkdown

        conversionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let markdown = try await urlToMarkdown.convert(url, config, loadingConfig)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = markdown }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.errorMessage = error.localizedDescription
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

public struct UrlToMarkdownModelView: View {
    @Bindable var model: UrlToMarkdownModel

    public init(model: UrlToMarkdownModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField(
                    "Enter URL to convert",
                    text: Binding(
                        get: { model.urlInput },
                        set: { model.setInputText($0) }
                    )
                )
                    .blissTextField()
                    .onSubmit {
                        model.convertButtonTouched()
                    }

                LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
                    model.convertButtonTouched()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Convert URL to Markdown (⌘ Return)")
                .disabled(model.urlInput.isEmpty || model.isConversionRequestInFlight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            configurationGrid
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text("Markdown Output")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Toggle("Preview", isOn: $model.showMarkdownPreview)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .help("Toggle between raw markdown and rendered preview")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ThemeColor.Background.controlBackground)

                Divider()

                if model.showMarkdownPreview {
                    ScrollView {
                        Markdown(model.outputText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ThemeColor.Background.textBackground)
                } else {
                    TextEditor(text: Binding(
                        get: { model.outputText },
                        set: { newValue in model.$outputText.withLock { $0 = newValue } }
                    ))
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    private var enginePicker: some View {
        Picker(
            "Engine",
            selection: Binding(
                get: { model.configuration.engine },
                set: { model.setEngine($0) }
            )
        ) {
            Text("Turndown (Accurate)").tag(ConversionEngine.turndown)
            Text("html-to-md (Fast)").tag(ConversionEngine.htmlToMd)
        }
        .help("Turndown for complex HTML, html-to-md for speed")
    }

    private var headingStylePicker: some View {
        Picker(
            "Heading Style",
            selection: Binding(
                get: { model.configuration.headingStyle },
                set: { model.setHeadingStyle($0) }
            )
        ) {
            Text("ATX (# Heading)").tag(DemarkHeadingStyle.atx)
            Text("Setext (Underline)").tag(DemarkHeadingStyle.setext)
        }
        .help("ATX uses # prefix, Setext uses underlines")
    }

    private var bulletMarkerPicker: some View {
        Picker(
            "Bullet Marker",
            selection: Binding(
                get: { model.configuration.bulletListMarker },
                set: { model.setBulletListMarker($0) }
            )
        ) {
            Text("-").tag("-")
            Text("*").tag("*")
            Text("+").tag("+")
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .help("Character for unordered list items")
    }

    private var codeBlockStylePicker: some View {
        Picker(
            "Code Block Style",
            selection: Binding(
                get: { model.configuration.codeBlockStyle },
                set: { model.setCodeBlockStyle($0) }
            )
        ) {
            Text("Fenced (``` )").tag(DemarkCodeBlockStyle.fenced)
            Text("Indented").tag(DemarkCodeBlockStyle.indented)
        }
        .help("Fenced uses triple backticks, Indented uses 4 spaces")
    }

    private var contentSelectorField: some View {
        TextField(
            "e.g., article, main, .content",
            text: Binding(
                get: { model.loadingConfiguration.contentSelector },
                set: { model.setContentSelector($0) }
            )
        )
            .blissCompactTextField()
            .help("CSS selector to extract specific content (leave empty for full page)")
    }

    @ViewBuilder
    private var configurationGrid: some View {
        #if os(iOS)
        VStack(spacing: 10) {
            enginePicker
            headingStylePicker
            HStack {
                Text("Bullet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                bulletMarkerPicker
            }
            codeBlockStylePicker
            VStack(alignment: .leading, spacing: 4) {
                Text("Content Selector")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                contentSelectorField
            }
        }
        #else
        let labelWidth: CGFloat = 120

        Grid(horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                ConfigLabel("Engine")
                    .frame(width: labelWidth, alignment: .trailing)
                enginePicker
                    .blissMenuPicker(width: 180)
                    .controlSize(.small)

                ConfigLabel("Heading Style")
                    .frame(width: labelWidth, alignment: .trailing)
                headingStylePicker
                    .blissMenuPicker(width: 160)
                    .controlSize(.small)
            }

            GridRow {
                ConfigLabel("Bullet Marker")
                    .frame(width: labelWidth, alignment: .trailing)
                bulletMarkerPicker
                    .frame(width: 180, alignment: .leading)
                    .controlSize(.small)

                ConfigLabel("Code Blocks")
                    .frame(width: labelWidth, alignment: .trailing)
                codeBlockStylePicker
                    .blissMenuPicker(width: 160)
                    .controlSize(.small)
            }

            GridRow {
                ConfigLabel("Content Selector")
                    .frame(width: labelWidth, alignment: .trailing)
                contentSelectorField
                    .gridCellColumns(3)
            }
        }
        #endif
    }
}

struct UrlToMarkdownModelView_Previews: PreviewProvider {
    static var previews: some View {
        UrlToMarkdownModelView(model: .init())
    }
}
