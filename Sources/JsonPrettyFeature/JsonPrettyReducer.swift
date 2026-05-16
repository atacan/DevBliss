import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("jsonPretty"))
        let outputText = Shared(wrappedValue: output, .toolOutput("jsonPretty"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        conversionTask = Task { [weak self, input = inputText, prettyClient = jsonPretty] in
            guard let self else { return }
            do {
                let result = try await prettyClient.convert(input)
                await MainActor.run {
                    isConversionRequestInFlight = false
                    outputText = result
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    outputText = "\(error)"
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

extension JsonPrettyModel: Equatable {
    public static func == (lhs: JsonPrettyModel, rhs: JsonPrettyModel) -> Bool {
        lhs === rhs
    }
}

public struct JsonPrettyModelView: View {
    @Bindable var model: JsonPrettyModel

    public init(model: JsonPrettyModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            LoadingButton(
                NSLocalizedString("Format", bundle: Bundle.module, comment: ""),
                isLoading: model.isConversionRequestInFlight
            ) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Format code (⌘ Return)", bundle: Bundle.module, comment: ""))
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.JsonPretty.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.JsonPretty.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Raw", bundle: Bundle.module, comment: ""))
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
            Text(NSLocalizedString("Pretty", bundle: Bundle.module, comment: ""))
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

public typealias JsonPrettyView = JsonPrettyModelView

struct JsonPrettyView_Previews: PreviewProvider {
    static var previews: some View {
        JsonPrettyModelView(model: .init())
    }
}
