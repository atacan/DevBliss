import BlissTheme
import Demark
import Dependencies
import MarkdownUI
import SharedModels
import SplitView
import SwiftUI
import SyntaxHighlightClient
import Sharing

// MARK: - FileStorage Key for Configuration

extension URL {
    fileprivate static var htmlToMarkdownConfigStorage: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ToolStorage")
            .appendingPathComponent("htmlToMarkdownConfig.json")
    }
}

extension SharedReaderKey where Self == FileStorageKey<HtmlToMarkdownConfig> {
    public static var htmlToMarkdownConfig: Self {
        .fileStorage(.htmlToMarkdownConfigStorage)
    }
}

@MainActor
@Observable
public final class HtmlToMarkdownModel {
    @ObservationIgnored
    @Shared(.toolInput("htmlToMarkdown")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("htmlToMarkdown")) public var outputText = ""

    @ObservationIgnored
    @Shared(.htmlToMarkdownConfig) public var configuration = HtmlToMarkdownConfig()

    public var isConversionRequestInFlight = false
    public var showMarkdownPreview = false
    public var errorMessage: String?

    private var conversionTask: Task<Void, Never>?

    @ObservationIgnored
    @Dependency(\.htmlToMarkdown) private var htmlToMarkdown
    @ObservationIgnored
    @Dependency(\.syntaxHighlight) private var syntaxHighlight

    private static let maxHighlightCharacters = 100_000

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("htmlToMarkdown"))
        let outputText = Shared(wrappedValue: "", .toolOutput("htmlToMarkdown"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("htmlToMarkdown"))
        let outputText = Shared(wrappedValue: output, .toolOutput("htmlToMarkdown"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        errorMessage = nil
        isConversionRequestInFlight = true
        let input = inputText
        let config = configuration
        let htmlToMarkdown = htmlToMarkdown

        conversionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let markdown = try await htmlToMarkdown.convert(input, config)
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

    public func setEngine(_ engine: ConversionEngine) {
        var configuration = configuration
        configuration.engine = engine
        $configuration.withLock { $0 = configuration }
    }

    public func setHeadingStyle(_ style: DemarkHeadingStyle) {
        var configuration = configuration
        configuration.headingStyle = style
        $configuration.withLock { $0 = configuration }
    }

    public func setBulletListMarker(_ marker: String) {
        var configuration = configuration
        configuration.bulletListMarker = marker
        $configuration.withLock { $0 = configuration }
    }

    public func setCodeBlockStyle(_ style: DemarkCodeBlockStyle) {
        var configuration = configuration
        configuration.codeBlockStyle = style
        $configuration.withLock { $0 = configuration }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

public struct HtmlToMarkdownModelView: View {
    @Bindable var model: HtmlToMarkdownModel

    public init(model: HtmlToMarkdownModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Engine")
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
                    .blissMenuPicker(width: 180)
                    .help("Turndown for complex HTML, html-to-md for speed")

                    ConfigLabel("Heading Style")
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
                    .blissMenuPicker(width: 160)
                    .help("ATX uses # prefix, Setext uses underlines")
                }

                GridRow {
                    ConfigLabel("Bullet Marker")
                    Picker(
                        "Bullet Marker",
                        selection: Binding(
                            get: { model.configuration.bulletListMarker },
                            set: { model.setBulletListMarker($0) }
                        )
                    ) {
                        Text("Dash (-)").tag("-")
                        Text("Asterisk (*)").tag("*")
                        Text("Plus (+)").tag("+")
                    }
                    .blissMenuPicker(width: 180)
                    .help("Character for unordered list items")

                    ConfigLabel("Code Blocks")
                    Picker(
                        "Code Blocks",
                        selection: Binding(
                            get: { model.configuration.codeBlockStyle },
                            set: { model.setCodeBlockStyle($0) }
                        )
                    ) {
                        Text("Fenced (``` )").tag(DemarkCodeBlockStyle.fenced)
                        Text("Indented").tag(DemarkCodeBlockStyle.indented)
                    }
                    .blissMenuPicker(width: 160)
                    .help("Fenced uses triple backticks, Indented uses 4 spaces")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert HTML to Markdown (⌘ Return)")

            HStack(spacing: 12) {
                Spacer()

                Toggle("Preview", isOn: $model.showMarkdownPreview)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .help("Toggle between raw markdown and rendered preview")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            if model.showMarkdownPreview {
                markdownPreviewSplitView
            } else {
                Split(primary: { inputEditor }, secondary: { outputEditor })
                    .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HtmlToMarkdown.splitViewFraction))
                    .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HtmlToMarkdown.splitViewLayout))
                    .styling(visibleThickness: 2)
            }
        }
    }

    @ViewBuilder
    private var markdownPreviewSplitView: some View {
        ScrollView {
            Markdown(model.outputText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeColor.Background.textBackground)
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HTML Input")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Markdown Output")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.outputText },
                set: { newValue in model.$outputText.withLock { $0 = newValue } }
            ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }
}

struct HtmlToMarkdownModelView_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToMarkdownModelView(model: .init())
    }
}
