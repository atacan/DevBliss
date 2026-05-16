import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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

    public func setPrettyPrinted(_ value: Bool) {
        prettyPrinted = value
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

extension YamlToJsonModel: Equatable {
    public static func == (lhs: YamlToJsonModel, rhs: YamlToJsonModel) -> Bool {
        lhs === rhs
    }
}

struct YamlToJsonView_Previews: PreviewProvider {
    static var previews: some View {
        YamlToJsonModelView(model: .init())
    }
}

public struct YamlToJsonModelView: View {
    @Bindable var model: YamlToJsonModel

    public init(model: YamlToJsonModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.YamlToJson.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.YamlToJson.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YAML")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: $model.inputText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JSON")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: $model.outputText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }
}
