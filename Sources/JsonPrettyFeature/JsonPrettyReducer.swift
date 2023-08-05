import BlissTheme
import ComposableArchitecture
import Dependencies
import InputOutput
import JsonPrettyClient
import SwiftUI

public struct JsonPrettyReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputAttributedEditorsReducer.State
        var isConversionRequestInFlight = false

        public init(inputOutput: InputOutputAttributedEditorsReducer.State = .init()) {
            self.inputOutput = inputOutput
        }

        public init(input: String, output: String = "") {
            self.inputOutput = .init(input: .init(text: input), output: .init(text: .init(string: output)))
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

    public var body: some ReducerProtocol<State, Action> {
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

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputAttributedEditorsReducer()
        }
    }
}

public struct JsonPrettyView: View {
    let store: StoreOf<JsonPrettyReducer>
    @ObservedObject var viewStore: ViewStoreOf<JsonPrettyReducer>

    public init(store: StoreOf<JsonPrettyReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Format", bundle: Bundle.module, comment: ""))
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Format code (Cmd+Return)", bundle: Bundle.module, comment: ""))

            InputOutputAttributedEditorsView(
                store: store.scope(state: \.inputOutput, action: JsonPrettyReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Raw", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Pretty", bundle: Bundle.module, comment: "")
            )
        }
    }
}

// preview
struct JsonPrettyReducer_Previews: PreviewProvider {
    static var previews: some View {
        JsonPrettyView(store: .init(initialState: .init(), reducer: JsonPrettyReducer()))
    }
}
