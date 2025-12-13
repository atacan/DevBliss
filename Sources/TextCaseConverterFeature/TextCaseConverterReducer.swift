import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import InputOutput
import SharedModels
import SwiftUI
import TextCaseConverterClient

@Reducer
public struct TextCaseConverterReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        public var sourceCase: WordGroupCase
        public var targetCase: WordGroupCase
        public var textSeperator: WordGroupSeperator

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
        case observeSettings
        case binding(BindingAction<State>)
        case convertButtonTouched
        case switchCasesButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.textCaseConverter) var textCaseConverter
    private enum CancelID { case conversionRequest }
    @Dependency(\.userDefaults) var userDefaults

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .observeSettings:
                return observeSettings(&state)
            case let .binding(action):
                return setPreferences(for: action, from: state)
            case .switchCasesButtonTouched:
                (state.sourceCase, state.targetCase) = (state.targetCase, state.sourceCase)
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

    private func observeSettings(_ state: inout State) -> Effect<Action> {
        if let newSourceCase: WordGroupCase =
            userDefaults
            .rawRepresentable(forKey: SettingsKey.TextCaseConverter.sourceCase)
        {
            state.sourceCase = newSourceCase
        }
        if let newTargetCase: WordGroupCase =
            userDefaults
            .rawRepresentable(forKey: SettingsKey.TextCaseConverter.targetCase)
        {
            state.targetCase = newTargetCase
        }
        if let newTextSeperator: WordGroupSeperator =
            userDefaults
            .rawRepresentable(forKey: SettingsKey.TextCaseConverter.textSeperator)
        {
            state.textSeperator = newTextSeperator
        }
        return .none
    }

    private func setPreferences(for action: BindingAction<State>, from state: State) -> Effect<Action> {
        userDefaults.set(state.sourceCase, forKey: SettingsKey.TextCaseConverter.sourceCase)
        userDefaults.set(state.targetCase, forKey: SettingsKey.TextCaseConverter.targetCase)
        userDefaults.set(state.textSeperator, forKey: SettingsKey.TextCaseConverter.textSeperator)
        return .none
    }
}

public struct TextCaseConverterView: View {
    @Perception.Bindable var store: StoreOf<TextCaseConverterReducer>

    #if os(iOS)
        private let pickerTitleSpace: CGFloat = 0
    #elseif os(macOS)
        private let pickerTitleSpace: CGFloat = 4
    #endif

    public init(store: StoreOf<TextCaseConverterReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center, spacing: pickerTitleSpace) {
                    Text(NSLocalizedString("From", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("From", bundle: Bundle.module, comment: ""),
                        selection: $store.sourceCase
                    ) {
                        ForEach(WordGroupCase.allCases) { sourceCase in
                            Text(sourceCase.rawValue)
                                .tag(sourceCase)
                        }
                    }
                    }
                    VStack(alignment: .center, spacing: pickerTitleSpace) {
                     Text(NSLocalizedString("To", bundle: Bundle.module, comment: ""))
                     Picker(
                         NSLocalizedString("To", bundle: Bundle.module, comment: ""),
                         selection: $store.targetCase
                     ) {
                         ForEach(WordGroupCase.allCases) { targetCase in
                             Text(targetCase.rawValue)
                                 .tag(targetCase)
                         }
                     }
                    }
                VStack(alignment: .center, spacing: pickerTitleSpace) {
                    Text(NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""),
                        selection: $store.textSeperator
                    ) {
                        ForEach(WordGroupSeperator.allCases) { (seperator: WordGroupSeperator) in
                            Text(seperator == .newLine ? "New Line" : "Space")
                                .tag(seperator)
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: 600)
            .labelsHidden()

            HStack {
                Button {
                    store.send(.switchCasesButtonTouched)
                } label: {
                    Image(systemName: "arrow.left.and.right")
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                .help(NSLocalizedString("Switch source and target cases (Cmd+Shift+W)", bundle: Bundle.module, comment: ""))

                Button(action: { store.send(.convertButtonTouched) }) {
                    Text(NSLocalizedString("Convert", bundle: Bundle.module, comment: ""))
                        .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Convert code (Cmd+Return)", bundle: Bundle.module, comment: ""))
                .padding(.bottom, 2)
            }

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: TextCaseConverterReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Input", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Output", bundle: Bundle.module, comment: ""),
                keyForFraction: SettingsKey.TextCaseConverter.splitViewFraction,
                keyForLayout: SettingsKey.TextCaseConverter.splitViewLayout
            )
        }
        .onAppear {
            store.send(.observeSettings)
        }
    }
}

// preview
struct TextCaseConverterReducer_Previews: PreviewProvider {
    static var previews: some View {
        TextCaseConverterView(store: .init(initialState: .init()) { TextCaseConverterReducer() })
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
