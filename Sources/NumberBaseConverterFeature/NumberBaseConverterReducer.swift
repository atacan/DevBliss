import BlissTheme
import ComposableArchitecture
import InputOutput
import NumberBaseConverterClient
import SharedModels
import SwiftUI

@Reducer
public struct NumberBaseConverterReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.numberBaseConverterIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputEditorsReducer.State
        var fromBase: NumberBase = .decimal
        var isConversionRequestInFlight = false
        var errorMessage: String?

        public init() {
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .numberBaseConverterIO)
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
        case conversionResponse(TaskResult<NumberBaseResult>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.numberBaseConverter) var numberBaseConverter
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.errorMessage = nil
                state.isConversionRequestInFlight = true
                let input = state.inputOutput.input.text
                let fromBase = state.fromBase
                return .run { [numberBaseConverter] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await numberBaseConverter.convert(input, fromBase)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                let output = format(result: result)
                return state.inputOutput.output.updateText(output)
                    .map { Action.inputOutput(.output($0)) }

            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.errorMessage = error.localizedDescription
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

    private func format(result: NumberBaseResult) -> String {
        [
            "Binary: \(result.binary)",
            "Octal: \(result.octal)",
            "Decimal: \(result.decimal)",
            "Hex: \(result.hex)",
        ]
        .joined(separator: "\n")
    }
}

public struct NumberBaseConverterView: View {
    @Bindable var store: StoreOf<NumberBaseConverterReducer>

    public init(store: StoreOf<NumberBaseConverterReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Input Base")
                    Picker("Base", selection: $store.fromBase) {
                        ForEach(NumberBase.allCases) { base in
                            Text(base.label)
                                .tag(base)
                        }
                    }
                    .blissMenuPicker(width: 140)
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

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Converted",
                keyForFraction: SettingsKey.NumberBaseConverter.splitViewFraction,
                keyForLayout: SettingsKey.NumberBaseConverter.splitViewLayout
            )
        }
    }
}

struct NumberBaseConverterView_Previews: PreviewProvider {
    static var previews: some View {
        NumberBaseConverterView(store: .init(initialState: .init()) { NumberBaseConverterReducer() })
    }
}
