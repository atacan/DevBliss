import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class BackslashEscapeModel {
    @ObservationIgnored
    @Shared(.toolInput("backslashEscape"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("backslashEscape"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: BackslashEscapeMode = .escape

    @ObservationIgnored
    @Dependency(\.backslashEscape) private var backslashEscape

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("backslashEscape"))
        let outputText = Shared(wrappedValue: "", .toolOutput("backslashEscape"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("backslashEscape"))
        let outputText = Shared(wrappedValue: output, .toolOutput("backslashEscape"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setMode(_ mode: BackslashEscapeMode) {
        self.mode = mode
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let mode = self.mode

        conversionTask = Task { [weak self, input = input, mode = mode, backslashEscape = backslashEscape] in
            guard let self else { return }
            do {
                let result = try await backslashEscape.convert(input, mode)
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

extension BackslashEscapeModel: Equatable {
    public static func == (lhs: BackslashEscapeModel, rhs: BackslashEscapeModel) -> Bool {
        lhs === rhs
    }
}

public struct BackslashEscapeModelView: View {
    @Bindable var model: BackslashEscapeModel

    public init(model: BackslashEscapeModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Mode", selection: $model.mode) {
                    ForEach(BackslashEscapeMode.allCases) { mode in
                        Text(mode.rawValue)
                            .tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 200)
                .help("Escape adds backslashes, Unescape removes them")
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
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.BackslashEscape.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.BackslashEscape.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input")
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
            Text("Output")
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

struct BackslashEscapeView_Previews: PreviewProvider {
    static var previews: some View {
        BackslashEscapeModelView(model: .init())
    }
}
