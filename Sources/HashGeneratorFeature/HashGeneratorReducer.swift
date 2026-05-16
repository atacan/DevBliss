import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class HashGeneratorModel {
    @ObservationIgnored
    @Shared(.toolInput("hashGenerator"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("hashGenerator"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var uppercase: Bool = false

    @ObservationIgnored
    @Dependency(\.hashGenerator) private var hashGenerator

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("hashGenerator"))
        let outputText = Shared(wrappedValue: "", .toolOutput("hashGenerator"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("hashGenerator"))
        let outputText = Shared(wrappedValue: output, .toolOutput("hashGenerator"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let uppercase = self.uppercase

        conversionTask = Task { [weak self, input = input, uppercase = uppercase, hashGenerator = hashGenerator] in
            guard let self else { return }
            do {
                let config = HashGeneratorConfig(uppercase: uppercase)
                let result = try await hashGenerator.hashes(input, config)
                let output = format(result: result)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = output }
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

    private func format(result: HashGeneratorResult) -> String {
        [
            "MD5: \(result.md5)",
            "SHA1: \(result.sha1)",
            "SHA256: \(result.sha256)",
            "SHA384: \(result.sha384)",
            "SHA512: \(result.sha512)",
        ]
        .joined(separator: "\n")
    }

    public func setUppercase(_ value: Bool) {
        uppercase = value
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

extension HashGeneratorModel: Equatable {
    public static func == (lhs: HashGeneratorModel, rhs: HashGeneratorModel) -> Bool {
        lhs === rhs
    }
}

struct HashGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        HashGeneratorModelView(model: .init())
    }
}

public struct HashGeneratorModelView: View {
    @Bindable var model: HashGeneratorModel

    public init(model: HashGeneratorModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Toggle("Uppercase", isOn: $model.uppercase)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Generate", isLoading: model.isConversionRequestInFlight) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Generate (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HashGenerator.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HashGenerator.splitViewLayout))
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
            Text("Hashes")
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
