import BlissTheme
import Dependencies
import SharedModels
import Sharing
import SwiftUI

@MainActor
@Observable
public final class RandomStringGeneratorModel {
    @ObservationIgnored
    @Shared(.toolInput("randomStringGenerator"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("randomStringGenerator"))
    public var outputText = ""

    @ObservationIgnored
    private var generationTask: Task<Void, Never>?

    public var length: Int = 16
    public var includeLowercase: Bool = true
    public var includeUppercase: Bool = true
    public var includeDigits: Bool = true
    public var includeSymbols: Bool = false
    public var isConversionRequestInFlight = false
    public var errorMessage: String?

    public var config: RandomStringConfig {
        RandomStringConfig(
            includeLowercase: includeLowercase,
            includeUppercase: includeUppercase,
            includeDigits: includeDigits,
            includeSymbols: includeSymbols
        )
    }

    @ObservationIgnored
    @Dependency(\.randomStringGenerator) private var randomStringGenerator

    public init() {
        let outputText = Shared(wrappedValue: "", .toolOutput("randomStringGenerator"))
        self._outputText = outputText
    }

    public init(output: String) {
        let outputText = Shared(wrappedValue: output, .toolOutput("randomStringGenerator"))
        self._outputText = outputText
    }

    public func generateButtonTouched() {
        generationTask?.cancel()
        isConversionRequestInFlight = true
        errorMessage = nil
        let length = length
        let config = config

        generationTask = Task { [weak self, length = length, config = config, randomStringGenerator = randomStringGenerator] in
            guard let self else { return }
                do {
                    let result = try await randomStringGenerator.generate(length, config)
                    await MainActor.run {
                        isConversionRequestInFlight = false
                        $outputText.withLock { $0 = result }
                    }
                }
                catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    errorMessage = error.localizedDescription
                    $outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func cancel() {
        generationTask?.cancel()
        generationTask = nil
        isConversionRequestInFlight = false
    }
}

public struct RandomStringGeneratorModelView: View {
    @Bindable var model: RandomStringGeneratorModel

    public init(model: RandomStringGeneratorModel) {
        self.model = model
    }

    private var lengthStepper: some View {
        Stepper(value: $model.length, in: 1...256) {
            Text("\(model.length)")
                .frame(width: 50, alignment: .leading)
        }
    }

    private var lowercaseToggle: some View {
        Toggle("Lowercase", isOn: $model.includeLowercase)
    }

    private var uppercaseToggle: some View {
        Toggle("Uppercase", isOn: $model.includeUppercase)
    }

    private var digitsToggle: some View {
        Toggle("Digits", isOn: $model.includeDigits)
    }

    private var symbolsToggle: some View {
        Toggle("Symbols", isOn: $model.includeSymbols)
    }

    private var generateButton: some View {
        LoadingButton("Generate", isLoading: model.isConversionRequestInFlight) {
            model.generateButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Generate (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                HStack {
                    Text("Length")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    lengthStepper
                }
                lowercaseToggle
                uppercaseToggle
                digitsToggle
                symbolsToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            generateButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Length")
                    lengthStepper
                }

                GridRow {
                    ConfigLabel("Include")
                    HStack(spacing: 16) {
                        lowercaseToggle
                        uppercaseToggle
                        digitsToggle
                        symbolsToggle
                    }
                    .toggleStyle(.checkbox)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            generateButton
                .padding(.vertical, 8)
            #endif

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Random Strings")
                    .font(.headline)
                    .padding(.horizontal, 8)

                TextEditor(text: Binding(
                    get: { model.outputText },
                    set: { newValue in model.$outputText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
        }
    }
}

struct RandomStringGeneratorModel_Previews: PreviewProvider {
    static var previews: some View {
        RandomStringGeneratorModelView(model: .init())
    }
}
