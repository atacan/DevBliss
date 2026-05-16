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
        set { inputText = newValue }
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
        self.configuration = configuration
        self.loadingConfiguration = loadingConfiguration
    }

    public init(input: String, output: String = "") {
        let outputText = Shared(wrappedValue: output, .toolOutput("urlToMarkdown"))
        self._inputText = Shared(wrappedValue: input, .toolInput("urlToMarkdown"))
        self._outputText = outputText
        self.isConversionRequestInFlight = false
        self.showMarkdownPreview = false
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
                    isConversionRequestInFlight = false
                    outputText = markdown
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    errorMessage = error.localizedDescription
                    outputText = error.localizedDescription
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

extension UrlToMarkdownModel: Equatable {
    public static func == (lhs: UrlToMarkdownModel, rhs: UrlToMarkdownModel) -> Bool {
        lhs === rhs
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
                TextField("Enter URL to convert", text: $model.urlInput)
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
                    TextEditor(text: $model.outputText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    private var enginePicker: some View {
        Picker("Engine", selection: $model.configuration.engine) {
            Text("Turndown (Accurate)").tag(ConversionEngine.turndown)
            Text("html-to-md (Fast)").tag(ConversionEngine.htmlToMd)
        }
        .help("Turndown for complex HTML, html-to-md for speed")
    }

    private var headingStylePicker: some View {
        Picker("Heading Style", selection: $model.configuration.headingStyle) {
            Text("ATX (# Heading)").tag(DemarkHeadingStyle.atx)
            Text("Setext (Underline)").tag(DemarkHeadingStyle.setext)
        }
        .help("ATX uses # prefix, Setext uses underlines")
    }

    private var bulletMarkerPicker: some View {
        Picker("Bullet Marker", selection: $model.configuration.bulletListMarker) {
            Text("-").tag("-")
            Text("*").tag("*")
            Text("+").tag("+")
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .help("Character for unordered list items")
    }

    private var codeBlockStylePicker: some View {
        Picker("Code Block Style", selection: $model.configuration.codeBlockStyle) {
            Text("Fenced (``` )").tag(DemarkCodeBlockStyle.fenced)
            Text("Indented").tag(DemarkCodeBlockStyle.indented)
        }
        .help("Fenced uses triple backticks, Indented uses 4 spaces")
    }

    private var contentSelectorField: some View {
        TextField("e.g., article, main, .content", text: $model.loadingConfiguration.contentSelector)
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
