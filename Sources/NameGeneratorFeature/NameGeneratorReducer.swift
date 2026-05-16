import BlissTheme
import Dependencies
import Foundation
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

public enum GenerationType {
    case prefixSuffix
    case alternatingVowelsConsonants
    case probabilistic
}

@MainActor
@Observable
public final class NameGeneratorModel {
    public var generationType: GenerationType = .alternatingVowelsConsonants
    public var prefixSuffix: NameGeneratorPrefixSuffixModel
    public var alternatingVowelsConsonants: NameGeneratorAlternatingModel
    public var probabilistic: NameGeneratorProbabilisticModel

    @ObservationIgnored
    @Shared(.toolOutput("nameGenerator"))
    public var outputText = ""

    public var isConversionRequestInFlight = false

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let outputText = Shared(wrappedValue: "", .toolOutput("nameGenerator"))

        self._outputText = outputText
        self.prefixSuffix = NameGeneratorPrefixSuffixModel()
        self.alternatingVowelsConsonants = NameGeneratorAlternatingModel()
        self.probabilistic = NameGeneratorProbabilisticModel()
    }

    public init(output: String) {
        let outputText = Shared(wrappedValue: output, .toolOutput("nameGenerator"))

        self._outputText = outputText
        self.prefixSuffix = NameGeneratorPrefixSuffixModel()
        self.alternatingVowelsConsonants = NameGeneratorAlternatingModel()
        self.probabilistic = NameGeneratorProbabilisticModel()
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true

        let generationType = generationType
        let prefixSuffix = self.prefixSuffix
        let alternating = self.alternatingVowelsConsonants
        let probabilistic = self.probabilistic

        conversionTask = Task { [weak self] in
            guard let self else { return }

            let result = switch generationType {
            case .prefixSuffix:
                await prefixSuffix.generate()
            case .alternatingVowelsConsonants:
                await alternating.generate()
            case .probabilistic:
                await probabilistic.generate()
            }

            if Task.isCancelled { return }

            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.isConversionRequestInFlight = false
                self.$outputText.withLock { $0 = result }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

extension NameGeneratorModel: Equatable {
    public static func == (lhs: NameGeneratorModel, rhs: NameGeneratorModel) -> Bool {
        lhs === rhs
    }
}

public struct NameGeneratorModelView: View {
    @Bindable var model: NameGeneratorModel

    public init(model: NameGeneratorModel) {
        self.model = model
    }

    public var body: some View {
        VStack {
            Picker(
                "Generation Type",
                selection: $model.generationType
            ) {
                Text(NSLocalizedString("Prefix Suffix", bundle: Bundle.module, comment: ""))
                    .tag(GenerationType.prefixSuffix)
                Text(NSLocalizedString("Alternating Vowels Consonants", bundle: Bundle.module, comment: ""))
                    .tag(GenerationType.alternatingVowelsConsonants)
                Text(NSLocalizedString("Probabilistic", bundle: Bundle.module, comment: ""))
                    .tag(GenerationType.probabilistic)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()

            LoadingButton(
                NSLocalizedString("Generate", bundle: Bundle.module, comment: ""),
                isLoading: model.isConversionRequestInFlight
            ) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Generate names (Cmd+Return)", bundle: Bundle.module, comment: ""))

            VSplit {
                Group {
                    switch model.generationType {
                    case .prefixSuffix:
                        NameGeneratorPrefixSuffixView(model: model.prefixSuffix)
                    case .alternatingVowelsConsonants:
                        NameGeneratorAlternatingView(model: model.alternatingVowelsConsonants)
                    case .probabilistic:
                        NameGeneratorProbabilisticView(model: model.probabilistic)
                    }
                }
                .padding()
            } bottom: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output")
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
}

public typealias NameGeneratorView = NameGeneratorModelView

struct NameGeneratorModelView_Previews: PreviewProvider {
    static var previews: some View {
        NameGeneratorModelView(model: .init())
    }
}
