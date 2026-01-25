import BlissTheme
import ComposableArchitecture
import HashGeneratorClient
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct HashGeneratorReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("hashGenerator")) public var inputText = ""
        @Shared(.toolOutput("hashGenerator")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var uppercase: Bool = false

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("hashGenerator"))
            let outputText = Shared(wrappedValue: "", .toolOutput("hashGenerator"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("hashGenerator"))
            let outputText = Shared(wrappedValue: output, .toolOutput("hashGenerator"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        var config: HashGeneratorConfig {
            HashGeneratorConfig(uppercase: uppercase)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<HashGeneratorResult>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.hashGenerator) var hashGenerator
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
                return .run { [hashGenerator] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await hashGenerator.hashes(input, config)
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

    private func format(result: HashGeneratorResult) -> String {
        [
            "MD5: \(result.md5)",
            "SHA1: \(result.sha1)",
            "SHA256: \(result.sha256)",
            "SHA384: \(result.sha384)",
            "SHA512: \(result.sha512)",
        ]
        .joined(separator: "\n")
    }
}

public struct HashGeneratorView: View {
    @Bindable var store: StoreOf<HashGeneratorReducer>

    public init(store: StoreOf<HashGeneratorReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
//                    ConfigLabel("Format")
                    Toggle("Uppercase", isOn: $store.uppercase)
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Generate", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Generate (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Hashes",
                keyForFraction: SettingsKey.HashGenerator.splitViewFraction,
                keyForLayout: SettingsKey.HashGenerator.splitViewLayout
            )
        }
    }
}

struct HashGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        HashGeneratorView(store: .init(initialState: .init()) { HashGeneratorReducer() })
    }
}
