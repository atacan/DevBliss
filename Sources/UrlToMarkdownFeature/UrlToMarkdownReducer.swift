import BlissTheme
import ComposableArchitecture
import Demark
import Dependencies
import DependenciesAdditions
import HtmlToMarkdownClient
import InputOutput
import SharedModels
import SwiftUI
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
        @Shared(.urlToMarkdownIO) public var storage = ToolIOStorage()
        @Shared(.urlToMarkdownConfig) public var configuration = HtmlToMarkdownConfig()
        @Shared(.urlLoadingConfig) public var loadingConfiguration = UrlLoadingConfig()
        public var output: OutputEditorReducer.State
        var isConversionRequestInFlight = false
        var errorMessage: String?

        // URL input is derived from storage.input for persistence
        public var urlInput: String {
            get { storage.input }
            set { $storage.withLock { $0.input = newValue } }
        }

        public init(
            configuration: HtmlToMarkdownConfig = .init(),
            loadingConfiguration: UrlLoadingConfig = .init()
        ) {
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(), .urlToMarkdownIO)
            self.output = OutputEditorReducer.State(text: sharedStorage.output)
            self.isConversionRequestInFlight = false
        }

        public var outputText: String {
            output.text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case output(OutputEditorReducer.Action)
    }

    @Dependency(\.urlToMarkdown) var urlToMarkdown
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
                                    try await urlToMarkdown.convert(url, config, loadingConfig)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                return state.output.updateText(result)
                    .map { Action.output($0) }
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.errorMessage = error.localizedDescription
                return state.output.updateText(error.localizedDescription)
                    .map { Action.output($0) }
            case .output:
                return .none
            }
        }

        Scope(state: \.output, action: \.output) {
            OutputEditorReducer()
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

            // Configuration panel - collapsible secondary controls
            ConfigurationSection("Conversion Options") {
                configurationGrid
            }

            Divider()
                .padding(.top, 4)

            OutputEditorView(
                store: store.scope(state: \.output, action: \.output),
                title: "Markdown Output"
            )
        }
    }

    @ViewBuilder
    private var configurationGrid: some View {
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

            // Row 3: Content Selector - aligned with grid columns above
            GridRow {
                ConfigLabel("Content Selector")
                TextField("e.g., article, main, .content", text: $store.loadingConfiguration.contentSelector)
                    .blissCompactTextField()
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
