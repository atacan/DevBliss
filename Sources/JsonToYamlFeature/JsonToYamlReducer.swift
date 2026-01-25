import BlissTheme
import ComposableArchitecture
import Foundation
import InputOutput
import JsonToYamlClient
import SharedModels
import SwiftUI
import SyntaxHighlightClient

@Reducer
public struct JsonToYamlReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("jsonToYaml")) public var inputText = ""
        @Shared(.toolOutput("jsonToYaml")) public var outputText = ""
        var inputOutput: InputOutputAttributedEditorsReducer.State
        var isConversionRequestInFlight = false
        var sortKeys: Bool = false

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("jsonToYaml"))
            let outputText = Shared(wrappedValue: "", .toolOutput("jsonToYaml"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputRawText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("jsonToYaml"))
            let outputText = Shared(wrappedValue: output, .toolOutput("jsonToYaml"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputRawText: outputText.projectedValue
            )
        }

        var config: JsonToYamlConfig {
            JsonToYamlConfig(sortKeys: sortKeys)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<NSAttributedString>)
        case inputOutput(InputOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.jsonToYaml) var jsonToYaml
    @Dependency(\.syntaxHighlight) var syntaxHighlight
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
                return .run { [jsonToYaml, syntaxHighlight] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                let yaml = try await jsonToYaml.convert(input, config)
                                let highlighted = await syntaxHighlight.highlightYaml(yaml)
                                return highlighted
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(highlighted)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(highlighted)
                    .map { Action.inputOutput(.output($0)) }

            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(errorAttributedString(error.localizedDescription))
                    .map { Action.inputOutput(.output($0)) }

            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: \.inputOutput) {
            InputOutputAttributedEditorsReducer()
        }
    }
}

public struct JsonToYamlView: View {
    @Perception.Bindable var store: StoreOf<JsonToYamlReducer>

    public init(store: StoreOf<JsonToYamlReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
//            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
//                GridRow {
//                    ConfigLabel("Options")
//                    Toggle("Sort keys", isOn: $store.sortKeys)
#if os(macOS)
//                        .toggleStyle(.checkbox)
#endif
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

            InputOutputAttributedEditorsView(
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
