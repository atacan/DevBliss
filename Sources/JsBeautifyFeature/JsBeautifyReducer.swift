import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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

    public init(model: JsBeautifyModel) {
        self.model = model
    }

    private var convertButton: some View {
        LoadingButton(model.mode == .beautify ? "Format" : "Minify", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Format (Cmd Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            convertButton
                .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.JsBeautify.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.JsBeautify.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JavaScript")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Result")
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
