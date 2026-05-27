import BlissTheme
import Foundation
import Dependencies
import SharedModels
import Sharing
import SwiftUI
import Observation
import InputOutput

@MainActor
@Observable
public final class JsonToYamlModel {
    @ObservationIgnored
    @Shared(.toolInput("jsonToYaml"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("jsonToYaml"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var sortKeys: Bool = false
    public var errorText: String?

    public var config: JsonToYamlConfig {
        JsonToYamlConfig(sortKeys: sortKeys)
    }

    @ObservationIgnored
    @Dependency(\.jsonToYaml) private var jsonToYaml

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("jsonToYaml"))
        let outputText = Shared(wrappedValue: "", .toolOutput("jsonToYaml"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(
        input: String,
        output: String = ""
    ) {
        let inputText = Shared(wrappedValue: input, .toolInput("jsonToYaml"))
        let outputText = Shared(wrappedValue: output, .toolOutput("jsonToYaml"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setSortKeys(_ value: Bool) {
        sortKeys = value
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        errorText = nil
        let input = inputText
        let config = self.config
        conversionTask = Task { [weak self, input = input, config = config, jsonToYaml = jsonToYaml] in
            guard let self else { return }
            do {
                let yaml = try await jsonToYaml.convert(input, config)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = yaml }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.errorText = error.localizedDescription
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

struct JsonToYamlView_Previews: PreviewProvider {
    static var previews: some View {
        JsonToYamlModelView(model: .init())
    }
}

public struct JsonToYamlModelView: View {
    @Bindable var model: JsonToYamlModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: JsonToYamlModel,
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
                fractionKey: SettingsKey.JsonToYaml.splitViewFraction,
                layoutKey: SettingsKey.JsonToYaml.splitViewLayout,
                primaryLabel: "JSON",
                secondaryLabel: "YAML"
            )
        ) {
            PlainInputTextPane(title: "JSON", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "YAML",
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
