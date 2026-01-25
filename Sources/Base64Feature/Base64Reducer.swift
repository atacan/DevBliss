import Base64Client
import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct Base64Reducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("base64")) public var inputText = ""
        @Shared(.toolOutput("base64")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var mode: Base64Mode = .encode
        var autoDetect: Bool = true
        var autoRemoveDataURLPrefix: Bool = true
        var autoRemoveNullBytes: Bool = true

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("base64"))
            let outputText = Shared(wrappedValue: "", .toolOutput("base64"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("base64"))
            let outputText = Shared(wrappedValue: output, .toolOutput("base64"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        var config: Base64Config {
            Base64Config(
                autoDetect: autoDetect,
                autoRemoveDataURLPrefix: autoRemoveDataURLPrefix,
                autoRemoveNullBytes: autoRemoveNullBytes
            )
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.base64) var base64
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
                let config = state.config
                return .run { [base64] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                switch mode {
                                case .encode:
                                    return try await base64.encode(input)
                                case .decode:
                                    return try await base64.decode(input, config)
                                }
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

public struct Base64View: View {
    @Bindable var store: StoreOf<Base64Reducer>

    public init(store: StoreOf<Base64Reducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mode selection and options
            Grid(horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
//                    ConfigLabel("Mode")
                    Picker("Mode", selection: $store.mode) {
                        ForEach(Base64Mode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                GridRow {
//                    ConfigLabel("Options")
                    HStack(spacing: 16) {
                        Toggle("Auto-detect", isOn: $store.autoDetect)
                            .help("Automatically detect if input is Base64 and switch mode")

                        Toggle("Strip data URL", isOn: $store.autoRemoveDataURLPrefix)
                            .help("Remove data:...;base64, prefix when decoding")

                        Toggle("Strip null bytes", isOn: $store.autoRemoveNullBytes)
                            .help("Remove null bytes at the end of decoded string")
                    }
                    .toggleStyle(.checkbox)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Convert button
            LoadingButton(
                store.mode == .encode ? "Encode" : "Decode",
                isLoading: store.isConversionRequestInFlight
            ) {
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
                keyForFraction: SettingsKey.Base64.splitViewFraction,
                keyForLayout: SettingsKey.Base64.splitViewLayout
            )
        }
    }
}

// MARK: - Preview

struct Base64Reducer_Previews: PreviewProvider {
    static var previews: some View {
        Base64View(store: .init(initialState: .init()) { Base64Reducer() })
    }
}
