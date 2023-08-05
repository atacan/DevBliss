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

    @FocusState private var focusedField: Field?
    enum Field: Int, Hashable {
        case prefixReplace
        case prefixReplaceWith
        case prefixAdd
        case suffixReplace
        case suffixReplaceWith
        case suffixAdd
    }

    public init(store: StoreOf<PrefixSuffixReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image(systemName: "arrow.forward")
                .help(
                    NSLocalizedString(
                        "It first starts applying the prefix changes",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                VStack {
                    Text(NSLocalizedString("Prefix", bundle: Bundle.module, comment: ""))
                    Group {
                        TextField(
                            NSLocalizedString("Replace prefix", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$configuration.prefixReplace)
                        )
                        .focused($focusedField, equals: .prefixReplace)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Replace prefix if available", bundle: Bundle.module, comment: ""))

                        TextField(
                            NSLocalizedString("with", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$configuration.prefixReplaceWith)
                        )
                        .focused($focusedField, equals: .prefixReplaceWith)
                        .onSubmit { focusNextField($focusedField) }
                        .help(
                            NSLocalizedString(
                                "the prefix written previously will be replaced with this",
                                bundle: Bundle.module,
                                comment: ""
                            )
                        )

                        TextField(
                            NSLocalizedString("Then add Prefix", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$configuration.prefixAdd)
                        )
                        .focused($focusedField, equals: .prefixAdd)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Then add Prefix", bundle: Bundle.module, comment: ""))
                    }  // <-Group
                    .font(.monospaced(.body)())
                    .textFieldStyle(.roundedBorder)
                }
                Image(systemName: "arrow.forward.square.fill")
                .help(
                    NSLocalizedString(
                        "Then it applies the suffix manipulation",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                VStack {
                    Text(
                        NSLocalizedString(
                            "Suffix",
                            bundle: Bundle.module,
                            comment: "title of the suffix manipulation input fields"
                        )
                    )
                    Group {
                        TextField(
                            NSLocalizedString("Replace suffix", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$configuration.suffixReplace)
                        )
                        .focused($focusedField, equals: .suffixReplace)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Replace suffix if available", bundle: Bundle.module, comment: ""))

                        TextField(
                            NSLocalizedString("with", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$configuration.suffixReplaceWith)
                        )
                        .focused($focusedField, equals: .suffixReplaceWith)
                        .onSubmit { focusNextField($focusedField) }
                        .help(
                            NSLocalizedString(
                                "the suffix written previously will be replaced with this",
                                bundle: Bundle.module,
                                comment: ""
                            )
                        )

                        TextField(
                            NSLocalizedString("Then add Suffix", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$configuration.suffixAdd)
                        )
                        .focused($focusedField, equals: .suffixAdd)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Then add Suffix", bundle: Bundle.module, comment: ""))
                    }  // <-Group
                    .font(.monospaced(.body)())
                    .textFieldStyle(.roundedBorder)
                }
                Image(systemName: "backward.end")
                .help(
                    NSLocalizedString(
                        "After applying prefix and suffice manipulations to each line separately, it ends.",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
            }  // <-HStack
            .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
            #endif
            .frame(maxWidth: 850)

            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Convert", bundle: Bundle.module, comment: ""))
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Convert (Cmd+Return)", bundle: Bundle.module, comment: ""))
            .padding(.top)

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: PrefixSuffixReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Input", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Output", bundle: Bundle.module, comment: "")
            )
        }
        .onAppear {
            focusedField = .prefixReplace
        }
    }
}

// preview
struct PrefixSuffixReducer_Previews: PreviewProvider {
    static var previews: some View {
        PrefixSuffixView(store: .init(initialState: .init(), reducer: PrefixSuffixReducer()))
    }
}

// https://stackoverflow.com/a/71531523
extension View {
    /// Focuses next field in sequence, from the given `FocusState`.
    /// Requires a currently active focus state and a next field available in the sequence.
    ///
    /// Example usage:
    /// ```
    /// .onSubmit { self.focusNextField($focusedField) }
    /// ```
    /// Given that `focusField` is an enum that represents the focusable fields. For example:
    /// ```
    /// @FocusState private var focusedField: Field?
    /// enum Field: Int, Hashable {
    ///    case name
    ///    case country
    ///    case city
    /// }
    /// ```
    func focusNextField<F: RawRepresentable>(_ field: FocusState<F?>.Binding) where F.RawValue == Int {
        guard let currentValue = field.wrappedValue else {
            return
        }
        let nextValue = currentValue.rawValue + 1
        if let newValue = F(rawValue: nextValue) {
            field.wrappedValue = newValue
        }
    }

    /// Focuses previous field in sequence, from the given `FocusState`.
    /// Requires a currently active focus state and a previous field available in the sequence.
    ///
    /// Example usage:
    /// ```
    /// .onSubmit { self.focusNextField($focusedField) }
    /// ```
    /// Given that `focusField` is an enum that represents the focusable fields. For example:
    /// ```
    /// @FocusState private var focusedField: Field?
    /// enum Field: Int, Hashable {
    ///    case name
    ///    case country
    ///    case city
    /// }
    /// ```
    func focusPreviousField<F: RawRepresentable>(_ field: FocusState<F?>.Binding) where F.RawValue == Int {
        guard let currentValue = field.wrappedValue else {
            return
        }
        let nextValue = currentValue.rawValue - 1
        if let newValue = F(rawValue: nextValue) {
            field.wrappedValue = newValue
        }
    }
}
