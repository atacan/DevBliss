import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class Base64Model {
    @ObservationIgnored
    @Shared(.toolInput("base64"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("base64"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: Base64Mode = .encode
    public var autoDetect: Bool = true
    public var autoRemoveDataURLPrefix: Bool = true
    public var autoRemoveNullBytes: Bool = true

    @ObservationIgnored
    @Dependency(\.base64) private var base64

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var config: Base64Config {
        Base64Config(
            autoDetect: autoDetect,
            autoRemoveDataURLPrefix: autoRemoveDataURLPrefix,
            autoRemoveNullBytes: autoRemoveNullBytes
        )
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("base64"))
        let outputText = Shared(wrappedValue: "", .toolOutput("base64"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("base64"))
        let outputText = Shared(wrappedValue: output, .toolOutput("base64"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setMode(_ mode: Base64Mode) {
        self.mode = mode
    }

    public func setAutoDetect(_ isEnabled: Bool) {
        autoDetect = isEnabled
    }

    public func setAutoRemoveDataURLPrefix(_ isEnabled: Bool) {
        autoRemoveDataURLPrefix = isEnabled
    }

    public func setAutoRemoveNullBytes(_ isEnabled: Bool) {
        autoRemoveNullBytes = isEnabled
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let selectedMode = mode
        let config = self.config

        conversionTask = Task { [weak self, input = input, selectedMode = selectedMode, config = config, base64 = base64] in
            guard let self else { return }
            do {
                let result: String
                switch selectedMode {
                case .encode:
                    result = try await base64.encode(input)
                case .decode:
                    result = try await base64.decode(input, config)
                }

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

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

// MARK: - Preview

struct Base64Model_Previews: PreviewProvider {
    static var previews: some View {
        Base64ModelView(model: .init())
    }
}

public struct Base64ModelView: View {
    @Bindable var model: Base64Model
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: Base64Model,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    private var configurationView: some View {
        VStack(spacing: 4) {
            Picker("Mode", selection: $model.mode) {
                ForEach(Base64Mode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 160)
            HStack(spacing: 16) {
                Toggle("Auto-detect", isOn: $model.autoDetect).help("Automatically detect if input is Base64 and switch mode")
                Toggle("Strip data URL", isOn: $model.autoRemoveDataURLPrefix).help("Remove data:...;base64, prefix when decoding")
                Toggle("Strip null bytes", isOn: $model.autoRemoveNullBytes).help("Remove null bytes at the end of decoded string")
            }
            .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    public var body: some View {
        TwoPaneToolView(
            actionTitle: model.mode == .encode ? "Encode" : "Decode",
            actionHelp: "Convert (⌘ Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.Base64.splitViewFraction,
                layoutKey: SettingsKey.Base64.splitViewLayout,
                primaryLabel: "Input",
                secondaryLabel: "Output"
            )
        ) {
            configurationView
        } primary: {
            PlainInputTextPane(title: "Input", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "Output",
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
