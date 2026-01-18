import BlissTheme
import ComposableArchitecture
import Demark
import Dependencies
import DependenciesAdditions
import HtmlToMarkdownClient
import InputOutput
import SharedModels
import SwiftUI

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
        @Shared(.htmlToMarkdownIO) public var storage = ToolIOStorage()
        @Shared(.htmlToMarkdownConfig) public var configuration = HtmlToMarkdownConfig()
        public var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false

        public init(
            inputOutput: InputOutputEditorsReducer.State = .init(),
            configuration: HtmlToMarkdownConfig = .init()
        ) {
            // Initialize inputOutput using derived shared refs from storage
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(), .htmlToMarkdownIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: sharedStorage.input,
                outputText: sharedStorage.output
            )

            self.isConversionRequestInFlight = false
            // Configuration is loaded from file storage automatically via @Shared
        }

        public init(input: String, output: String = "") {
            // Initialize @Shared storage with provided values
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .htmlToMarkdownIO)

            // Initialize inputOutput using derived shared refs
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .htmlToMarkdownIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: sharedStorage.input,
                outputText: sharedStorage.output
            )

            self.isConversionRequestInFlight = false
            // Configuration is loaded from file storage automatically via @Shared
        }

        public var outputText: String {
            inputOutput.output.text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.htmlToMarkdown) var htmlToMarkdown
    private enum CancelID { case conversionRequest }
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

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(result)
                    .map { Action.inputOutput(.output($0)) }
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(error.localizedDescription)
                    .map { Action.inputOutput(.output($0)) }
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: \.inputOutput) {
            InputOutputEditorsReducer()
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
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: HtmlToMarkdownReducer.Action.inputOutput),
                inputEditorTitle: "HTML Input",
                outputEditorTitle: "Markdown Output",
                keyForFraction: SettingsKey.HtmlToMarkdown.splitViewFraction,
                keyForLayout: SettingsKey.HtmlToMarkdown.splitViewLayout
            )
        }
    }
}

// Preview
struct HtmlToMarkdownReducer_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToMarkdownView(store: .init(initialState: .init()) { HtmlToMarkdownReducer() })
    }
}
