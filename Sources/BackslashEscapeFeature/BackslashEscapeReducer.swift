import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class BackslashEscapeModel {
    @ObservationIgnored
    @Shared(.toolInput("backslashEscape"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("backslashEscape"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: BackslashEscapeMode = .escape

    @ObservationIgnored
    @Dependency(\.backslashEscape) private var backslashEscape

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("backslashEscape"))
        let outputText = Shared(wrappedValue: "", .toolOutput("backslashEscape"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("backslashEscape"))
        let outputText = Shared(wrappedValue: output, .toolOutput("backslashEscape"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setMode(_ mode: BackslashEscapeMode) {
        self.mode = mode
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let mode = self.mode

        conversionTask = Task { [weak self, input = input, mode = mode, backslashEscape = backslashEscape] in
            guard let self else { return }
            do {
                let result = try await backslashEscape.convert(input, mode)
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

public struct BackslashEscapeModelView: View {
    @Bindable var model: BackslashEscapeModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: BackslashEscapeModel,
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
                fractionKey: SettingsKey.BackslashEscape.splitViewFraction,
                layoutKey: SettingsKey.BackslashEscape.splitViewLayout,
                primaryLabel: "Input",
                secondaryLabel: "Output"
            )
        ) {
            PlainInputTextPane(title: "Input", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "Output",
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

struct BackslashEscapeView_Previews: PreviewProvider {
    static var previews: some View {
        BackslashEscapeModelView(model: .init())
    }
}
