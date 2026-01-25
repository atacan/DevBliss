import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI
import XmlFormatClient

@Reducer
public struct XmlFormatReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("xmlFormat")) public var inputText = ""
        @Shared(.toolOutput("xmlFormat")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var mode: XmlFormatMode = .beautify

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("xmlFormat"))
            let outputText = Shared(wrappedValue: "", .toolOutput("xmlFormat"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("xmlFormat"))
            let outputText = Shared(wrappedValue: output, .toolOutput("xmlFormat"))
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

    @Dependency(\.xmlFormat) var xmlFormat
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
                return .run { [xmlFormat] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await xmlFormat.format(input, mode)
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

public struct XmlFormatView: View {
    @Bindable var store: StoreOf<XmlFormatReducer>

    public init(store: StoreOf<XmlFormatReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
//                    ConfigLabel("Mode")
                    Picker("Mode", selection: $store.mode) {
                        ForEach(XmlFormatMode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Format", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Format (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "XML",
                outputEditorTitle: "Result",
                keyForFraction: SettingsKey.XmlFormat.splitViewFraction,
                keyForLayout: SettingsKey.XmlFormat.splitViewLayout
            )
        }
    }
}

struct XmlFormatView_Previews: PreviewProvider {
    static var previews: some View {
        XmlFormatView(store: .init(initialState: .init()) { XmlFormatReducer() })
    }
}
