import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class YamlToJsonModel {
    @ObservationIgnored
    @Shared(.toolInput("yamlToJson"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("yamlToJson"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var prettyPrinted: Bool = true

    public var config: YamlToJsonConfig {
        YamlToJsonConfig(prettyPrinted: prettyPrinted)
    }

    @ObservationIgnored
    @Dependency(\.yamlToJson) private var yamlToJson

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("yamlToJson"))
        let outputText = Shared(wrappedValue: "", .toolOutput("yamlToJson"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(
        input: String,
        output: String = ""
    ) {
        let inputText = Shared(wrappedValue: input, .toolInput("yamlToJson"))
        let outputText = Shared(wrappedValue: output, .toolOutput("yamlToJson"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = self.config
        conversionTask = Task { [weak self, input = input, config = config, yamlToJson = yamlToJson] in
            guard let self else { return }
            do {
                let result = try await yamlToJson.convert(input, config)
                await MainActor.run {
                    isConversionRequestInFlight = false
                    $outputText.withLock { $0 = result }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    $outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func setPrettyPrinted(_ value: Bool) {
        prettyPrinted = value
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

struct YamlToJsonView_Previews: PreviewProvider {
    static var previews: some View {
        YamlToJsonModelView(model: .init())
    }
}

public struct YamlToJsonModelView: View {
    @Bindable var model: YamlToJsonModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: YamlToJsonModel,
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
                fractionKey: SettingsKey.YamlToJson.splitViewFraction,
                layoutKey: SettingsKey.YamlToJson.splitViewLayout,
                primaryLabel: "YAML",
                secondaryLabel: "JSON"
            )
        ) {
            PlainInputTextPane(title: "YAML", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "JSON",
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
