import AsciiToHexClient
import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct AsciiToHexReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("asciiToHex")) public var inputText = ""
        @Shared(.toolOutput("asciiToHex")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var uppercase: Bool = true
        var separator: HexSeparator = .space

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("asciiToHex"))
            let outputText = Shared(wrappedValue: "", .toolOutput("asciiToHex"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("asciiToHex"))
            let outputText = Shared(wrappedValue: output, .toolOutput("asciiToHex"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        var config: AsciiToHexConfig {
            AsciiToHexConfig(uppercase: uppercase, separator: separator)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.asciiToHex) var asciiToHex
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
                return .run { [asciiToHex] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await asciiToHex.convert(input, config)
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

public struct AsciiToHexView: View {
    @Bindable var store: StoreOf<AsciiToHexReducer>

    public init(store: StoreOf<AsciiToHexReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Separator")

                    Picker("Separator", selection: $store.separator) {
                        ForEach(HexSeparator.allCases) { separator in
                            Text(separator.rawValue)
                                .tag(separator)
                        }
                    }
                    .blissMenuPicker(width: 120)

                    Toggle("Uppercase", isOn: $store.uppercase)
                        .toggleStyle(.checkbox)

//                    Spacer()
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
                inputEditorTitle: "ASCII",
                outputEditorTitle: "Hex",
                keyForFraction: SettingsKey.AsciiToHex.splitViewFraction,
                keyForLayout: SettingsKey.AsciiToHex.splitViewLayout
            )
        }
    }
}

struct AsciiToHexView_Previews: PreviewProvider {
    static var previews: some View {
        AsciiToHexView(store: .init(initialState: .init()) { AsciiToHexReducer() })
    }
}
