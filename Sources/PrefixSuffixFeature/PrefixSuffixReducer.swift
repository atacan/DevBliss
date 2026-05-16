import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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
            prefixReplace = newValue.prefixReplace
            prefixReplaceWith = newValue.prefixReplaceWith
            prefixAdd = newValue.prefixAdd
            suffixReplace = newValue.suffixReplace
            suffixReplaceWith = newValue.suffixReplaceWith
            suffixAdd = newValue.suffixAdd
            trimWhiteSpace = newValue.trimWhiteSpace
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
                    isConversionRequestInFlight = false
                    outputText = result
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    outputText = error.localizedDescription
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

extension PrefixSuffixModel: Equatable {
    public static func == (lhs: PrefixSuffixModel, rhs: PrefixSuffixModel) -> Bool {
        lhs === rhs
    }
}

// TODO: delete this file once all legacy App shell cases are fully migrated.

public struct PrefixSuffixModelView: View {
    @Bindable var model: PrefixSuffixModel

    @FocusState private var focusedField: Field?
    enum Field: Int, Hashable {
        case prefixReplace
        case prefixReplaceWith
        case prefixAdd
        case suffixReplace
        case suffixReplaceWith
        case suffixAdd
    }

    public init(model: PrefixSuffixModel) {
        self.model = model
    }

    private let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.PrefixSuffix.splitViewFraction)
    @StateObject private var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.PrefixSuffix.splitViewLayout)
    @StateObject private var hide = SideHolder()

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
                            text: $model.prefixReplace
                        )
                        .focused($focusedField, equals: .prefixReplace)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Replace prefix if available", bundle: Bundle.module, comment: ""))

                        TextField(
                            NSLocalizedString("with", bundle: Bundle.module, comment: ""),
                            text: $model.prefixReplaceWith
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
                            text: $model.prefixAdd
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
                             text: $model.suffixReplace
                         )
                         .focused($focusedField, equals: .suffixReplace)
                         .onSubmit { focusNextField($focusedField) }
                         .help(NSLocalizedString("Replace suffix if available", bundle: Bundle.module, comment: ""))

                         TextField(
                             NSLocalizedString("with", bundle: Bundle.module, comment: ""),
                             text: $model.suffixReplaceWith
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
                             text: $model.suffixAdd
                         )
                        .focused($focusedField, equals: .suffixAdd)
                        .onSubmit { focusNextField($focusedField) }
                        .help(NSLocalizedString("Then add Suffix", bundle: Bundle.module, comment: ""))
                    }
                    .font(.monospaced(.body)())
                    .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 850)

            Toggle(NSLocalizedString("Trim whitespace", bundle: Bundle.module, comment: ""), isOn: $model.trimWhiteSpace)

            LoadingButton(
                NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
                isLoading: model.isConversionRequestInFlight
            ) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Convert (Cmd+Return)", bundle: Bundle.module, comment: ""))
            .padding(.top)

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
        .onAppear {
            focusedField = .prefixReplace
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: $model.inputText)
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Output")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: $model.outputText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
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
