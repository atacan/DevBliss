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
import SwiftUI
import SyntaxHighlightClient
import UrlToMarkdownClient

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

@Reducer
public struct UrlToMarkdownReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("urlToMarkdown")) public var inputText = ""
        @Shared(.toolOutput("urlToMarkdown")) public var outputText = ""
        @Shared(.urlToMarkdownConfig) public var configuration = HtmlToMarkdownConfig()
        @Shared(.urlLoadingConfig) public var loadingConfiguration = UrlLoadingConfig()
        public var output: OutputAttributedEditorReducer.State
        var isConversionRequestInFlight = false
        var errorMessage: String?
        var showMarkdownPreview = false

        // URL input is derived from inputText for persistence
        public var urlInput: String {
            get { inputText }
            set { $inputText.withLock { $0 = newValue } }
        }

        public init(
            configuration: HtmlToMarkdownConfig = .init(),
            loadingConfiguration: UrlLoadingConfig = .init()
        ) {
            let outputText = Shared(wrappedValue: "", .toolOutput("urlToMarkdown"))
            self._outputText = outputText
            self.output = OutputAttributedEditorReducer.State(rawText: outputText.projectedValue)
            self.isConversionRequestInFlight = false
        }

        public var outputString: String {
            output.text.string
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<NSAttributedString>)
        case output(OutputAttributedEditorReducer.Action)
    }

    @Dependency(\.urlToMarkdown) var urlToMarkdown
    @Dependency(\.syntaxHighlight) var syntaxHighlight
    private enum CancelID { case conversionRequest }
    @Dependency(\.mainQueue) var mainQueue

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.errorMessage = nil
                guard let url = URL(string: state.urlInput) else {
                    state.errorMessage = "Invalid URL"
                    return .none
                }
                state.isConversionRequestInFlight = true
                return
                    .run { [url = url, config = state.configuration, loadingConfig = state.loadingConfiguration] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    let markdown = try await urlToMarkdown.convert(url, config, loadingConfig)
                                    let highlighted = await syntaxHighlight.highlightMarkdown(markdown)
                                    return highlighted
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(highlighted)):
                state.isConversionRequestInFlight = false
                return state.output.updateText(highlighted)
                    .map { Action.output($0) }
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.errorMessage = error.localizedDescription
                return state.output.updateText(errorAttributedString(error.localizedDescription))
                    .map { Action.output($0) }
            case .output:
                return .none
            }
        }

        Scope(state: \.output, action: \.output) {
            OutputAttributedEditorReducer()
        }
    }
}

public struct UrlToMarkdownView: View {
    @Bindable var store: StoreOf<UrlToMarkdownReducer>

    public init(store: StoreOf<UrlToMarkdownReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Primary action area: URL input + Convert button
            HStack(spacing: 12) {
                TextField("Enter URL to convert", text: $store.urlInput)
                    .blissTextField()
                    .onSubmit {
                        store.send(.convertButtonTouched)
                    }

                LoadingButton("Convert", isLoading: store.isConversionRequestInFlight) {
                    store.send(.convertButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Convert URL to Markdown (⌘ Return)")
                .disabled(store.urlInput.isEmpty || store.isConversionRequestInFlight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Error message
            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            // Configuration panel
            configurationGrid
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()

            // Output area with preview toggle
            VStack(spacing: 0) {
                // Header with title and preview toggle
                HStack {
                    Text("Markdown Output")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Toggle("Preview", isOn: $store.showMarkdownPreview)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .help("Toggle between raw markdown and rendered preview")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ThemeColor.Background.controlBackground)

                Divider()

                // Content: either preview or raw editor
                if store.showMarkdownPreview {
                    ScrollView {
                        Markdown(store.outputText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ThemeColor.Background.textBackground)
                } else {
                    OutputAttributedEditorView(
                        store: store.scope(state: \.output, action: \.output),
                        title: ""
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var configurationGrid: some View {
        let labelWidth: CGFloat = 120

        Grid(horizontalSpacing: 18, verticalSpacing: 12) {
            // Row 1: Engine and Heading Style
            GridRow {
                ConfigLabel("Engine")
                    .frame(width: labelWidth, alignment: .trailing)
                Picker("Engine", selection: $store.configuration.engine) {
                    Text("Turndown (Accurate)").tag(ConversionEngine.turndown)
                    Text("html-to-md (Fast)").tag(ConversionEngine.htmlToMd)
                }
                .blissMenuPicker(width: 180)
                .controlSize(.small)
                .help("Turndown for complex HTML, html-to-md for speed")

                ConfigLabel("Heading Style")
                    .frame(width: labelWidth, alignment: .trailing)
                Picker("Heading Style", selection: $store.configuration.headingStyle) {
                    Text("ATX (# Heading)").tag(DemarkHeadingStyle.atx)
                    Text("Setext (Underline)").tag(DemarkHeadingStyle.setext)
                }
                .blissMenuPicker(width: 160)
                .controlSize(.small)
                .help("ATX uses # prefix, Setext uses underlines")
            }

            // Row 2: Bullet Marker and Code Block Style
            GridRow {
                ConfigLabel("Bullet Marker")
                    .frame(width: labelWidth, alignment: .trailing)
                Picker("Bullet Marker", selection: $store.configuration.bulletListMarker) {
                    Text("-").tag("-")
                    Text("*").tag("*")
                    Text("+").tag("+")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 180, alignment: .leading)
                .controlSize(.small)
                .help("Character for unordered list items")

                ConfigLabel("Code Blocks")
                    .frame(width: labelWidth, alignment: .trailing)
                Picker("Code Block Style", selection: $store.configuration.codeBlockStyle) {
                    Text("Fenced (```)").tag(DemarkCodeBlockStyle.fenced)
                    Text("Indented").tag(DemarkCodeBlockStyle.indented)
                }
                .blissMenuPicker(width: 160)
                .controlSize(.small)
                .help("Fenced uses triple backticks, Indented uses 4 spaces")
            }

            // Row 3: Content Selector - aligned with grid columns above
            GridRow {
                ConfigLabel("Content Selector")
                    .frame(width: labelWidth, alignment: .trailing)
                TextField("e.g., article, main, .content", text: $store.loadingConfiguration.contentSelector)
                    .blissCompactTextField()
//                    .frame(maxWidth: 200)
                    .gridCellColumns(3)
                    .help("CSS selector to extract specific content (leave empty for full page)")
            }
        }
    }
}

// Preview
struct UrlToMarkdownReducer_Previews: PreviewProvider {
    static var previews: some View {
        UrlToMarkdownView(store: .init(initialState: .init()) { UrlToMarkdownReducer() })
    }
}
