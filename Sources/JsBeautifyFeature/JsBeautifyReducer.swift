import BlissTheme
import ComposableArchitecture
import InputOutput
import JsBeautifyClient
import SharedModels
import SwiftUI

@Reducer
public struct JsBeautifyReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.jsBeautifyIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var mode: JsBeautifyMode = .beautify

        public init() {
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .jsBeautifyIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
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

    @Dependency(\.jsBeautify) var jsBeautify
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                let input = state.inputOutput.input.text
                let mode = state.mode
                return .run { [jsBeautify] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await jsBeautify.format(input, mode)
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

public struct JsBeautifyView: View {
    @Bindable var store: StoreOf<JsBeautifyReducer>

    public init(store: StoreOf<JsBeautifyReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
//            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
//                GridRow {
//                    ConfigLabel("Mode")
//                    Picker("Mode", selection: $store.mode) {
//                        ForEach(JsBeautifyMode.allCases) { mode in
//                            Text(mode.rawValue)
//                                .tag(mode)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                    .frame(width: 200)
//
//                    Spacer()
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)

            LoadingButton(store.mode == .beautify ? "Format" : "Minify", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Format (Cmd Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "JavaScript",
                outputEditorTitle: "Result",
                keyForFraction: SettingsKey.JsBeautify.splitViewFraction,
                keyForLayout: SettingsKey.JsBeautify.splitViewLayout
            )
        }
    }
}

struct JsBeautifyView_Previews: PreviewProvider {
    static var previews: some View {
        JsBeautifyView(store: .init(initialState: .init()) { JsBeautifyReducer() })
    }
}
