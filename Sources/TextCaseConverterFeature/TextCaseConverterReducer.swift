import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class TextCaseConverterModel {
    @ObservationIgnored
    @Shared(.toolInput("textCaseConverter"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("textCaseConverter"))
    public var outputText = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.TextCaseConverter.sourceCase))
    public var sourceCase: WordGroupCase = .kebab

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.TextCaseConverter.targetCase))
    public var targetCase: WordGroupCase = .snake

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.TextCaseConverter.textSeperator))
    public var textSeperator: WordGroupSeperator = .newLine

    public var isConversionRequestInFlight = false

    @ObservationIgnored
    @Dependency(\.textCaseConverter) private var textCaseConverter

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("textCaseConverter"))
        let outputText = Shared(wrappedValue: "", .toolOutput("textCaseConverter"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(
        input: String,
        output: String = ""
    ) {
        let inputText = Shared(wrappedValue: input, .toolInput("textCaseConverter"))
        let outputText = Shared(wrappedValue: output, .toolOutput("textCaseConverter"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func switchCases() {
        let oldSource = sourceCase
        $sourceCase.withLock { $0 = targetCase }
        $targetCase.withLock { $0 = oldSource }
    }

    public func setSourceCase(_ value: WordGroupCase) {
        $sourceCase.withLock { $0 = value }
    }

    public func setTargetCase(_ value: WordGroupCase) {
        $targetCase.withLock { $0 = value }
    }

    public func setTextSeperator(_ value: WordGroupSeperator) {
        $textSeperator.withLock { $0 = value }
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let sourceCase = self.sourceCase
        let targetCase = self.targetCase
        conversionTask = Task { [weak self, input = input, sourceCase = sourceCase, targetCase = targetCase, textCaseConverter = textCaseConverter] in
            guard let self else { return }
            do {
                let result = try await textCaseConverter.convert(input, .newLine, sourceCase, targetCase)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = result }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

extension TextCaseConverterModel: Equatable {
    public static func == (lhs: TextCaseConverterModel, rhs: TextCaseConverterModel) -> Bool {
        lhs === rhs
    }
}

public struct TextCaseConverterModelView: View {
    @Bindable var model: TextCaseConverterModel

    public init(model: TextCaseConverterModel) {
        self.model = model
    }

    #if os(iOS)
        private let pickerTitleSpace: CGFloat = 0
    #elseif os(macOS)
        private let pickerTitleSpace: CGFloat = 4
    #endif

    private var sourceCasePicker: some View {
        Picker(
            NSLocalizedString("From", bundle: Bundle.module, comment: ""),
            selection: Binding(
                get: { model.sourceCase },
                set: { model.setSourceCase($0) }
            )
        ) {
            ForEach(WordGroupCase.allCases) { sourceCase in
                Text(sourceCase.rawValue)
                    .tag(sourceCase)
            }
        }
    }

    private var targetCasePicker: some View {
        Picker(
            NSLocalizedString("To", bundle: Bundle.module, comment: ""),
            selection: Binding(
                get: { model.targetCase },
                set: { model.setTargetCase($0) }
            )
        ) {
            ForEach(WordGroupCase.allCases) { targetCase in
                Text(targetCase.rawValue)
                    .tag(targetCase)
            }
        }
    }

    private var separatorPicker: some View {
        Picker(
            NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""),
            selection: Binding(
                get: { model.textSeperator },
                set: { model.setTextSeperator($0) }
            )
        ) {
            ForEach(WordGroupSeperator.allCases) { (seperator: WordGroupSeperator) in
                Text(seperator == .newLine ? "New Line" : "Space")
                    .tag(seperator)
            }
        }
    }

    private var switchCasesButton: some View {
        Button {
            model.switchCases()
        } label: {
            Label(NSLocalizedString("Switch Cases", bundle: Bundle.module, comment: ""), systemImage: "arrow.left.and.right")
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("w", modifiers: [.command, .shift])
        .help(NSLocalizedString("Switch source and target cases (⌘⇧W)", bundle: Bundle.module, comment: ""))
    }

    private var convertButton: some View {
        LoadingButton(
            NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
            isLoading: model.isConversionRequestInFlight
        ) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help(NSLocalizedString("Convert code (⌘ Return)", bundle: Bundle.module, comment: ""))
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                HStack {
                    Text(NSLocalizedString("From", bundle: Bundle.module, comment: ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    sourceCasePicker
                        .labelsHidden()
                }
                HStack {
                    Text(NSLocalizedString("To", bundle: Bundle.module, comment: ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    targetCasePicker
                        .labelsHidden()
                }
                HStack {
                    Text(NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    separatorPicker
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                switchCasesButton
                convertButton
            }
            .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("From", bundle: Bundle.module, comment: ""))
                    sourceCasePicker
                        .blissMenuPicker(width: 140)

                    ConfigLabel(NSLocalizedString("To", bundle: Bundle.module, comment: ""))
                    targetCasePicker
                        .blissMenuPicker(width: 140)
                }

                GridRow {
                    ConfigLabel(NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""))
                    separatorPicker
                        .blissMenuPicker(width: 140)
                        .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                switchCasesButton
                convertButton
            }
            .padding(.vertical, 8)
            #endif

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.TextCaseConverter.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.TextCaseConverter.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Input", bundle: Bundle.module, comment: ""))
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Output", bundle: Bundle.module, comment: ""))
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.outputText },
                set: { newValue in model.$outputText.withLock { $0 = newValue } }
            ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
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
