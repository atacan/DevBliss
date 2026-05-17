import BlissTheme
import Dependencies
import Foundation
import InputOutput
import Observation
import SharedModels
import Sharing
import SwiftUI

@MainActor
@Observable
public final class JsonPrettyModel {
    @ObservationIgnored
    @Shared(.toolInput("jsonPretty"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("jsonPretty"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var outputAttributedText = NSMutableAttributedString()

    @ObservationIgnored
    @Dependency(\.jsonPretty)
    private var jsonPretty

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("jsonPretty"))
        let outputText = Shared(wrappedValue: "", .toolOutput("jsonPretty"))
        self._inputText = inputText
        self._outputText = outputText
        self.outputAttributedText = .init(attributedString: EditorAttributedStrings.regular(outputText.wrappedValue))
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("jsonPretty"))
        let outputText = Shared(wrappedValue: output, .toolOutput("jsonPretty"))
        self._inputText = inputText
        self._outputText = outputText
        self.outputAttributedText = .init(attributedString: EditorAttributedStrings.regular(outputText.wrappedValue))
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        conversionTask = Task { [weak self, input = inputText, prettyClient = jsonPretty] in
            guard let self else { return }
            do {
                let result = try await prettyClient.convert(input)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.updateOutput(result.string, attributedText: result)
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.updateOutput(
                        "\(error)",
                        attributedText: EditorAttributedStrings.error("\(error)")
                    )
                }
            }
        }
    }

    public func setOutputAttributedText(_ value: NSMutableAttributedString) {
        outputAttributedText = value
        $outputText.withLock { $0 = value.string }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }

    private func updateOutput(_ text: String, attributedText: NSAttributedString? = nil) {
        $outputText.withLock { $0 = text }
        outputAttributedText = .init(attributedString: attributedText ?? EditorAttributedStrings.regular(text))
    }
}

public struct JsonPrettyModelView: View {
    @Bindable var model: JsonPrettyModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: JsonPrettyModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: NSLocalizedString("Format", bundle: Bundle.module, comment: ""),
            actionHelp: NSLocalizedString("Format code (⌘ Return)", bundle: Bundle.module, comment: ""),
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.JsonPretty.splitViewFraction,
                layoutKey: SettingsKey.JsonPretty.splitViewLayout,
                primaryLabel: NSLocalizedString("Raw", bundle: Bundle.module, comment: ""),
                secondaryLabel: NSLocalizedString("Pretty", bundle: Bundle.module, comment: "")
            )
        ) {
            PlainInputTextPane(
                title: NSLocalizedString("Raw", bundle: Bundle.module, comment: ""),
                text: inputTextBinding
            )
        } secondary: {
            AttributedOutputTextPane(
                title: NSLocalizedString("Pretty", bundle: Bundle.module, comment: ""),
                attributedText: outputAttributedTextBinding,
                plainText: { model.outputText },
                onSendToTool: sendOutputToTool
            )
        }
    }

    private var sendOutputToTool: ((Tool) -> Void)? {
        guard let onSendOutputToTool else {
            return nil
        }

        return { tool in
            onSendOutputToTool(model.outputText, tool)
        }
    }

    private var inputTextBinding: Binding<String> {
        Binding(
            get: { model.inputText },
            set: { newValue in model.$inputText.withLock { $0 = newValue } }
        )
    }

    private var outputAttributedTextBinding: Binding<NSMutableAttributedString> {
        Binding(
            get: { model.outputAttributedText },
            set: { model.setOutputAttributedText($0) }
        )
    }
}

public typealias JsonPrettyView = JsonPrettyModelView

struct JsonPrettyView_Previews: PreviewProvider {
    static var previews: some View {
        JsonPrettyModelView(model: .init())
    }
}
