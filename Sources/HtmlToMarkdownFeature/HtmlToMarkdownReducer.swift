import BlissTheme
import Demark
import Dependencies
import MarkdownUI
import SharedModels
import InputOutput
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
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: HtmlToMarkdownModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        VStack(spacing: 0) {
            configurationView

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
                SideBySideView(
                    fractionKey: SettingsKey.HtmlToMarkdown.splitViewFraction,
                    layoutKey: SettingsKey.HtmlToMarkdown.splitViewLayout,
                    primaryLabel: "HTML Input",
                    secondaryLabel: "Markdown Output"
                ) {
                    PlainInputTextPane(title: "HTML Input", text: inputTextBinding)
                } secondary: {
                    PlainOutputTextPane(
                        title: "Markdown Output",
                        text: outputTextBinding,
                        onSendToTool: sendOutputToTool
                    )
                }
            }
        }
    }

    private var configurationView: some View {
        ViewThatFits(in: .horizontal) {
            regularConfigurationView
            compactConfigurationView
        }
        .padding(.horizontal, configurationHorizontalPadding)
        .padding(.vertical, configurationVerticalPadding)
    }

    private var regularConfigurationView: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ConfigLabel("Engine")
                enginePicker
                    .blissMenuPicker(width: 180)

                ConfigLabel("Heading Style")
                headingStylePicker
                    .blissMenuPicker(width: 160)
            }

            GridRow {
                ConfigLabel("Bullet Marker")
                bulletMarkerPicker
                    .blissMenuPicker(width: 180)

                ConfigLabel("Code Blocks")
                codeBlockStylePicker
                    .blissMenuPicker(width: 160)
            }
        }
    }

    private var compactConfigurationView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                enginePicker
                    .blissMenuPicker(width: 152)
                headingStylePicker
                    .blissMenuPicker(width: 152)
            }

            HStack(spacing: 8) {
                bulletMarkerPicker
                    .blissMenuPicker(width: 152)
                codeBlockStylePicker
                    .blissMenuPicker(width: 152)
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
            Text("Turndown").tag(ConversionEngine.turndown)
            Text("html-to-md").tag(ConversionEngine.htmlToMd)
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
            Text("ATX (#)").tag(DemarkHeadingStyle.atx)
            Text("Setext").tag(DemarkHeadingStyle.setext)
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
            Text("Dash (-)").tag("-")
            Text("Asterisk (*)").tag("*")
            Text("Plus (+)").tag("+")
        }
        .help("Character for unordered list items")
    }

    private var codeBlockStylePicker: some View {
        Picker(
            "Code Blocks",
            selection: Binding(
                get: { model.configuration.codeBlockStyle },
                set: { model.setCodeBlockStyle($0) }
            )
        ) {
            Text("Fenced").tag(DemarkCodeBlockStyle.fenced)
            Text("Indented").tag(DemarkCodeBlockStyle.indented)
        }
        .help("Fenced uses triple backticks, Indented uses 4 spaces")
    }

    private var configurationHorizontalPadding: CGFloat {
        #if os(iOS)
            return 10
        #else
            return 16
        #endif
    }

    private var configurationVerticalPadding: CGFloat {
        #if os(iOS)
            return 6
        #else
            return 8
        #endif
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

    private var sendOutputToTool: ((Tool) -> Void)? {
        guard let onSendOutputToTool else {
            return nil
        }

        return { tool in
            onSendOutputToTool(model.outputText, tool)
        }
    }

    private var inputTextBinding: Binding<String> {
        Binding(
            get: { model.inputText },
            set: { newValue in model.$inputText.withLock { $0 = newValue } }
        )
    }

    private var outputTextBinding: Binding<String> {
        Binding(
            get: { model.outputText },
            set: { newValue in model.$outputText.withLock { $0 = newValue } }
        )
    }
}

struct HtmlToMarkdownModelView_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToMarkdownModelView(model: .init())
    }
}
