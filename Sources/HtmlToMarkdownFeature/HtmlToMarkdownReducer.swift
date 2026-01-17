import ComposableArchitecture
import Demark
import Dependencies
import DependenciesAdditions
import HtmlToMarkdownClient
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct HtmlToMarkdownReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.htmlToMarkdownIO) var storage = ToolIOStorage()
        public var inputOutput: InputOutputEditorsReducer.State
        public var configuration: HtmlToMarkdownConfig
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
            self.configuration = configuration
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
            self.configuration = .init()
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
        VStack {
            // Configuration UI above the text editors
            VStack(spacing: 12) {
                // Engine picker
                HStack {
                    Text("Engine:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("Engine", selection: $store.configuration.engine) {
                        Text("Turndown (Accurate)").tag(ConversionEngine.turndown)
                        Text("html-to-md (Fast)").tag(ConversionEngine.htmlToMd)
                    }
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
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    Spacer()
                }
                .help("Fenced uses triple backticks, Indented uses 4 spaces")
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxWidth: 850)

            Button(action: { store.send(.convertButtonTouched) }) {
                Text("Convert")
                    .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert HTML to Markdown (Cmd+Return)")
            .padding(.top, 8)

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
