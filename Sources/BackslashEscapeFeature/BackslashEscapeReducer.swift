import BackslashEscapeClient
import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct BackslashEscapeReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.backslashEscapeIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var mode: BackslashEscapeMode = .escape

        public init() {
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .backslashEscapeIO)
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

    @Dependency(\.backslashEscape) var backslashEscape
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
                return .run { [backslashEscape] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await backslashEscape.convert(input, mode)
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

public struct BackslashEscapeView: View {
    @Bindable var store: StoreOf<BackslashEscapeReducer>

    public init(store: StoreOf<BackslashEscapeReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    Picker("Mode", selection: $store.mode) {
                        ForEach(BackslashEscapeMode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Convert", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Output",
                keyForFraction: SettingsKey.BackslashEscape.splitViewFraction,
                keyForLayout: SettingsKey.BackslashEscape.splitViewLayout
            )
        }
    }
}

struct BackslashEscapeView_Previews: PreviewProvider {
    static var previews: some View {
        BackslashEscapeView(store: .init(initialState: .init()) { BackslashEscapeReducer() })
    }
}
