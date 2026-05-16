import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class SvgToCssModel {
    @ObservationIgnored
    @Shared(.toolInput("svgToCss"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("svgToCss"))
    public var outputText = ""

    @ObservationIgnored
    public var includeDataPrefix = true

    @ObservationIgnored
    public var wrapWithCss = true

    public var isConversionRequestInFlight = false

    @ObservationIgnored
    @Dependency(\.svgToCss) private var svgToCss

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("svgToCss"))
        let outputText = Shared(wrappedValue: "", .toolOutput("svgToCss"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("svgToCss"))
        let outputText = Shared(wrappedValue: output, .toolOutput("svgToCss"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true

        let input = inputText
        let config = SvgToCssConfig(includeDataPrefix: includeDataPrefix, wrapWithCss: wrapWithCss)

        conversionTask = Task { [weak self, input = input, config = config, svgToCss = svgToCss] in
            guard let self else { return }
            do {
                let result = try await svgToCss.convert(input, config)
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

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

public struct SvgToCssModelView: View {
    @Bindable var model: SvgToCssModel

    public init(model: SvgToCssModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Toggle("Include data: prefix", isOn: $model.includeDataPrefix)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif

                    Toggle("Wrap in CSS", isOn: $model.wrapWithCss)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.SvgToCss.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.SvgToCss.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SVG")
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
            Text("CSS")
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

struct SvgToCssView_Previews: PreviewProvider {
    static var previews: some View {
        SvgToCssModelView(model: .init())
    }
}
