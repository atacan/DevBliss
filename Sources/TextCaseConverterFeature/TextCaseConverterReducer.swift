import ComposableArchitecture
import Dependencies
import InputOutput
import SwiftUI
import TextCaseConverterClient

public struct TextCaseConverterReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        @BindingState var sourceCase: WordGroupCase
        @BindingState var targetCase: WordGroupCase
        @BindingState var textSeperator: WordGroupSeperator

        public init(
            inputOutput: InputOutputEditorsReducer.State = .init(),
            sourceCase: WordGroupCase = .kebab,
            targetCase: WordGroupCase = .snake,
            textSeperator: WordGroupSeperator = .newLine
        ) {
            self.inputOutput = inputOutput
            self.sourceCase = sourceCase
            self.targetCase = targetCase
            self.textSeperator = textSeperator
        }

        public init(input: String, output: String = "") {
            self.init()
            self.inputOutput = .init(input: .init(text: input), output: .init(text: output))
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

    @Dependency(\.textCaseConverter) var textCaseConverter
    private enum CancelID { case conversionRequest }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                return
                    .run {
                        [
                            input = state.inputOutput.input,
                            sourceCase = state.sourceCase,
                            targetCase = state.targetCase
                        ] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await textCaseConverter.convert(input.text, .newLine, sourceCase, targetCase)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(swiftCode)):
                state.isConversionRequestInFlight = false
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/1952#discussioncomment-5167956
                return state.inputOutput.output.updateText(swiftCode)
                    .map { Action.inputOutput(.output($0)) }
            case .conversionResponse(.failure):
                state.isConversionRequestInFlight = false
                return .none
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputEditorsReducer()
        }
    }
}

public struct TextCaseConverterView: View {
    let store: StoreOf<TextCaseConverterReducer>
    @ObservedObject var viewStore: ViewStoreOf<TextCaseConverterReducer>

    public init(store: StoreOf<TextCaseConverterReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                Picker("From", selection: viewStore.binding(\.$sourceCase)) {
                    ForEach(WordGroupCase.allCases) { sourceCase in
                        Text(sourceCase.rawValue)
                            .tag(sourceCase)
                    }
                }
                Picker("To", selection: viewStore.binding(\.$targetCase)) {
                    ForEach(WordGroupCase.allCases) { targetCase in
                        Text(targetCase.rawValue)
                            .tag(targetCase)
                    }
                }
                Picker("Separator", selection: viewStore.binding(\.$textSeperator)) {
                    ForEach(WordGroupSeperator.allCases) { textSeperator in
                        Text(textSeperator.name)
                            .tag(textSeperator)
                    }
                }
                Spacer()
            }  // <-HStack
            .frame(maxWidth: 550)

            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text("Convert")
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: TextCaseConverterReducer.Action.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Output"
            )
        }
    }
}

// preview
struct TextCaseConverterReducer_Previews: PreviewProvider {
    static var previews: some View {
        TextCaseConverterView(store: .init(initialState: .init(), reducer: TextCaseConverterReducer()))
    }
}
