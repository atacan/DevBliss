import ComposableArchitecture
import InputOutput
import NameGeneratorClient
import SwiftUI

public struct NameGeneratorAlternatingReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState var vowelsInput: String
        @BindingState var consonantsInput: String
        @BindingState var inputSeparator: String
        @BindingState var minLength: Int
        @BindingState var maxLength: Int
        @BindingState var numberOfNames: Int
        var isGenerating: Bool = false

        public init(
            vowelsInput: String = "aeiou",
            consonantsInput: String = "bcdfghjklmnpqrstvwxyz",
            inputSeparator: String = "",
            minLength: Int = 3,
            maxLength: Int = 10,
            numberOfNames: Int = 10
        ) {
            self.vowelsInput = vowelsInput
            self.consonantsInput = consonantsInput
            self.inputSeparator = inputSeparator
            self.minLength = minLength
            self.maxLength = maxLength
            self.numberOfNames = numberOfNames
        }

        public var vowels: [String] {
            vowelsInput.components(separatedBy: inputSeparator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        public var consonants: [String] {
            consonantsInput.components(separatedBy: inputSeparator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case generateButtonTouched
        case generationResponse(TaskResult<String>)
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
                            maxLength = state.maxLength, numberOfNames = state.numberOfNames
                        ] send in
                        await send(
                            .generationResponse(
                                TaskResult {
                                    await nameGenerator.generateAlternating(
                                        vowels: vowels,
                                        consonants: consonants,
                                        minLength: minLength,
                                        maxLength: maxLength,
                                        times: numberOfNames
                                    )
                                    .joined(separator: "\n")
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.generationRequest, cancelInFlight: true)
            case .generationResponse(.success(_)):
                state.isGenerating = false
                return .none
            case .generationResponse(.failure):
                state.isGenerating = false
                return .none
            }
        }
    }
}

public struct NameGeneratorAlternatingView: View {
    let store: StoreOf<NameGeneratorAlternatingReducer>
    @ObservedObject var viewStore: ViewStoreOf<NameGeneratorAlternatingReducer>

    public init(store: StoreOf<NameGeneratorAlternatingReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Vowels", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Prefixes", bundle: Bundle.module, comment: ""),
                        text: viewStore.binding(\.$vowelsInput)
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                }  // <-VStack
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Separator", bundle: Bundle.module, comment: ""),
                        text: viewStore.binding(\.$inputSeparator)
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Consonants", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Suffixes", bundle: Bundle.module, comment: ""),
                        text: viewStore.binding(\.$consonantsInput)
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: "")).foregroundColor(.clear)
                    TextField(
                        NSLocalizedString("Separator", bundle: Bundle.module, comment: ""),
                        text: viewStore.binding(\.$inputSeparator)
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
                }
            }

            HStack {
                VStack {
                    Text(NSLocalizedString("Min. length", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: viewStore.binding(\.$minLength), range: 1 ... 15)
                        .frame(maxWidth: 150)
                }
                .accessibilityLabel(
                    NSLocalizedString(
                        "Minimum length of the names",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                .accessibilityValue(
                    NSLocalizedString(
                        "\(viewStore.minLength)",
                        bundle: Bundle.module,
                        comment: "value of a numeric input value for voice-over"
                    )
                )

                VStack {
                    Text(NSLocalizedString("Max. length", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: viewStore.binding(\.$maxLength), range: 1 ... 15)
                        .frame(maxWidth: 150)
                }
                .accessibilityLabel(
                    NSLocalizedString(
                        "Maximum length of the names",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                .accessibilityValue(
                    NSLocalizedString(
                        "\(viewStore.maxLength)",
                        bundle: Bundle.module,
                        comment: "value of a numeric input value for voice-over"
                    )
                )

                VStack {
                    Text(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: viewStore.binding(\.$numberOfNames), range: 1 ... 200)
                        .frame(maxWidth: 150)
                }
                .accessibilityLabel(
                    NSLocalizedString(
                        "Number of names",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                .accessibilityValue(
                    String(
                        format: NSLocalizedString(
                            "%d",
                            bundle: Bundle.module,
                            comment: "value of a numeric input value for voice-over"
                        ),
                        viewStore.numberOfNames
                    )
                )
            }

            Button(NSLocalizedString("Generate", bundle: Bundle.module, comment: "")) {
                viewStore.send(.generateButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Generate names (Cmd+Return)", bundle: Bundle.module, comment: ""))
        }
    }
}

// preview
#if DEBUG

    struct NameGeneratorAlternatingView_Previews: PreviewProvider {
        let vowelsMock = "aeiou"
        let consonantsMock = "bcdfghjklmnpqrstvwxyz"

        static var previews: some View {
            NameGeneratorAlternatingView(
                store: Store(
                    initialState: .init(),
                    reducer: NameGeneratorAlternatingReducer()
                )
            )
        }
    }
#endif

// BUG: on macOS although the value stays 1+, the text field shows zero
struct IntegerTextField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Stepper(
                value: Binding(
                    get: { value },
                    set: { value = $0.clamped(to: range) }
                )
            ) {
                TextField(
                    "",
                    text: Binding(
                        get: { "\(value)" },
                        set: {
                            if let newValue = Int($0) {
                                value = newValue.clamped(to: range)
                            }
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 250)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
