import BlissTheme
import ComposableArchitecture
import Dependencies
import InputOutput
import JsonPrettyClient
import SharedModels
import SwiftUI

@Reducer
public struct JsonPrettyReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared(.jsonPrettyIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputAttributedEditorsReducer.State
        var isConversionRequestInFlight = false

        public init() {
            // Initialize inputOutput with default, then update to use shared references
            let storage = Shared<ToolIOStorage>.init(wrappedValue: ToolIOStorage(), .jsonPrettyIO)
            self._storage = storage
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: storage.input,
                outputRawText: storage.output
            )
        }

        public init(input: String, output: String = "") {
            let storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .jsonPrettyIO)
            self._storage = storage
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: storage.input,
                outputRawText: storage.output
            )
        }

        public var outputText: String {
            inputOutput.output.text.string
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<NSAttributedString>)
        case inputOutput(InputOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.jsonPretty) var jsonPretty
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                return
                    .run { [input = state.inputOutput.input] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await jsonPretty.convert(input.text)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(swiftCode)):
                state.isConversionRequestInFlight = false
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/1952#discussioncomment-5167956
                return state.inputOutput.output.updateText(swiftCode)
                    .map { Action.inputOutput(.output($0)) }
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                let attributedString = errorAttributedString("\(error)")
                return state.inputOutput.output.updateText(attributedString)
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

public struct JsonPrettyView: View {
    @Bindable var store: StoreOf<JsonPrettyReducer>

    public init(store: StoreOf<JsonPrettyReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            Button(action: { store.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Format", bundle: Bundle.module, comment: ""))
                    .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Format code (Cmd+Return)", bundle: Bundle.module, comment: ""))

            InputOutputAttributedEditorsView(
                store: store.scope(state: \.inputOutput, action: JsonPrettyReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Raw", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Pretty", bundle: Bundle.module, comment: ""),
                keyForFraction: SettingsKey.JsonPretty.splitViewFraction,
                keyForLayout: SettingsKey.JsonPretty.splitViewLayout
            )
        }
    }
}

// preview
struct JsonPrettyReducer_Previews: PreviewProvider {
    static var previews: some View {
        JsonPrettyView(store: .init(initialState: .init()) { JsonPrettyReducer() })
    }
}
