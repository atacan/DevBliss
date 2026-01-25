import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI
import YamlToJsonClient

@Reducer
public struct YamlToJsonReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("yamlToJson")) public var inputText = ""
        @Shared(.toolOutput("yamlToJson")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var prettyPrinted: Bool = true

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("yamlToJson"))
            let outputText = Shared(wrappedValue: "", .toolOutput("yamlToJson"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("yamlToJson"))
            let outputText = Shared(wrappedValue: output, .toolOutput("yamlToJson"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        var config: YamlToJsonConfig {
            YamlToJsonConfig(prettyPrinted: prettyPrinted)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.yamlToJson) var yamlToJson
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
                return .run { [yamlToJson] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await yamlToJson.convert(input, config)
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

public struct YamlToJsonView: View {
    @Bindable var store: StoreOf<YamlToJsonReducer>

    public init(store: StoreOf<YamlToJsonReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
//            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
//                GridRow {
//                    ConfigLabel("Options")
//                    Toggle("Pretty printed", isOn: $store.prettyPrinted)
//                        .toggleStyle(.checkbox)
//                    Spacer()
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)

            LoadingButton("Convert", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "YAML",
                outputEditorTitle: "JSON",
                keyForFraction: SettingsKey.YamlToJson.splitViewFraction,
                keyForLayout: SettingsKey.YamlToJson.splitViewLayout
            )
        }
    }
}

struct YamlToJsonView_Previews: PreviewProvider {
    static var previews: some View {
        YamlToJsonView(store: .init(initialState: .init()) { YamlToJsonReducer() })
    }
}
