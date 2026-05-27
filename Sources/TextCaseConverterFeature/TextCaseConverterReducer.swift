import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
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

public struct TextCaseConverterModelView: View {
    @Bindable var model: TextCaseConverterModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: TextCaseConverterModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    private var configurationView: some View {
        ViewThatFits(in: .horizontal) {
            regularConfigurationView
            compactConfigurationView
        }
        .padding(.horizontal, configurationHorizontalPadding)
        .padding(.vertical, configurationVerticalPadding)
    }

    private var regularConfigurationView: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                ConfigLabel(NSLocalizedString("From", bundle: Bundle.module, comment: ""))
                sourceCasePicker
                    .blissMenuPicker(width: 140)

                switchCasesButton

                ConfigLabel(NSLocalizedString("To", bundle: Bundle.module, comment: ""))
                targetCasePicker
                    .blissMenuPicker(width: 140)
            }

            GridRow {
                ConfigLabel(NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""))
                separatorPicker
                    .blissMenuPicker(width: 140)
                    .gridCellColumns(4)
            }
        }
    }

    private var compactConfigurationView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                sourceCasePicker
                    .blissMenuPicker(width: 128)

                switchCasesButton

                targetCasePicker
                    .blissMenuPicker(width: 128)
            }

            HStack(spacing: 8) {
                ConfigLabel(NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""))
                separatorPicker
                    .blissMenuPicker(width: 150)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var sourceCasePicker: some View {
        Picker(
            NSLocalizedString("From", bundle: Bundle.module, comment: ""),
            selection: Binding(get: { model.sourceCase }, set: { model.setSourceCase($0) })
        ) {
            ForEach(WordGroupCase.allCases) { Text($0.rawValue).tag($0) }
        }
    }

    private var targetCasePicker: some View {
        Picker(
            NSLocalizedString("To", bundle: Bundle.module, comment: ""),
            selection: Binding(get: { model.targetCase }, set: { model.setTargetCase($0) })
        ) {
            ForEach(WordGroupCase.allCases) { Text($0.rawValue).tag($0) }
        }
    }

    private var separatorPicker: some View {
        Picker(
            NSLocalizedString("Seperator", bundle: Bundle.module, comment: ""),
            selection: Binding(get: { model.textSeperator }, set: { model.setTextSeperator($0) })
        ) {
            ForEach(WordGroupSeperator.allCases) { Text($0 == .newLine ? "New Line" : "Space").tag($0) }
        }
    }

    private var switchCasesButton: some View {
        Button { model.switchCases() } label: {
            Image(systemName: "arrow.left.and.right")
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("w", modifiers: [.command, .shift])
        .help(NSLocalizedString("Switch Cases", bundle: Bundle.module, comment: ""))
        .accessibilityLabel(NSLocalizedString("Switch Cases", bundle: Bundle.module, comment: ""))
    }

    private var configurationHorizontalPadding: CGFloat {
        #if os(iOS)
            return 10
        #else
            return 16
        #endif
    }

    private var configurationVerticalPadding: CGFloat {
        #if os(iOS)
            return 6
        #else
            return 8
        #endif
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
            actionHelp: NSLocalizedString("Convert code (⌘ Return)", bundle: Bundle.module, comment: ""),
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(fractionKey: SettingsKey.TextCaseConverter.splitViewFraction, layoutKey: SettingsKey.TextCaseConverter.splitViewLayout, primaryLabel: NSLocalizedString("Input", bundle: Bundle.module, comment: ""), secondaryLabel: NSLocalizedString("Output", bundle: Bundle.module, comment: ""))
        ) { configurationView } primary: {
            PlainInputTextPane(title: NSLocalizedString("Input", bundle: Bundle.module, comment: ""), text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(title: NSLocalizedString("Output", bundle: Bundle.module, comment: ""), text: outputTextBinding, onSendToTool: sendOutputToTool)
        }
    }
    private var sendOutputToTool: ((Tool) -> Void)? {
        guard let onSendOutputToTool else { return nil }
        return { tool in onSendOutputToTool(model.outputText, tool) }
    }

    private var inputTextBinding: Binding<String> {
        Binding(
            get: { model.inputText },
            set: { newValue in model.$inputText.withLock { $0 = newValue } }
        )
    }

    private var outputTextBinding: Binding<String> {
        Binding(
            get: { model.outputText },
            set: { newValue in model.$outputText.withLock { $0 = newValue } }
        )
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
