import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class XmlFormatModel {
    @ObservationIgnored
    @Shared(.toolInput("xmlFormat"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("xmlFormat"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: XmlFormatMode = .beautify

    @ObservationIgnored
    @Dependency(\.xmlFormat) private var xmlFormat

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("xmlFormat"))
        let outputText = Shared(wrappedValue: "", .toolOutput("xmlFormat"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("xmlFormat"))
        let outputText = Shared(wrappedValue: output, .toolOutput("xmlFormat"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let mode = self.mode

        conversionTask = Task { [weak self, input = input, mode = mode, xmlFormat = xmlFormat] in
            guard let self else { return }
            do {
                let result = try await xmlFormat.format(input, mode)
                await MainActor.run {
                    isConversionRequestInFlight = false
                    $outputText.withLock { $0 = result }
                }
            }
            catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    $outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func setMode(_ mode: XmlFormatMode) {
        self.mode = mode
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

struct XmlFormatView_Previews: PreviewProvider {
    static var previews: some View {
        XmlFormatModelView(model: .init())
    }
}

public struct XmlFormatModelView: View {
    @Bindable var model: XmlFormatModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: XmlFormatModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    private var configurationView: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Picker("Mode", selection: $model.mode) {
                    ForEach(XmlFormatMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    public var body: some View {
        TwoPaneToolView(
            actionTitle: "Format",
            actionHelp: "Format (⌘ Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.XmlFormat.splitViewFraction,
                layoutKey: SettingsKey.XmlFormat.splitViewLayout,
                primaryLabel: "XML",
                secondaryLabel: "Result"
            )
        ) {
            configurationView
        } primary: {
            PlainInputTextPane(title: "XML", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "Result",
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

struct XmlFormatModelView_Previews: PreviewProvider {
    static var previews: some View {
        XmlFormatModelView(model: .init())
    }
}
