import BlissTheme
import ComposableArchitecture
import InputOutput
import JsonToYamlClient
import SharedModels
import SwiftUI

@Reducer
public struct JsonToYamlReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.jsonToYamlIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var sortKeys: Bool = false

        public init() {
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .jsonToYamlIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        var config: JsonToYamlConfig {
            JsonToYamlConfig(sortKeys: sortKeys)
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

    @Dependency(\.jsonToYaml) var jsonToYaml
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
                return .run { [jsonToYaml] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await jsonToYaml.convert(input, config)
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

public struct JsonToYamlView: View {
    @Bindable var store: StoreOf<JsonToYamlReducer>

    public init(store: StoreOf<JsonToYamlReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Options")
                    Toggle("Sort keys", isOn: $store.sortKeys)
                        .toggleStyle(.checkbox)
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
                inputEditorTitle: "JSON",
                outputEditorTitle: "YAML",
                keyForFraction: SettingsKey.JsonToYaml.splitViewFraction,
                keyForLayout: SettingsKey.JsonToYaml.splitViewLayout
            )
        }
    }
}

struct JsonToYamlView_Previews: PreviewProvider {
    static var previews: some View {
        JsonToYamlView(store: .init(initialState: .init()) { JsonToYamlReducer() })
    }
}
