import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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

    private let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.Base64.splitViewFraction)
    @StateObject private var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.Base64.splitViewLayout)
    @StateObject private var hide = SideHolder()

    public init(model: Base64Model) {
        self.model = model
    }

    private var modePicker: some View {
        Picker("Mode", selection: $model.mode) {
            ForEach(Base64Mode.allCases) { mode in
                Text(mode.rawValue)
                    .tag(mode)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    private var autoDetectToggle: some View {
        Toggle("Auto-detect", isOn: $model.autoDetect)
            .help("Automatically detect if input is Base64 and switch mode")
    }

    private var stripDataURLToggle: some View {
        Toggle("Strip data URL", isOn: $model.autoRemoveDataURLPrefix)
            .help("Remove data:...;base64, prefix when decoding")
    }

    private var stripNullBytesToggle: some View {
        Toggle("Strip null bytes", isOn: $model.autoRemoveNullBytes)
            .help("Remove null bytes at the end of decoded string")
    }

    private var convertButton: some View {
        LoadingButton(
            model.mode == .encode ? "Encode" : "Decode",
            isLoading: model.isConversionRequestInFlight
        ) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 8) {
                modePicker
                HStack(spacing: 12) {
                    autoDetectToggle
                    Spacer()
                }
                HStack(spacing: 12) {
                    stripDataURLToggle
                    Spacer()
                }
                HStack(spacing: 12) {
                    stripNullBytesToggle
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            convertButton
                .padding(.vertical, 8)
            #else
            VStack(spacing: 4) {
                modePicker
                    .frame(width: 160)

                HStack(spacing: 16) {
                    autoDetectToggle
                    stripDataURLToggle
                    stripNullBytesToggle
                }
                .toggleStyle(.checkbox)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            convertButton
                .padding(.vertical, 8)
            #endif

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input")
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
            Text("Output")
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
