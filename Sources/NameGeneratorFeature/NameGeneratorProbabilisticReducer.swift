import ComposableArchitecture
import InputOutput
import NameGeneratorClient
import SwiftUI

public struct NameGeneratorProbabilisticReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState var vowelsInput: [LetterWeight]
        @BindingState var consonantsInput: [LetterWeight]
        @BindingState var minLength: Int
        @BindingState var maxLength: Int
        @BindingState var alternationProbability: Double
        @BindingState var numberOfNames: Int
        var isGenerating: Bool = false

        public init(
            vowelsInput: [LetterWeight] = [
                LetterWeight(letter: "a", frequency: 8),
                LetterWeight(letter: "e", frequency: 12),
                LetterWeight(letter: "i", frequency: 7),
                LetterWeight(letter: "o", frequency: 8),
                LetterWeight(letter: "u", frequency: 3),
            ],
            consonantsInput: [LetterWeight] = [
                LetterWeight(letter: "b", frequency: 1),
                LetterWeight(letter: "c", frequency: 3),
                LetterWeight(letter: "d", frequency: 4),
                LetterWeight(letter: "f", frequency: 2),
                LetterWeight(letter: "g", frequency: 2),
                LetterWeight(letter: "h", frequency: 5),
                LetterWeight(letter: "j", frequency: 1),
                LetterWeight(letter: "k", frequency: 1),
                LetterWeight(letter: "l", frequency: 4),
                LetterWeight(letter: "m", frequency: 3),
                LetterWeight(letter: "n", frequency: 7),
                LetterWeight(letter: "p", frequency: 2),
                LetterWeight(letter: "q", frequency: 1),
                LetterWeight(letter: "r", frequency: 6),
                LetterWeight(letter: "s", frequency: 6),
                LetterWeight(letter: "t", frequency: 9),
                LetterWeight(letter: "v", frequency: 1),
                LetterWeight(letter: "w", frequency: 2),
                LetterWeight(letter: "x", frequency: 1),
                LetterWeight(letter: "y", frequency: 2),
                LetterWeight(letter: "z", frequency: 1),
            ],
            minLength: Int = 3,
            maxLength: Int = 10,
            alternationProbability: Double = 0.5,
            numberOfNames: Int = 10

        ) {
            self.vowelsInput = vowelsInput
            self.consonantsInput = consonantsInput
            self.minLength = minLength
            self.maxLength = maxLength
            self.alternationProbability = alternationProbability
            self.numberOfNames = numberOfNames
        }

    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case generateButtonTouched
        case generationResponse(TaskResult<String>)
        case addVowelButtontouched
        case addConsonantButtontouched
        case deleteVowelButtontouched(LetterWeight.ID)
        case deleteConsonantButtontouched(LetterWeight.ID)
    }

    @Dependency(\.nameGenerator) var nameGenerator
    private enum CancelID { case generationRequest }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .generateButtonTouched:
                state.isGenerating = true
                return
                    .run {
                        [
                            vowels = state.vowelsInput, consonants = state.consonantsInput, minLength = state.minLength,
                            maxLength = state.maxLength, alternationProbability = state.alternationProbability,
                            numberOfNames = state.numberOfNames
                        ] send in
                        await send(
                            .generationResponse(
                                TaskResult {
                                    await nameGenerator.generate(
                                        probabilisticWith: .init(
                                            vowels: vowels,
                                            consonants: consonants,
                                            minLength: minLength,
                                            maxLength: maxLength,
                                            alternationProbability: alternationProbability
                                        ),
                                        times: numberOfNames
                                    )
                                    .joined(separator: "\n")
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.generationRequest, cancelInFlight: true)
            case .generationResponse(.success):
                state.isGenerating = false
                return .none
            case .generationResponse(.failure):
                state.isGenerating = false
                return .none

            case .addVowelButtontouched:
                state.vowelsInput.append(LetterWeight(letter: "?", frequency: 1))
                return .none
            case .addConsonantButtontouched:
                state.consonantsInput.append(LetterWeight(letter: "?", frequency: 1))
                return .none

            case let .deleteVowelButtontouched(id):
                state.vowelsInput.removeAll(where: { $0.id == id })
                return .none
            case let .deleteConsonantButtontouched(id):
                state.consonantsInput.removeAll(where: { $0.id == id })
                return .none
            }
        }
    }
}

