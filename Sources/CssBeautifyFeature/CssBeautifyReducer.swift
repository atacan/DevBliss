import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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

    public init(model: CssBeautifyModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            LoadingButton(model.mode == .beautify ? "Beautify" : "Minify", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Format (Cmd Return)")
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.CssBeautify.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.CssBeautify.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CSS")
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
