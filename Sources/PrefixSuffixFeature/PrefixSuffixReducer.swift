import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class PrefixSuffixModel {
    @ObservationIgnored
    @Shared(.toolInput("prefixSuffix")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("prefixSuffix")) public var outputText = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.prefixReplace))
    public var prefixReplace: String = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.prefixReplaceWith))
    public var prefixReplaceWith: String = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.prefixAdd))
    public var prefixAdd: String = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.suffixReplace))
    public var suffixReplace: String = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.suffixReplaceWith))
    public var suffixReplaceWith: String = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.suffixAdd))
    public var suffixAdd: String = ""

    @ObservationIgnored
    @Shared(.appStorage(SettingsKey.PrefixSuffix.trimWhiteSpace))
    public var trimWhiteSpace: Bool = true

    public var isConversionRequestInFlight = false
    public var configuration: PrefixSuffixConfig {
        get {
            .init(
                prefixReplace: prefixReplace,
                prefixReplaceWith: prefixReplaceWith,
                prefixAdd: prefixAdd,
                suffixReplace: suffixReplace,
                suffixReplaceWith: suffixReplaceWith,
                suffixAdd: suffixAdd,
                trimWhiteSpace: trimWhiteSpace
            )
        }
        set {
            $prefixReplace.withLock { $0 = newValue.prefixReplace }
            $prefixReplaceWith.withLock { $0 = newValue.prefixReplaceWith }
            $prefixAdd.withLock { $0 = newValue.prefixAdd }
            $suffixReplace.withLock { $0 = newValue.suffixReplace }
            $suffixReplaceWith.withLock { $0 = newValue.suffixReplaceWith }
            $suffixAdd.withLock { $0 = newValue.suffixAdd }
            $trimWhiteSpace.withLock { $0 = newValue.trimWhiteSpace }
        }
    }

    @ObservationIgnored
    @Dependency(\.prefixSuffix) private var prefixSuffix

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("prefixSuffix"))
        let outputText = Shared(wrappedValue: "", .toolOutput("prefixSuffix"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(
        input: String,
        output: String = ""
    ) {
        let inputText = Shared(wrappedValue: input, .toolInput("prefixSuffix"))
        let outputText = Shared(wrappedValue: output, .toolOutput("prefixSuffix"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = configuration
        conversionTask = Task { [weak self, input = input, config = config, prefixSuffix = prefixSuffix] in
            guard let self else { return }
            do {
                let result = try await prefixSuffix.convert(input, config)
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

// TODO: delete this file once all legacy App shell cases are fully migrated.

public struct PrefixSuffixModelView: View {
    @Bindable var model: PrefixSuffixModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?
    @FocusState private var focusedField: Field?

    enum Field: Int, Hashable { case prefixReplace, prefixReplaceWith, prefixAdd, suffixReplace, suffixReplaceWith, suffixAdd }

    public init(model: PrefixSuffixModel, onSendOutputToTool: ((String, Tool) -> Void)? = nil) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    private var configurationView: some View {
        VStack {
            HStack(alignment: .center) {
                VStack {
                    Text(NSLocalizedString("Prefix", bundle: Bundle.module, comment: ""))
                    TextField(NSLocalizedString("Replace prefix", bundle: Bundle.module, comment: ""), text: Binding(get: { model.prefixReplace }, set: { newValue in model.$prefixReplace.withLock { $0 = newValue } }))
                    TextField(NSLocalizedString("with", bundle: Bundle.module, comment: ""), text: Binding(get: { model.prefixReplaceWith }, set: { newValue in model.$prefixReplaceWith.withLock { $0 = newValue } }))
                    TextField(NSLocalizedString("Then add Prefix", bundle: Bundle.module, comment: ""), text: Binding(get: { model.prefixAdd }, set: { newValue in model.$prefixAdd.withLock { $0 = newValue } }))
                }
                VStack {
                    Text(NSLocalizedString("Suffix", bundle: Bundle.module, comment: ""))
                    TextField(NSLocalizedString("Replace suffix", bundle: Bundle.module, comment: ""), text: Binding(get: { model.suffixReplace }, set: { newValue in model.$suffixReplace.withLock { $0 = newValue } }))
                    TextField(NSLocalizedString("with", bundle: Bundle.module, comment: ""), text: Binding(get: { model.suffixReplaceWith }, set: { newValue in model.$suffixReplaceWith.withLock { $0 = newValue } }))
                    TextField(NSLocalizedString("Then add Suffix", bundle: Bundle.module, comment: ""), text: Binding(get: { model.suffixAdd }, set: { newValue in model.$suffixAdd.withLock { $0 = newValue } }))
                }
            }
            .font(.monospaced(.body)())
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 16)
            .frame(maxWidth: 850)
            Toggle(NSLocalizedString("Trim whitespace", bundle: Bundle.module, comment: ""), isOn: Binding(get: { model.trimWhiteSpace }, set: { newValue in model.$trimWhiteSpace.withLock { $0 = newValue } }))
        }
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
            actionHelp: NSLocalizedString("Convert (Cmd+Return)", bundle: Bundle.module, comment: ""),
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(fractionKey: SettingsKey.PrefixSuffix.splitViewFraction, layoutKey: SettingsKey.PrefixSuffix.splitViewLayout, primaryLabel: "Input", secondaryLabel: "Output")
        ) { configurationView } primary: {
            PlainInputTextPane(title: "Input", text: inputTextBinding, minHeight: 140)
        } secondary: {
            PlainOutputTextPane(title: "Output", text: outputTextBinding, minHeight: 140, onSendToTool: sendOutputToTool)
        }
        .onAppear { focusedField = .prefixReplace }
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

// preview
struct PrefixSuffixReducer_Previews: PreviewProvider {
    static var previews: some View {
        PrefixSuffixModelView(model: .init())
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
