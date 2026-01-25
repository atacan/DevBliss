import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI
import TextCaseConverterClient

@Reducer
public struct TextCaseConverterReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("textCaseConverter")) public var inputText = ""
        @Shared(.toolOutput("textCaseConverter")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        @Shared(.appStorage(SettingsKey.TextCaseConverter.sourceCase)) public var sourceCase: WordGroupCase = .kebab
        @Shared(.appStorage(SettingsKey.TextCaseConverter.targetCase)) public var targetCase: WordGroupCase = .snake
        @Shared(.appStorage(SettingsKey.TextCaseConverter.textSeperator)) public var textSeperator: WordGroupSeperator = .newLine

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("textCaseConverter"))
            let outputText = Shared(wrappedValue: "", .toolOutput("textCaseConverter"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("textCaseConverter"))
            let outputText = Shared(wrappedValue: output, .toolOutput("textCaseConverter"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case switchCasesButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.textCaseConverter) var textCaseConverter
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .switchCasesButtonTouched:
                let oldSource = state.sourceCase
                let oldTarget = state.targetCase
                state.$sourceCase.withLock { $0 = oldTarget }
                state.$targetCase.withLock { $0 = oldSource }
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
}

public struct TextCaseConverterView: View {
    @Bindable var store: StoreOf<TextCaseConverterReducer>

    #if os(iOS)
        private let pickerTitleSpace: CGFloat = 0
    #elseif os(macOS)
        private let pickerTitleSpace: CGFloat = 4
    #endif

    public init(store: StoreOf<TextCaseConverterReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("From", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("From", bundle: Bundle.module, comment: ""),
                        selection: $store.sourceCase
                    ) {
                        ForEach(WordGroupCase.allCases) { sourceCase in
                            Text(sourceCase.rawValue)
                                .tag(sourceCase)
                        }
                    }
                    .blissMenuPicker(width: 140)

                    ConfigLabel(NSLocalizedString("To", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("To", bundle: Bundle.module, comment: ""),
                        selection: $store.targetCase
                    ) {
                        ForEach(WordGroupCase.allCases) { targetCase in
                            Text(targetCase.rawValue)
                                .tag(targetCase)
                        }
                    }
                    .blissMenuPicker(width: 140)
                }

                GridRow {
                    ConfigLabel(NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""),
                        selection: $store.textSeperator
                    ) {
                        ForEach(WordGroupSeperator.allCases) { (seperator: WordGroupSeperator) in
                            Text(seperator == .newLine ? "New Line" : "Space")
                                .tag(seperator)
                        }
                    }
                    .blissMenuPicker(width: 140)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                Button {
                    store.send(.switchCasesButtonTouched)
                } label: {
                    Label(NSLocalizedString("Switch Cases", bundle: Bundle.module, comment: ""), systemImage: "arrow.left.and.right")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("w", modifiers: [.command, .shift])
                .help(NSLocalizedString("Switch source and target cases (⌘⇧W)", bundle: Bundle.module, comment: ""))

                LoadingButton(
                    NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
                    isLoading: store.isConversionRequestInFlight
                ) {
                    store.send(.convertButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Convert code (⌘ Return)", bundle: Bundle.module, comment: ""))
            }
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: TextCaseConverterReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Input", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Output", bundle: Bundle.module, comment: ""),
                keyForFraction: SettingsKey.TextCaseConverter.splitViewFraction,
                keyForLayout: SettingsKey.TextCaseConverter.splitViewLayout
            )
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
