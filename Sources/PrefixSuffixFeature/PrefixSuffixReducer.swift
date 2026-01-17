import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import InputOutput
import PrefixSuffixClient
import SharedModels
import SwiftUI

@Reducer
public struct PrefixSuffixReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared(.prefixSuffixIO) var storage = ToolIOStorage()
        public var inputOutput: InputOutputEditorsReducer.State
        public var configuration: PrefixSuffixConfig
        var isConversionRequestInFlight = false

        public init(
            inputOutput: InputOutputEditorsReducer.State = .init(),
            configuration: PrefixSuffixConfig = .init()
        ) {
            // Initialize inputOutput using derived shared refs from storage
            // We must create Shared projections from the persisted key, not from $storage
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(), .prefixSuffixIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: sharedStorage.input,
                outputText: sharedStorage.output
            )

            // Initialize other properties
            self.isConversionRequestInFlight = false

            // Load config from UserDefaults
            @Dependency(\.userDefaults) var userDefaults
            let config: PrefixSuffixConfig = with(configuration) {
                .init(
                    prefixReplace: userDefaults.string(forKey: SettingsKey.PrefixSuffix.prefixReplace)
                        ?? $0
                        .prefixReplace,
                    prefixReplaceWith: userDefaults.string(forKey: SettingsKey.PrefixSuffix.prefixReplaceWith)
                        ?? $0
                        .prefixReplaceWith,
                    prefixAdd: userDefaults.string(forKey: SettingsKey.PrefixSuffix.prefixAdd) ?? $0.prefixAdd,
                    suffixReplace: userDefaults.string(forKey: SettingsKey.PrefixSuffix.suffixReplace)
                        ?? $0
                        .suffixReplace,
                    suffixReplaceWith: userDefaults.string(forKey: SettingsKey.PrefixSuffix.suffixReplaceWith)
                        ?? $0
                        .suffixReplaceWith,
                    suffixAdd: userDefaults.string(forKey: SettingsKey.PrefixSuffix.suffixAdd) ?? $0.suffixAdd,
                    trimWhiteSpace: userDefaults.bool(forKey: SettingsKey.PrefixSuffix.trimWhiteSpace)
                        ?? $0
                        .trimWhiteSpace
                )
            }
            self.configuration = config
        }

        public init(input: String, output: String = "") {
            // Initialize @Shared storage with provided values
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .prefixSuffixIO)

            // Initialize inputOutput using derived shared refs
            // Create a new Shared reference from the same key to get projections
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .prefixSuffixIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: sharedStorage.input,
                outputText: sharedStorage.output
            )

            // Initialize other properties
            self.isConversionRequestInFlight = false

            // Load config from UserDefaults
            @Dependency(\.userDefaults) var userDefaults
            let config = PrefixSuffixConfig(
                prefixReplace: userDefaults.string(forKey: SettingsKey.PrefixSuffix.prefixReplace) ?? "",
                prefixReplaceWith: userDefaults.string(forKey: SettingsKey.PrefixSuffix.prefixReplaceWith) ?? "",
                prefixAdd: userDefaults.string(forKey: SettingsKey.PrefixSuffix.prefixAdd) ?? "",
                suffixReplace: userDefaults.string(forKey: SettingsKey.PrefixSuffix.suffixReplace) ?? "",
                suffixReplaceWith: userDefaults.string(forKey: SettingsKey.PrefixSuffix.suffixReplaceWith) ?? "",
                suffixAdd: userDefaults.string(forKey: SettingsKey.PrefixSuffix.suffixAdd) ?? "",
                trimWhiteSpace: userDefaults.bool(forKey: SettingsKey.PrefixSuffix.trimWhiteSpace) ?? true
            )
            self.configuration = config
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
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.mainQueue) var mainQueue

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case let .binding(action):
                return setPreferences(for: action, from: state)
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

    private func setPreferences(for action: BindingAction<State>, from state: State) -> Effect<Action> {
        userDefaults.set(state.configuration.prefixReplace, forKey: SettingsKey.PrefixSuffix.prefixReplace)
        userDefaults.set(state.configuration.prefixReplaceWith, forKey: SettingsKey.PrefixSuffix.prefixReplaceWith)
        userDefaults.set(state.configuration.prefixAdd, forKey: SettingsKey.PrefixSuffix.prefixAdd)
        userDefaults.set(state.configuration.suffixReplace, forKey: SettingsKey.PrefixSuffix.suffixReplace)
        userDefaults.set(state.configuration.suffixReplaceWith, forKey: SettingsKey.PrefixSuffix.suffixReplaceWith)
        userDefaults.set(state.configuration.suffixAdd, forKey: SettingsKey.PrefixSuffix.suffixAdd)
        userDefaults.set(state.configuration.trimWhiteSpace, forKey: SettingsKey.PrefixSuffix.trimWhiteSpace)
        return .none
    }
}

public struct PrefixSuffixView: View {
    @Bindable var store: StoreOf<PrefixSuffixReducer>

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
                            text: $store.configuration.prefixReplace
                        )
                        .focused($focusedField, equals: .prefixReplace)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Replace prefix if available", bundle: Bundle.module, comment: ""))

                        TextField(
                            NSLocalizedString("with", bundle: Bundle.module, comment: ""),
                            text: $store.configuration.prefixReplaceWith
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
                            text: $store.configuration.prefixAdd
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
                             text: $store.configuration.suffixReplace
                         )
                         .focused($focusedField, equals: .suffixReplace)
                         .onSubmit { focusNextField($focusedField) }
                         .help(NSLocalizedString("Replace suffix if available", bundle: Bundle.module, comment: ""))

                         TextField(
                             NSLocalizedString("with", bundle: Bundle.module, comment: ""),
                             text: $store.configuration.suffixReplaceWith
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
                             text: $store.configuration.suffixAdd
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

            Button(action: { store.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Convert", bundle: Bundle.module, comment: ""))
                    .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Convert (Cmd+Return)", bundle: Bundle.module, comment: ""))
            .padding(.top)

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: PrefixSuffixReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Input", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Output", bundle: Bundle.module, comment: ""),
                keyForFraction: SettingsKey.PrefixSuffix.splitViewFraction,
                keyForLayout: SettingsKey.PrefixSuffix.splitViewLayout
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
        PrefixSuffixView(store: .init(initialState: .init()) { PrefixSuffixReducer() })
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
