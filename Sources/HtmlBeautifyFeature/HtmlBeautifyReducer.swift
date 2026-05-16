import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class HtmlBeautifyModel {
    @ObservationIgnored
    @Shared(.toolInput("htmlBeautify"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("htmlBeautify"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: HtmlBeautifyMode = .beautify

    @ObservationIgnored
    @Dependency(\.htmlBeautify) private var htmlBeautify

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("htmlBeautify"))
        let outputText = Shared(wrappedValue: "", .toolOutput("htmlBeautify"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("htmlBeautify"))
        let outputText = Shared(wrappedValue: output, .toolOutput("htmlBeautify"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let mode = self.mode

        conversionTask = Task { [weak self, input = input, mode = mode, htmlBeautify = htmlBeautify] in
            guard let self else { return }
            do {
                let result = try await htmlBeautify.format(input, mode)
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

    public func setMode(_ mode: HtmlBeautifyMode) {
        self.mode = mode
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

extension HtmlBeautifyModel: Equatable {
    public static func == (lhs: HtmlBeautifyModel, rhs: HtmlBeautifyModel) -> Bool {
        lhs === rhs
    }
}

struct HtmlBeautifyView_Previews: PreviewProvider {
    static var previews: some View {
        HtmlBeautifyModelView(model: .init())
    }
}

public struct HtmlBeautifyModelView: View {
    @Bindable var model: HtmlBeautifyModel

    public init(model: HtmlBeautifyModel) {
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
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HtmlBeautify.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HtmlBeautify.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HTML")
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
