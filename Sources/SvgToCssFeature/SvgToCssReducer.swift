import BlissTheme
import Dependencies
import InputOutput
import Observation
import SharedModels
import Sharing
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
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: SvgToCssModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: "Convert",
            actionHelp: "Convert (⌘ Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.SvgToCss.splitViewFraction,
                layoutKey: SettingsKey.SvgToCss.splitViewLayout,
                primaryLabel: "SVG",
                secondaryLabel: "CSS"
            )
        ) {
            configurationView
        } primary: {
            PlainInputTextPane(title: "SVG", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "CSS",
                text: outputTextBinding,
                onSendToTool: sendOutputToTool
            )
        }
    }

    private var configurationView: some View {
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

    private var outputTextBinding: Binding<String> {
        Binding(
            get: { model.outputText },
            set: { newValue in model.$outputText.withLock { $0 = newValue } }
        )
    }
}

struct SvgToCssView_Previews: PreviewProvider {
    static var previews: some View {
        SvgToCssModelView(model: .init())
    }
}
