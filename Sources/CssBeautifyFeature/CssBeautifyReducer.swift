import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class CssBeautifyModel {
    @ObservationIgnored
    @Shared(.toolInput("cssBeautify"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("cssBeautify"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: CssBeautifyMode = .beautify

    @ObservationIgnored
    @Dependency(\.cssBeautify) private var cssBeautify

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("cssBeautify"))
        let outputText = Shared(wrappedValue: "", .toolOutput("cssBeautify"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("cssBeautify"))
        let outputText = Shared(wrappedValue: output, .toolOutput("cssBeautify"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let mode = self.mode

        conversionTask = Task { [weak self, input = input, mode = mode, cssBeautify = cssBeautify] in
            guard let self else { return }
            do {
                let result = try await cssBeautify.format(input, mode)
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

    public func setMode(_ mode: CssBeautifyMode) {
        self.mode = mode
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

struct CssBeautifyView_Previews: PreviewProvider {
    static var previews: some View {
        CssBeautifyModelView(model: .init())
    }
}

public struct CssBeautifyModelView: View {
    @Bindable var model: CssBeautifyModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: CssBeautifyModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: model.mode == .beautify ? "Beautify" : "Minify",
            actionHelp: "Beautify (Cmd Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.CssBeautify.splitViewFraction,
                layoutKey: SettingsKey.CssBeautify.splitViewLayout,
                primaryLabel: "CSS",
                secondaryLabel: "Result"
            )
        ) {
            PlainInputTextPane(title: "CSS", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "Result",
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
