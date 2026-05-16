import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class HexToAsciiModel {
    @ObservationIgnored
    @Shared(.toolInput("hexToAscii"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("hexToAscii"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var allowSeparators: Bool = true

    @ObservationIgnored
    @Dependency(\.hexToAscii) private var hexToAscii

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var config: HexToAsciiConfig {
        HexToAsciiConfig(allowSeparators: allowSeparators)
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("hexToAscii"))
        let outputText = Shared(wrappedValue: "", .toolOutput("hexToAscii"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("hexToAscii"))
        let outputText = Shared(wrappedValue: output, .toolOutput("hexToAscii"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setAllowSeparators(_ enabled: Bool) {
        allowSeparators = enabled
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = self.config

        conversionTask = Task { [weak self, input = input, config = config, hexToAscii = hexToAscii] in
            guard let self else { return }
            do {
                let result = try await hexToAscii.convert(input, config)
                await MainActor.run {
                    isConversionRequestInFlight = false
                    outputText = result
                }
            }
            catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    outputText = error.localizedDescription
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

extension HexToAsciiModel: Equatable {
    public static func == (lhs: HexToAsciiModel, rhs: HexToAsciiModel) -> Bool {
        lhs === rhs
    }
}

public struct HexToAsciiModelView: View {
    @Bindable var model: HexToAsciiModel

    public init(model: HexToAsciiModel) {
        self.model = model
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
                Toggle("Allow separators", isOn: $model.allowSeparators)
                    .help("Allow spaces, commas, colons, and 0x prefixes")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            convertButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Toggle("Allow separators", isOn: $model.allowSeparators)
                        .help("Allow spaces, commas, colons, and 0x prefixes")
                        .gridCellColumns(3)
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
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HexToAscii.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HexToAscii.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ASCII")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: $model.inputText)
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

            TextEditor(text: $model.outputText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }
}

struct HexToAsciiView_Previews: PreviewProvider {
    static var previews: some View {
        HexToAsciiModelView(model: .init())
    }
}
