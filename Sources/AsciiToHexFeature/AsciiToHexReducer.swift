import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class AsciiToHexModel {
    @ObservationIgnored
    @Shared(.toolInput("asciiToHex"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("asciiToHex"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var uppercase: Bool = true
    public var separator: HexSeparator = .space

    @ObservationIgnored
    @Dependency(\.asciiToHex) private var asciiToHex

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var config: AsciiToHexConfig {
        AsciiToHexConfig(uppercase: uppercase, separator: separator)
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("asciiToHex"))
        let outputText = Shared(wrappedValue: "", .toolOutput("asciiToHex"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("asciiToHex"))
        let outputText = Shared(wrappedValue: output, .toolOutput("asciiToHex"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setUppercase(_ enabled: Bool) {
        uppercase = enabled
    }

    public func setSeparator(_ separator: HexSeparator) {
        self.separator = separator
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = self.config

        conversionTask = Task { [weak self, input = input, config = config, asciiToHex = asciiToHex] in
            guard let self else { return }
            do {
                let result = try await asciiToHex.convert(input, config)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = result }
                }
            }
            catch {
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

public struct AsciiToHexModelView: View {
    @Bindable var model: AsciiToHexModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: AsciiToHexModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    private var configurationView: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ConfigLabel("Separator")
                Picker("Separator", selection: $model.separator) {
                    ForEach(HexSeparator.allCases) { separator in Text(separator.rawValue).tag(separator) }
                }
                .blissMenuPicker(width: 120)
                Toggle("Uppercase", isOn: $model.uppercase).toggleStyle(.checkbox)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    public var body: some View {
        TwoPaneToolView(
            actionTitle: "Convert",
            actionHelp: "Convert (⌘ Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.AsciiToHex.splitViewFraction,
                layoutKey: SettingsKey.AsciiToHex.splitViewLayout,
                primaryLabel: "ASCII",
                secondaryLabel: "Hex"
            )
        ) {
            configurationView
        } primary: {
            PlainInputTextPane(title: "ASCII", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "Hex",
                text: outputTextBinding,
                onSendToTool: sendOutputToTool
            )
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

// TODO: delete this file and move to AsciiToHexModelView once the app shell is fully migrated.
struct AsciiToHexView_Previews: PreviewProvider {
    static var previews: some View {
        AsciiToHexModelView(model: AsciiToHexModel())
    }
}
