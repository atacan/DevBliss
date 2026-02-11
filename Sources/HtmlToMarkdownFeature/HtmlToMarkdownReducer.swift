import BlissTheme
import ComposableArchitecture
import Demark
import Dependencies
import DependenciesAdditions
import Foundation
import HtmlToMarkdownClient
import InputOutput
import MarkdownUI
import SharedModels
import SplitView
import SwiftUI
import SyntaxHighlightClient

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

@Reducer
public struct HtmlToMarkdownReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("htmlToMarkdown")) public var inputText = ""
        @Shared(.toolOutput("htmlToMarkdown")) public var outputText = ""
        @Shared(.htmlToMarkdownConfig) public var configuration = HtmlToMarkdownConfig()
        public var inputOutput: InputOutputAttributedEditorsReducer.State
        var isConversionRequestInFlight = false
        var showMarkdownPreview = false

        public init(
            inputOutput: InputOutputAttributedEditorsReducer.State = .init(),
            configuration: HtmlToMarkdownConfig = .init()
        ) {
            let inputText = Shared(wrappedValue: "", .toolInput("htmlToMarkdown"))
            let outputText = Shared(wrappedValue: "", .toolOutput("htmlToMarkdown"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputRawText: outputText.projectedValue
            )

            self.isConversionRequestInFlight = false
            // Configuration is loaded from file storage automatically via @Shared
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("htmlToMarkdown"))
            let outputText = Shared(wrappedValue: output, .toolOutput("htmlToMarkdown"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputRawText: outputText.projectedValue
            )

            self.isConversionRequestInFlight = false
            // Configuration is loaded from file storage automatically via @Shared
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case highlightResponse(NSAttributedString)
        case inputOutput(InputOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.htmlToMarkdown) var htmlToMarkdown
    @Dependency(\.syntaxHighlight) var syntaxHighlight
    private enum CancelID { case conversionRequest, highlightRequest }
    private static let maxHighlightCharacters = 100_000
    @Dependency(\.mainQueue) var mainQueue

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                return
                    .run { [input = state.inputOutput.input.text, config = state.configuration] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await htmlToMarkdown.convert(input, config)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(markdown)):
                state.isConversionRequestInFlight = false
                let showPlainText = state.inputOutput.output.updateText(markdown)
                    .map { Action.inputOutput(.output($0)) }

                guard markdown.count <= Self.maxHighlightCharacters else {
                    return showPlainText
                }

                return .merge(
                    showPlainText,
                    .run { [syntaxHighlight] send in
                        let highlighted = await syntaxHighlight.highlightMarkdown(markdown)
                        if highlighted.length > 0 {
                            await send(.highlightResponse(highlighted))
                        }
                    }
                    .cancellable(id: CancelID.highlightRequest, cancelInFlight: true)
                )

            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(errorAttributedString(error.localizedDescription))
                    .map { Action.inputOutput(.output($0)) }

            case let .highlightResponse(highlighted):
                return state.inputOutput.output.updateText(highlighted)
                    .map { Action.inputOutput(.output($0)) }

            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: \.inputOutput) {
            InputOutputAttributedEditorsReducer()
        }
    }
}

public struct HtmlToMarkdownView: View {
    @Bindable var store: StoreOf<HtmlToMarkdownReducer>

    public init(store: StoreOf<HtmlToMarkdownReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Configuration panel
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                // Row 1: Engine and Heading Style
                GridRow {
                    ConfigLabel("Engine")
                    Picker("Engine", selection: $store.configuration.engine) {
                        Text("Turndown (Accurate)").tag(ConversionEngine.turndown)
                        Text("html-to-md (Fast)").tag(ConversionEngine.htmlToMd)
                    }
                    .blissMenuPicker(width: 180)
                    .help("Turndown for complex HTML, html-to-md for speed")

                    ConfigLabel("Heading Style")
                    Picker("Heading Style", selection: $store.configuration.headingStyle) {
                        Text("ATX (# Heading)").tag(DemarkHeadingStyle.atx)
                        Text("Setext (Underline)").tag(DemarkHeadingStyle.setext)
                    }
                    .blissMenuPicker(width: 160)
                    .help("ATX uses # prefix, Setext uses underlines")
                }

                // Row 2: Bullet Marker and Code Block Style
                GridRow {
                    ConfigLabel("Bullet Marker")
                    Picker("Bullet Marker", selection: $store.configuration.bulletListMarker) {
                        Text("Dash (-)").tag("-")
                        Text("Asterisk (*)").tag("*")
                        Text("Plus (+)").tag("+")
                    }
                    .blissMenuPicker(width: 180)
                    .help("Character for unordered list items")

                    ConfigLabel("Code Blocks")
                    Picker("Code Block Style", selection: $store.configuration.codeBlockStyle) {
                        Text("Fenced (```)").tag(DemarkCodeBlockStyle.fenced)
                        Text("Indented").tag(DemarkCodeBlockStyle.indented)
                    }
                    .blissMenuPicker(width: 160)
                    .help("Fenced uses triple backticks, Indented uses 4 spaces")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            
            LoadingButton("Convert", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert HTML to Markdown (⌘ Return)")

            HStack(spacing: 12) {

                Spacer()

                Toggle("Preview", isOn: $store.showMarkdownPreview)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .help("Toggle between raw markdown and rendered preview")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            if store.showMarkdownPreview {
                markdownPreviewSplitView
            } else {
                InputOutputAttributedEditorsView(
                    store: store.scope(state: \.inputOutput, action: \.inputOutput),
                    inputEditorTitle: "HTML Input",
                    outputEditorTitle: "Markdown Output",
                    keyForFraction: SettingsKey.HtmlToMarkdown.splitViewFraction,
                    keyForLayout: SettingsKey.HtmlToMarkdown.splitViewLayout
                )
            }
        }
    }

    @ViewBuilder
    private var markdownPreviewSplitView: some View {
        let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HtmlToMarkdown.splitViewFraction)
        let layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HtmlToMarkdown.splitViewLayout)
        let hide = SideHolder()

        Split(
            primary: {
                // Input side
                VStack(spacing: 0) {
                    HStack {
                        Text("HTML Input")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeColor.Background.controlBackground)

                    Divider()

                    InputEditorView(
                        store: store.scope(state: \.inputOutput.input, action: \.inputOutput.input),
                        title: ""
                    )
                }
            },
            secondary: {
                // Output side with markdown preview
                VStack(spacing: 0) {
                    HStack {
                        Text("Markdown Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeColor.Background.controlBackground)

                    Divider()

                    ScrollView {
                        Markdown(store.outputText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ThemeColor.Background.textBackground)
                }
            }
        )
        .fraction(fraction)
        .layout(layout)
        .hide(hide)
        .styling(visibleThickness: 2)
    }
}

// Preview
struct HtmlToMarkdownReducer_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToMarkdownView(store: .init(initialState: .init()) { HtmlToMarkdownReducer() })
    }
}
