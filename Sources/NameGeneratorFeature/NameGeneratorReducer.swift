import ComposableArchitecture
import InputOutput
import NameGeneratorClient
import SplitView
import SwiftUI

public enum GenerationType {
    case prefixSuffix
    case alternatingVowelsConsonants
    case probabilistic
}

public struct NameGeneratorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState var generationType: GenerationType
        var prefixSuffix: NameGeneratorPrefixSuffixReducer.State
        var alternatingVowelsConsonants: NameGeneratorAlternatingReducer.State
        var probabilistic: NameGeneratorProbabilisticReducer.State
        var output: OutputEditorReducer.State

        public init(
            generationType: GenerationType = .probabilistic,
            prefixSuffix: NameGeneratorPrefixSuffixReducer.State = .init(),
            alternatingVowelsConsonants: NameGeneratorAlternatingReducer.State = .init(),
            probabilistic: NameGeneratorProbabilisticReducer.State = .init(),
            output: OutputEditorReducer.State = .init()
        ) {
            self.generationType = generationType
            self.prefixSuffix = prefixSuffix
            self.alternatingVowelsConsonants = alternatingVowelsConsonants
            self.probabilistic = probabilistic
            self.output = output
        }

        public var outputText: String {
            output.text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case prefixSuffix(NameGeneratorPrefixSuffixReducer.Action)
        case alternatingVowelsConsonants(NameGeneratorAlternatingReducer.Action)
        case probabilistic(NameGeneratorProbabilisticReducer.Action)
        case output(OutputEditorReducer.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case let .prefixSuffix(.generationResponse(.success(names))):
                return state.output.updateText(names)
                    .map { Action.output($0) }
            case .prefixSuffix:
                return .none
            case let .alternatingVowelsConsonants(.generationResponse(.success(names))):
                return state.output.updateText(names)
                    .map { Action.output($0) }
            case .alternatingVowelsConsonants:
                return .none
            case let .probabilistic(.generationResponse(.success(names))):
                return state.output.updateText(names)
                    .map { Action.output($0) }
            case .probabilistic:
                return .none
            case .output:
                return .none
            }
        }
        Scope(state: \.prefixSuffix, action: /Action.prefixSuffix) {
            NameGeneratorPrefixSuffixReducer()
        }
        Scope(state: \.alternatingVowelsConsonants, action: /Action.alternatingVowelsConsonants) {
            NameGeneratorAlternatingReducer()
        }
        Scope(state: \.probabilistic, action: /Action.probabilistic) {
            NameGeneratorProbabilisticReducer()
        }
        Scope(state: \.output, action: /Action.output) {
            OutputEditorReducer()
        }
    }
}

public struct NameGeneratorView: View {
    let store: StoreOf<NameGeneratorReducer>
    @ObservedObject var viewStore: ViewStoreOf<NameGeneratorReducer>

    public init(store: StoreOf<NameGeneratorReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            Picker(
                "Generation Type",
                selection: viewStore.binding(
                    \.$generationType
                )
            ) {
                Text(NSLocalizedString("Prefix Suffix", bundle: Bundle.module, comment: ""))
                    .tag(GenerationType.prefixSuffix)
                Text(NSLocalizedString("Alternating Vowels Consonants", bundle: Bundle.module, comment: ""))
                    .tag(GenerationType.alternatingVowelsConsonants)
                Text(NSLocalizedString("Probabilistic", bundle: Bundle.module, comment: ""))
                    .tag(GenerationType.probabilistic)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()

            VSplit {
                Group {
                    switch viewStore.generationType {
                    case .prefixSuffix:
                        NameGeneratorPrefixSuffixView(
                            store: store.scope(
                                state: \.prefixSuffix,
                                action: NameGeneratorReducer.Action.prefixSuffix
                            )
                        )
                    case .alternatingVowelsConsonants:
                        NameGeneratorAlternatingView(
                            store: store.scope(
                                state: \.alternatingVowelsConsonants,
                                action: NameGeneratorReducer.Action.alternatingVowelsConsonants
                            )
                        )
                    case .probabilistic:

                        NameGeneratorProbabilisticView(
                            store: store.scope(
                                state: \.probabilistic,
                                action: NameGeneratorReducer.Action.probabilistic
                            )
                        )
                    }
                }
                .padding()

            } bottom: {
                OutputEditorView(
                    store: store.scope(
                        state: \.output,
                        action: NameGeneratorReducer.Action.output
                    )
                )
            }
        }
    }
}

// preview
#if DEBUG
    struct NameGeneratorView_Previews: PreviewProvider {
        static var previews: some View {
            NameGeneratorView(
                store: Store(initialState: .init(), reducer: NameGeneratorReducer())
            )
        }
    }
#endif
