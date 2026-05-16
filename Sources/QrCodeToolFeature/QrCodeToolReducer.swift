import BlissTheme
import Dependencies
import QRCode
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class QrCodeToolModel {
    public enum Mode: String, CaseIterable, Identifiable {
        case generate = "Generate"
        case decode = "Decode"

        public var id: Self { self }
    }

    @ObservationIgnored
    @Shared(.toolInput("qrCodeTool"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("qrCodeTool"))
    public var outputText = ""

    public var mode: Mode = .generate
    public var errorCorrection: QrCodeErrorCorrection = .high
    public var dimension: Int = 256
    public var decodedMessages: [String] = []
    public var errorMessage: String?
    public var isConversionRequestInFlight = false

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    @ObservationIgnored
    @Dependency(\.qrCodeTool) private var qrCodeTool

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("qrCodeTool"))
        let outputText = Shared(wrappedValue: "", .toolOutput("qrCodeTool"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(inputText: String, outputText: String = "") {
        let input = Shared(wrappedValue: inputText, .toolInput("qrCodeTool"))
        let output = Shared(wrappedValue: outputText, .toolOutput("qrCodeTool"))
        self._inputText = input
        self._outputText = output
    }

    public var config: QrCodeGenerationConfig {
        QrCodeGenerationConfig(dimension: dimension, errorCorrection: errorCorrection)
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = true
        errorMessage = nil

        let input = inputText
        let mode = mode
        let config = config
        let qrCodeTool = qrCodeTool

        conversionTask = Task { [weak self, input = input, mode = mode, config = config, qrCodeTool = qrCodeTool] in
            guard let self else { return }
            do {
                if mode == .generate {
                    let result = try await qrCodeTool.generate(input, config)
                    await MainActor.run {
                        self.isConversionRequestInFlight = false
                        self.decodedMessages = []
                        self.$outputText.withLock { $0 = result.base64PNG }
                    }
                } else {
                    let messages = try await qrCodeTool.decode(input)
                    await MainActor.run {
                        self.isConversionRequestInFlight = false
                        self.decodedMessages = messages
                        self.$outputText.withLock { $0 = messages.joined(separator: "\n") }
                    }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    if mode == .decode {
                        self.decodedMessages = []
                    }
                    self.errorMessage = error.localizedDescription
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

public struct QrCodeToolView: View {
    @Bindable var model: QrCodeToolModel
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.QrCodeTool.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.QrCodeTool.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: QrCodeToolModel) {
        self.model = model
    }

    private var modePicker: some View {
        Picker("Mode", selection: $model.mode) {
            ForEach(QrCodeToolModel.Mode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    private var correctionPicker: some View {
        Picker("Correction", selection: $model.errorCorrection) {
            ForEach(QrCodeErrorCorrection.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
    }

    private var sizeStepper: some View {
        Stepper("Size \(model.dimension)", value: $model.dimension, in: 128...1024, step: 64)
    }

    private var actionButton: some View {
        LoadingButton(model.mode == .generate ? "Generate" : "Decode", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                modePicker
                if model.mode == .generate {
                    HStack {
                        Text("Correction")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        correctionPicker
                            .labelsHidden()
                        Spacer()
                    }
                    sizeStepper
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            actionButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    modePicker
                        .frame(width: 200)

                    if model.mode == .generate {
                        ConfigLabel("Correction")
                        correctionPicker
                            .blissMenuPicker(width: 140)

                        ConfigLabel("Size")
                        sizeStepper
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            actionButton
                .padding(.vertical, 8)
            #endif

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Split(primary: { inputEditor }, secondary: { outputPane })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.mode == .generate ? "Content" : "Image Path or Base64")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            if model.mode == .generate {
                if model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Spacer()
                    Text("Enter content to generate a QR code")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    QRCodeViewUI(content: model.inputText, errorCorrection: model.errorCorrection.qrCodeValue)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding()
                }
            } else {
                if model.decodedMessages.isEmpty {
                    Spacer()
                    Text("Provide an image path or base64 data to decode")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(model.decodedMessages, id: \.self) { message in
                        Text(message)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Output")
                    .font(.headline)
                    .padding(.horizontal, 8)
                TextEditor(text: Binding(
                    get: { model.outputText },
                    set: { newValue in model.$outputText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
        }
    }
}

struct QrCodeToolView_Previews: PreviewProvider {
    static var previews: some View {
        QrCodeToolView(model: .init())
    }
}
