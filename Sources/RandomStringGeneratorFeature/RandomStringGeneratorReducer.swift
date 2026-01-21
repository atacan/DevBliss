import BlissTheme
import ComposableArchitecture
import InputOutput
import RandomStringGeneratorClient
import SharedModels
import SwiftUI

@Reducer
public struct RandomStringGeneratorReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.randomStringGeneratorIO) public var storage = ToolIOStorage()
        var output: OutputEditorReducer.State
        var length: Int = 16
        var includeLowercase: Bool = true
        var includeUppercase: Bool = true
        var includeDigits: Bool = true
        var includeSymbols: Bool = false
        var errorMessage: String?

        public init() {
            self.output = OutputEditorReducer.State(text: _storage.projectedValue.output)
        }

        public init(output: String) {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: "", output: output), .randomStringGeneratorIO)
            self.output = OutputEditorReducer.State(text: _storage.projectedValue.output)
        }

        var config: RandomStringConfig {
            RandomStringConfig(
                includeLowercase: includeLowercase,
                includeUppercase: includeUppercase,
                includeDigits: includeDigits,
                includeSymbols: includeSymbols
            )
        }

        public var outputText: String {
            output.text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case generateButtonTouched
        case generationResponse(TaskResult<String>)
        case output(OutputEditorReducer.Action)
    }

    @Dependency(\.randomStringGenerator) var randomStringGenerator
    private enum CancelID { case generationRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .generateButtonTouched:
                state.errorMessage = nil
                let length = state.length
                let config = state.config
                return .run { [randomStringGenerator] send in
                    await send(
                        .generationResponse(
                            TaskResult {
                                try await randomStringGenerator.generate(length, config)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.generationRequest, cancelInFlight: true)

            case let .generationResponse(.success(result)):
                return state.output.updateText(result)
                    .map { Action.output($0) }

            case let .generationResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .output:
                return .none
            }
        }

        Scope(state: \.output, action: \.output) {
            OutputEditorReducer()
        }
    }
}

public struct RandomStringGeneratorView: View {
    @Bindable var store: StoreOf<RandomStringGeneratorReducer>

    public init(store: StoreOf<RandomStringGeneratorReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Length")
                    Stepper(value: $store.length, in: 1...256) {
                        Text("\(store.length)")
                            .frame(width: 50, alignment: .leading)
                    }

                    Spacer()
                }

                GridRow {
                    ConfigLabel("Include")
                    HStack(spacing: 16) {
                        Toggle("Lowercase", isOn: $store.includeLowercase)
                        Toggle("Uppercase", isOn: $store.includeUppercase)
                        Toggle("Digits", isOn: $store.includeDigits)
                        Toggle("Symbols", isOn: $store.includeSymbols)
                    }
                    .toggleStyle(.checkbox)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Generate", isLoading: false) {
                store.send(.generateButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Generate (⌘ Return)")
            .padding(.vertical, 8)

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            OutputEditorView(store: store.scope(state: \.output, action: \.output))
        }
    }
}

struct RandomStringGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        RandomStringGeneratorView(store: .init(initialState: .init()) { RandomStringGeneratorReducer() })
    }
}
