import ComposableArchitecture
import InputOutput
import NameGeneratorClient
import SwiftUI

public struct NameGeneratorPrefixSuffixReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState var prefixesInput: String
        @BindingState var suffixesInput: String
        @BindingState var inputSeparator: String
        @BindingState var numberOfNames: Int
        var isGenerating: Bool = false

        public init(
            prefixesInput: String = [
                "Jo", "Bel", "Har", "San", "Le", "Gra", "Mel", "Ed", "Ari", "Theo", "Lau", "Phil", "Mat", "Rach",
                "Mich", "Chris",
                "An", "Jes", "Zach", "Deb", "Rob", "Steph", "Bri", "Pat", "Sam", "Kat", "Vic", "Nico", "Alex", "El",
                "Gab",
            ].joined(separator: ";"),
            suffixesInput: String = [
                "Jo", "Bel", "Har", "San", "Le", "Gra", "Mel", "Ed", "Ari", "Theo", "Lau", "Phil", "Mat", "Rach",
                "Mich", "Chris",
                "An", "Jes", "Zach", "Deb", "Rob", "Steph", "Bri", "Pat", "Sam", "Kat", "Vic", "Nico", "Alex", "El",
                "Gab",
            ].joined(separator: ";c"),
            inputSeparator: String = ";",
            numberOfNames: Int = 10
        ) {
            self.prefixesInput = prefixesInput
            self.suffixesInput = suffixesInput
            self.inputSeparator = inputSeparator
            self.numberOfNames = numberOfNames
        }

        public var prefixes: [String] {
            prefixesInput.components(separatedBy: inputSeparator)
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        }

        public var suffixes: [String] {
            suffixesInput.components(separatedBy: inputSeparator)
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
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
                        [prefixes = state.prefixes, suffixes = state.suffixes, numberOfNames = state.numberOfNames] send in
                        await send(
                            .generationResponse(
                                TaskResult {
                                    await nameGenerator.generateUsing(namePrefixes: prefixes, nameSuffixes: suffixes,
                                    times: numberOfNames)
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
            }
        }
    }
}

public struct NameGeneratorPrefixSuffixView: View {
    let store: StoreOf<NameGeneratorPrefixSuffixReducer>
    @ObservedObject var viewStore: ViewStoreOf<NameGeneratorPrefixSuffixReducer>

    public init(store: StoreOf<NameGeneratorPrefixSuffixReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Prefixes", bundle: Bundle.module, comment: ""))
                    TextField(NSLocalizedString("Prefixes", bundle: Bundle.module, comment: ""), text: viewStore.binding(\.$prefixesInput))
                        .font(.monospaced(.title3)())
                }  // <-VStack
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: ""))
                    TextField(NSLocalizedString("Separator", bundle: Bundle.module, comment: ""), text: viewStore.binding(\.$inputSeparator))
                        .font(.monospaced(.title3)())
                        .frame(maxWidth: 60)
                }
                .help(NSLocalizedString("string to be used to split input into a list", bundle: Bundle.module, comment: ""))
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Suffixes", bundle: Bundle.module, comment: ""))
                    TextField(NSLocalizedString("Suffixes", bundle: Bundle.module, comment: ""), text: viewStore.binding(\.$suffixesInput))
                        .font(.monospaced(.title3)())
                }
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: "")).foregroundColor(.clear)
                    TextField(NSLocalizedString("Separator", bundle: Bundle.module, comment: ""), text: viewStore.binding(\.$inputSeparator))
                        .font(.monospaced(.title3)())
                        .frame(maxWidth: 60)
                        .help(NSLocalizedString("string to be used to split input into a list", bundle: Bundle.module, comment: ""))
                }
                VStack {
                    Text(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: viewStore.binding(\.$numberOfNames), range: 1 ... 200)
                        .frame(maxWidth: 150)
                }
                .accessibilityLabel(NSLocalizedString("Number of names", bundle: Bundle.module, comment: ""))                
                .accessibilityValue(NSLocalizedString("\(viewStore.numberOfNames)", bundle: Bundle.module, comment: "value of a numeric input value for voice-over"))
            }
            Button(NSLocalizedString("Generate", bundle: Bundle.module, comment: "")) {
                viewStore.send(.generateButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Generate names (Cmd+Return)", bundle: Bundle.module, comment: ""))
            // OutputEditorView(store: store.scope(state: \.output, action: /NameGeneratorPrefixSuffixReducer.Action.output))
        }
    }
}

// preview
#if DEBUG

    struct NameGeneratorPrefixSuffixView_Previews: PreviewProvider {

        static var previews: some View {
            let namePrefixesMock = [
                "Jo", "Bel", "Har", "San", "Le", "Gra", "Mel", "Ed", "Ari", "Theo", "Lau", "Phil", "Mat", "Rach",
                "Mich", "Chris",
                "An", "Jes", "Zach", "Deb", "Rob", "Steph", "Bri", "Pat", "Sam", "Kat", "Vic", "Nico", "Alex", "El",
                "Gab",
            ]
            let nameSuffixesMock = [
                "na", "la", "ron", "ton", "ine", "bell", "dor", "ber", "lie", "der", "ney", "dy", "son", "lan", "th",
                "ce", "cie",
                "cy", "sy", "ca", "ty", "ny", "ris", "is", "sey", "nie", "len", "ken", "ben", "den", "men", "jen",
            ]
            return NameGeneratorPrefixSuffixView(
                store: Store(
                    initialState: .init(prefixesInput: namePrefixesMock.joined(separator: ";"), suffixesInput: nameSuffixesMock.joined(separator: ";")),
                    reducer: NameGeneratorPrefixSuffixReducer()
                )
            )
        }
    }
#endif
