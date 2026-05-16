import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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

extension XmlFormatModel: Equatable {
    public static func == (lhs: XmlFormatModel, rhs: XmlFormatModel) -> Bool {
        lhs === rhs
    }
}

struct XmlFormatView_Previews: PreviewProvider {
    static var previews: some View {
        XmlFormatModelView(model: .init())
    }
}

public struct XmlFormatModelView: View {
    @Bindable var model: XmlFormatModel

    public init(model: XmlFormatModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Picker("Mode", selection: $model.mode) {
                        ForEach(XmlFormatMode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Format", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Format (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.XmlFormat.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.XmlFormat.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("XML")
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

struct XmlFormatModelView_Previews: PreviewProvider {
    static var previews: some View {
        XmlFormatModelView(model: .init())
    }
}
