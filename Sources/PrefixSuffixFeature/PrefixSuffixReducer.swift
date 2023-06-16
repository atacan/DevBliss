import ComposableArchitecture
import Dependencies
import InputOutput
import PrefixSuffixClient
import SwiftUI

public struct PrefixSuffixReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        @BindingState var configuration: PrefixSuffixConfig
        var isConversionRequestInFlight = false

        public init(
            inputOutput: InputOutputEditorsReducer.State = .init(),
            configuration: PrefixSuffixConfig = .init()
        ) {
            self.inputOutput = inputOutput
            self.configuration = configuration
        }

        public init(input: String, output: String = "") {
            self.inputOutput = .init(input: .init(text: input), output: .init(text: output))
            self.configuration = .init()
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

    @Dependency(\.prefixSuffix) var prefixSuffix
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
                    .run { [input = state.inputOutput.input.text, config = state.configuration] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await prefixSuffix.convert(input, config)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/1952#discussioncomment-5167956
                return state.inputOutput.output.updateText(result)
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

public struct PrefixSuffixView: View {
    let store: StoreOf<PrefixSuffixReducer>
    @ObservedObject var viewStore: ViewStoreOf<PrefixSuffixReducer>

    public init(store: StoreOf<PrefixSuffixReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            VStack(alignment: .center) {
                HStack{
                    Text("Prefix")
                    TextField("Replace prefix", text: viewStore.binding(\.$configuration.prefixReplace))
                        .font(.monospaced(.body)())
                        .help("Replace prefix if available")
                    TextField("with", text: viewStore.binding(\.$configuration.prefixReplaceWith))
                        .font(.monospaced(.body)())
                        .help("the prefix written previously will be replaced with this")
                    TextField("Then add Prefix", text: viewStore.binding(\.$configuration.prefixAdd))
                        .font(.monospaced(.body)())
                        .help("Then add Prefix")
                }
                
                HStack{
                    Text("Suffix")
                    TextField("Replace suffix", text: viewStore.binding(\.$configuration.suffixReplace))
                        .font(.monospaced(.body)())
                        .help("Replace suffix if available")
                    TextField("with", text: viewStore.binding(\.$configuration.suffixReplaceWith))
                        .font(.monospaced(.body)())
                        .help("the suffix written previously will be replaced with this")
                    TextField("Then add Suffix", text: viewStore.binding(\.$configuration.suffixAdd))
                        .font(.monospaced(.body)())
                        .help("Then add Suffix")
                }
            }  // <-HStack
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .frame(maxWidth: 850)

            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text("Convert")
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: PrefixSuffixReducer.Action.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Output"
            )
        }
    }
}

// preview
struct PrefixSuffixReducer_Previews: PreviewProvider {
    static var previews: some View {
        PrefixSuffixView(store: .init(initialState: .init(), reducer: PrefixSuffixReducer()))
    }
}
