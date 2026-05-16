import BlissTheme
import Foundation
import Dependencies
import SharedModels
import Sharing
import SwiftUI
import Observation
import SplitView

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

    public init(model: JsonToYamlModel) {
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
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.JsonToYaml.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.JsonToYaml.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JSON")
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
            Text("YAML")
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
