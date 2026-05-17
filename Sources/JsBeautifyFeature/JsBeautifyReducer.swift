import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class JsBeautifyModel {
    @ObservationIgnored
    @Shared(.toolInput("jsBeautify"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("jsBeautify"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: JsBeautifyMode = .beautify

    @ObservationIgnored
    @Dependency(\.jsBeautify) private var jsBeautify

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("jsBeautify"))
        let outputText = Shared(wrappedValue: "", .toolOutput("jsBeautify"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("jsBeautify"))
        let outputText = Shared(wrappedValue: output, .toolOutput("jsBeautify"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let mode = self.mode

        conversionTask = Task { [weak self, input = input, mode = mode, jsBeautify = jsBeautify] in
            guard let self else { return }
            do {
                let result = try await jsBeautify.format(input, mode)
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

    public func setMode(_ mode: JsBeautifyMode) {
        self.mode = mode
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

struct JsBeautifyView_Previews: PreviewProvider {
    static var previews: some View {
        JsBeautifyModelView(model: .init())
    }
}

public struct JsBeautifyModelView: View {
    @Bindable var model: JsBeautifyModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: JsBeautifyModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: model.mode == .beautify ? "Format" : "Minify",
            actionHelp: "Format (Cmd Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.JsBeautify.splitViewFraction,
                layoutKey: SettingsKey.JsBeautify.splitViewLayout,
                primaryLabel: "JavaScript",
                secondaryLabel: "Result"
            )
        ) {
            PlainInputTextPane(title: "JavaScript", text: inputTextBinding)
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
