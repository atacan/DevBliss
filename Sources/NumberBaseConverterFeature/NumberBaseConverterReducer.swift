import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class NumberBaseConverterModel {
    @ObservationIgnored
    @Shared(.toolInput("numberBaseConverter"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("numberBaseConverter"))
    public var outputText = ""

    public var fromBase: NumberBase = .decimal
    public var isConversionRequestInFlight = false
    public var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.numberBaseConverter) private var numberBaseConverter

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("numberBaseConverter"))
        let outputText = Shared(wrappedValue: "", .toolOutput("numberBaseConverter"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(
        input: String,
        output: String = ""
    ) {
        let inputText = Shared(wrappedValue: input, .toolInput("numberBaseConverter"))
        let outputText = Shared(wrappedValue: output, .toolOutput("numberBaseConverter"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setFromBase(_ fromBase: NumberBase) {
        self.fromBase = fromBase
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        errorMessage = nil
        let input = inputText
        let fromBase = self.fromBase
        conversionTask = Task { [weak self, input = input, fromBase = fromBase, numberBaseConverter = numberBaseConverter] in
            guard let self else { return }
            do {
                let result = try await numberBaseConverter.convert(input, fromBase)
                let output = format(result: result)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = output }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.errorMessage = error.localizedDescription
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

    private func format(result: NumberBaseResult) -> String {
        [
            "Binary: \(result.binary)",
            "Octal: \(result.octal)",
            "Decimal: \(result.decimal)",
            "Hex: \(result.hex)",
        ]
        .joined(separator: "\n")
    }
}

extension NumberBaseConverterModel: Equatable {
    public static func == (lhs: NumberBaseConverterModel, rhs: NumberBaseConverterModel) -> Bool {
        lhs === rhs
    }
}

public struct NumberBaseConverterModelView: View {
    @Bindable var model: NumberBaseConverterModel

    public init(model: NumberBaseConverterModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Input Base")
                    Picker("Base", selection: $model.fromBase) {
                        ForEach(NumberBase.allCases) { base in
                            Text(base.label)
                                .tag(base)
                        }
                    }
                    .blissMenuPicker(width: 140)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.NumberBaseConverter.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.NumberBaseConverter.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input")
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
            Text("Converted")
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

struct NumberBaseConverterView_Previews: PreviewProvider {
    static var previews: some View {
        NumberBaseConverterModelView(model: .init())
    }
}
