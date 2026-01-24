import BlissTheme
import ComposableArchitecture
import HexToAsciiClient
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct HexToAsciiReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.hexToAsciiIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var allowSeparators: Bool = true

        public init() {
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .hexToAsciiIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        var config: HexToAsciiConfig {
            HexToAsciiConfig(allowSeparators: allowSeparators)
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

    @Dependency(\.hexToAscii) var hexToAscii
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
                let config = state.config
                return .run { [hexToAscii] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await hexToAscii.convert(input, config)
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

public struct HexToAsciiView: View {
    @Bindable var store: StoreOf<HexToAsciiReducer>

    public init(store: StoreOf<HexToAsciiReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
//                    ConfigLabel("Options")
                    Toggle("Allow separators", isOn: $store.allowSeparators)
                        .toggleStyle(.checkbox)
                        .help("Allow spaces, commas, colons, and 0x prefixes")
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
                inputEditorTitle: "Hex",
                outputEditorTitle: "ASCII",
                keyForFraction: SettingsKey.HexToAscii.splitViewFraction,
                keyForLayout: SettingsKey.HexToAscii.splitViewLayout
            )
        }
    }
}

struct HexToAsciiView_Previews: PreviewProvider {
    static var previews: some View {
        HexToAsciiView(store: .init(initialState: .init()) { HexToAsciiReducer() })
    }
}
