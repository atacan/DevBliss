import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class HexToAsciiModel {
    @ObservationIgnored
    @Shared(.toolInput("hexToAscii"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("hexToAscii"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var allowSeparators: Bool = true

    @ObservationIgnored
    @Dependency(\.hexToAscii) private var hexToAscii

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var config: HexToAsciiConfig {
        HexToAsciiConfig(allowSeparators: allowSeparators)
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("hexToAscii"))
        let outputText = Shared(wrappedValue: "", .toolOutput("hexToAscii"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("hexToAscii"))
        let outputText = Shared(wrappedValue: output, .toolOutput("hexToAscii"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setAllowSeparators(_ enabled: Bool) {
        allowSeparators = enabled
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = self.config

        conversionTask = Task { [weak self, input = input, config = config, hexToAscii = hexToAscii] in
            guard let self else { return }
            do {
                let result = try await hexToAscii.convert(input, config)
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

public struct HexToAsciiModelView: View {
    @Bindable var model: HexToAsciiModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: HexToAsciiModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: "Convert",
            actionHelp: "Convert (Cmd Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.HexToAscii.splitViewFraction,
                layoutKey: SettingsKey.HexToAscii.splitViewLayout,
                primaryLabel: "Hex",
                secondaryLabel: "ASCII"
            )
        ) {
            PlainInputTextPane(title: "Hex", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "ASCII",
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

struct HexToAsciiView_Previews: PreviewProvider {
    static var previews: some View {
        HexToAsciiModelView(model: .init())
    }
}
