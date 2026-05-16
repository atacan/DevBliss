import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class AsciiToHexModel {
    @ObservationIgnored
    @Shared(.toolInput("asciiToHex"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("asciiToHex"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var uppercase: Bool = true
    public var separator: HexSeparator = .space

    @ObservationIgnored
    @Dependency(\.asciiToHex) private var asciiToHex

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var config: AsciiToHexConfig {
        AsciiToHexConfig(uppercase: uppercase, separator: separator)
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("asciiToHex"))
        let outputText = Shared(wrappedValue: "", .toolOutput("asciiToHex"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("asciiToHex"))
        let outputText = Shared(wrappedValue: output, .toolOutput("asciiToHex"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setUppercase(_ enabled: Bool) {
        uppercase = enabled
    }

    public func setSeparator(_ separator: HexSeparator) {
        self.separator = separator
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = self.config

        conversionTask = Task { [weak self, input = input, config = config, asciiToHex = asciiToHex] in
            guard let self else { return }
            do {
                let result = try await asciiToHex.convert(input, config)
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

public struct AsciiToHexModelView: View {
    @Bindable var model: AsciiToHexModel

    public init(model: AsciiToHexModel) {
        self.model = model
    }

    private var separatorPicker: some View {
        Picker("Separator", selection: $model.separator) {
            ForEach(HexSeparator.allCases) { separator in
                Text(separator.rawValue)
                    .tag(separator)
            }
        }
    }

    private var uppercaseToggle: some View {
        Toggle("Uppercase", isOn: $model.uppercase)
    }

    private var convertButton: some View {
        LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                separatorPicker
                uppercaseToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            convertButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Separator")
                    separatorPicker
                        .blissMenuPicker(width: 120)
                    uppercaseToggle
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            convertButton
                .padding(.vertical, 8)
            #endif

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.AsciiToHex.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.AsciiToHex.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ASCII")
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
            Text("Hex")
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

// TODO: delete this file and move to AsciiToHexModelView once the app shell is fully migrated.
struct AsciiToHexView_Previews: PreviewProvider {
    static var previews: some View {
        AsciiToHexModelView(model: AsciiToHexModel())
    }
}
