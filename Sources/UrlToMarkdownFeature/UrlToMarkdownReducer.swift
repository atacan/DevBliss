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
        VStack {
            // URL input field
            HStack {
                Text("URL:")
                    .frame(width: 50, alignment: .trailing)
                TextField("Enter URL to convert", text: $store.urlInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        store.send(.convertButtonTouched)
                    }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Configuration UI
            VStack(spacing: 12) {
                // Engine picker
                HStack {
                    Text("Engine:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("Engine", selection: $store.configuration.engine) {
                        Text("Turndown (Accurate)").tag(ConversionEngine.turndown)
                        Text("html-to-md (Fast)").tag(ConversionEngine.htmlToMd)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    Spacer()
                }
                .help("Choose conversion engine: Turndown for complex HTML, html-to-md for speed")

                // Heading style picker
                HStack {
                    Text("Heading Style:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("Heading Style", selection: $store.configuration.headingStyle) {
                        Text("ATX (# Heading)").tag(DemarkHeadingStyle.atx)
                        Text("Setext (Underline)").tag(DemarkHeadingStyle.setext)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    Spacer()
                }
                .help("ATX uses # prefix, Setext uses underlines")

                // Bullet list marker picker
                HStack {
                    Text("Bullet Marker:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("Bullet Marker", selection: $store.configuration.bulletListMarker) {
                        Text("Dash (-)").tag("-")
                        Text("Asterisk (*)").tag("*")
                        Text("Plus (+)").tag("+")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    Spacer()
                }
                .help("Choose character for unordered list items")

                // Code block style picker
                HStack {
                    Text("Code Block Style:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("Code Block Style", selection: $store.configuration.codeBlockStyle) {
                        Text("Fenced (```)").tag(DemarkCodeBlockStyle.fenced)
                        Text("Indented").tag(DemarkCodeBlockStyle.indented)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    Spacer()
                }
                .help("Fenced uses triple backticks, Indented uses 4 spaces")

                // Content selector
                HStack {
                    Text("Content Selector:")
                        .frame(width: 140, alignment: .trailing)
                    TextField("e.g., article, main, .content", text: $store.loadingConfiguration.contentSelector)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                    Spacer()
                }
                .help("CSS selector to extract specific content (leave empty for full page)")
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxWidth: 850)

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Button(action: { store.send(.convertButtonTouched) }) {
                Text("Convert")
                    .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert URL to Markdown (Cmd+Return)")
            .disabled(store.urlInput.isEmpty || store.isConversionRequestInFlight)
            .padding(.top, 8)

            OutputEditorView(
                store: store.scope(state: \.output, action: \.output),
                title: "Markdown Output"
            )
        }
    }
}

// Preview
struct UrlToMarkdownReducer_Previews: PreviewProvider {
    static var previews: some View {
        UrlToMarkdownView(store: .init(initialState: .init()) { UrlToMarkdownReducer() })
    }
}