public struct NameGeneratorProbabilisticView: View {
    let store: StoreOf<NameGeneratorProbabilisticReducer>
    @ObservedObject var viewStore: ViewStoreOf<NameGeneratorProbabilisticReducer>

    public init(store: StoreOf<NameGeneratorProbabilisticReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            LetterWeightsInputView(
                vowelsInput: viewStore.binding(\.$vowelsInput),
                title: "Vowels",
                plustButtonAction: {
                    viewStore.send(.addVowelButtontouched)
                },
                deleteButtonAction: { id in
                    viewStore.send(.deleteVowelButtontouched(id))
                }
            )
            LetterWeightsInputView(
                vowelsInput: viewStore.binding(\.$consonantsInput),
                title: "Consonants",
                plustButtonAction: {
                    viewStore.send(.addVowelButtontouched)
                },
                deleteButtonAction: { id in
                    viewStore.send(.deleteVowelButtontouched(id))
                }
            )
            HStack {
                VStack {
                    Text("Min. length")
                    IntegerTextField(value: viewStore.binding(\.$minLength), range: 1 ... 15)
                        .frame(maxWidth: 100)
                }
                VStack {
                    Text("Max. length")
                    IntegerTextField(value: viewStore.binding(\.$maxLength), range: 1 ... 15)
                        .frame(maxWidth: 100)
                }
                VStack {
                    Text("Alternation\nProbability")
                        .help(
                            "the probability of alternating between vowel and consonant when generating the next letter"
                        )
                    Slider(value: viewStore.binding(\.$alternationProbability), in: 0 ... 1)
                        .frame(maxWidth: 100)
                }
                VStack {
                    Text("Count")
                    IntegerTextField(value: viewStore.binding(\.$numberOfNames), range: 1 ... 200)
                        .frame(maxWidth: 150)
                }
            }

            Button(NSLocalizedString("Generate", bundle: Bundle.module, comment: "")) {
                viewStore.send(.generateButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Generate names (Cmd+Return)", bundle: Bundle.module, comment: ""))
            .overlay(
                viewStore.isGenerating
                    ? ProgressView()
                    : nil
            )
        }
    }
}

// preview
#if DEBUG

    struct NameGeneratorProbabilisticView_Previews: PreviewProvider {
        let vowelsMock = "aeiou"
        let consonantsMock = "bcdfghjklmnpqrstvwxyz"

        static var previews: some View {
            NameGeneratorProbabilisticView(
                store: Store(
                    initialState: .init(),
                    reducer: NameGeneratorProbabilisticReducer()
                )
            )
        }
    }
#endif

struct LetterWeightsInputView: View {
    @Binding var vowelsInput: [LetterWeight]
    let title: String
    let plustButtonAction: () -> Void
    let deleteButtonAction: (LetterWeight.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Letter")
                        Text("Weight")
                    }
                    ForEach($vowelsInput) { $letterWeight in

                        VStack(alignment: .center) {
                            TextField("", text: $letterWeight.letter)
                            IntegerTextField(value: $letterWeight.frequency, range: 0 ... 20)

                                .frame(maxWidth: 70)
                            Button {
                                deleteButtonAction(letterWeight.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.footnote)
                            }  // <-Button
                            .buttonStyle(.plain)
                        }

                    }
                    .font(.monospaced(.title3)())

                    Button {
                        plustButtonAction()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(NSLocalizedString("Add \(title)", bundle: Bundle.module, comment: ""))
                }
            }
        }
    }
}
