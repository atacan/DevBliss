import BlissTheme
import ComposableArchitecture
import CssBeautifyClient
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct CssBeautifyReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("cssBeautify")) public var inputText = ""
        @Shared(.toolOutput("cssBeautify")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var mode: CssBeautifyMode = .beautify

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("cssBeautify"))
            let outputText = Shared(wrappedValue: "", .toolOutput("cssBeautify"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("cssBeautify"))
            let outputText = Shared(wrappedValue: output, .toolOutput("cssBeautify"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.cssBeautify) var cssBeautify
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
                return .run { [cssBeautify] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await cssBeautify.format(input, mode)
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

public struct CssBeautifyView: View {
    @Bindable var store: StoreOf<CssBeautifyReducer>

    public init(store: StoreOf<CssBeautifyReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
//            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
//                GridRow {
//                    ConfigLabel("Mode")
//                    Picker("Mode", selection: $store.mode) {
//                        ForEach(CssBeautifyMode.allCases) { mode in
//                            Text(mode.rawValue)
//                                .tag(mode)
//                        }
//                    }
//                    .labelsHidden()
//                    .pickerStyle(.segmented)
//                    .frame(width: 200)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)

            LoadingButton(store.mode == .beautify ? "Beautify" : "Minify", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Format (Cmd Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "CSS",
                outputEditorTitle: "Result",
                keyForFraction: SettingsKey.CssBeautify.splitViewFraction,
                keyForLayout: SettingsKey.CssBeautify.splitViewLayout
            )
        }
    }
}

struct CssBeautifyView_Previews: PreviewProvider {
    static var previews: some View {
        CssBeautifyView(store: .init(initialState: .init()) { CssBeautifyReducer() })
    }
}
