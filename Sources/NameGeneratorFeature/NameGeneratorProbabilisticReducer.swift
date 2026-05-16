import BlissTheme
import Dependencies
import Foundation
import Observation
import SharedModels
import SwiftUI

@MainActor
@Observable
public final class NameGeneratorProbabilisticModel {
    public var vowelsInput: [LetterWeight]
    public var consonantsInput: [LetterWeight]
    public var minLength: Int
    public var maxLength: Int
    public var alternationProbability: Double
    public var numberOfNames: Int

    @ObservationIgnored
    @Dependency(\.nameGenerator) private var nameGenerator

    public init(
        vowelsInput: [LetterWeight] = [
            LetterWeight(letter: "a", frequency: 8),
            LetterWeight(letter: "e", frequency: 12),
            LetterWeight(letter: "i", frequency: 7),
            LetterWeight(letter: "o", frequency: 8),
            LetterWeight(letter: "u", frequency: 3),
        ],
        consonantsInput: [LetterWeight] = [
            LetterWeight(letter: "b", frequency: 1),
            LetterWeight(letter: "c", frequency: 3),
            LetterWeight(letter: "d", frequency: 4),
            LetterWeight(letter: "f", frequency: 2),
            LetterWeight(letter: "g", frequency: 2),
            LetterWeight(letter: "h", frequency: 5),
            LetterWeight(letter: "j", frequency: 1),
            LetterWeight(letter: "k", frequency: 1),
            LetterWeight(letter: "l", frequency: 4),
            LetterWeight(letter: "m", frequency: 3),
            LetterWeight(letter: "n", frequency: 7),
            LetterWeight(letter: "p", frequency: 2),
            LetterWeight(letter: "q", frequency: 1),
            LetterWeight(letter: "r", frequency: 6),
            LetterWeight(letter: "s", frequency: 6),
            LetterWeight(letter: "t", frequency: 9),
            LetterWeight(letter: "v", frequency: 1),
            LetterWeight(letter: "w", frequency: 2),
            LetterWeight(letter: "x", frequency: 1),
            LetterWeight(letter: "y", frequency: 2),
            LetterWeight(letter: "z", frequency: 1),
        ],
        minLength: Int = 3,
        maxLength: Int = 10,
        alternationProbability: Double = 0.5,
        numberOfNames: Int = 10

    ) {
        self.vowelsInput = vowelsInput
        self.consonantsInput = consonantsInput
        self.minLength = minLength
        self.maxLength = maxLength
        self.alternationProbability = alternationProbability
        self.numberOfNames = numberOfNames
    }

    public func addVowelButtontouched() {
        vowelsInput.append(LetterWeight(letter: "?", frequency: 1))
    }

    public func addConsonantButtontouched() {
        consonantsInput.append(LetterWeight(letter: "?", frequency: 1))
    }

    public func deleteVowelButtontouched(id: LetterWeight.ID) {
        vowelsInput.removeAll(where: { $0.id == id })
    }

    public func deleteConsonantButtontouched(id: LetterWeight.ID) {
        consonantsInput.removeAll(where: { $0.id == id })
    }

    public func generate() async -> String {
        let names = await nameGenerator.generate(
            probabilisticWith: .init(
                vowels: vowelsInput,
                consonants: consonantsInput,
                minLength: minLength,
                maxLength: maxLength,
                alternationProbability: alternationProbability
            ),
            times: numberOfNames
        )
        return names.joined(separator: "\n")
    }
}

public struct NameGeneratorProbabilisticView: View {
    @Bindable var model: NameGeneratorProbabilisticModel

    public init(model: NameGeneratorProbabilisticModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack {
                LetterWeightsInputView(
                    vowelsInput: $model.vowelsInput,
                    title: NSLocalizedString("Vowels", bundle: Bundle.module, comment: ""),
                    plustButtonAction: {
                        model.addVowelButtontouched()
                    },
                    deleteButtonAction: { id in
                        model.deleteVowelButtontouched(id: id)
                    }
                )
                LetterWeightsInputView(
                    vowelsInput: $model.consonantsInput,
                    title: NSLocalizedString("Consonants", bundle: Bundle.module, comment: ""),
                    plustButtonAction: {
                        model.addConsonantButtontouched()
                    },
                    deleteButtonAction: { id in
                        model.deleteConsonantButtontouched(id: id)
                    }
                )
                HStack {
                    VStack {
                        Text(NSLocalizedString("Min. length", bundle: Bundle.module, comment: ""))
                        IntegerTextField(value: $model.minLength, range: 1 ... 15)
                            .frame(maxWidth: 150)
                    }
                    .accessibilityLabel(
                        NSLocalizedString(
                            "minimum length for the names",
                            bundle: Bundle.module,
                            comment: ""
                        )
                    )
                    .accessibilityValue(
                        NSLocalizedString(
                            "%d",
                            tableName: nil,
                            bundle: Bundle.module,
                            value: "\(model.minLength)",
                            comment: "value of a numeric input value for voice-over"
                        )
                    )

                    VStack {
                        Text(NSLocalizedString("Max. length", bundle: Bundle.module, comment: ""))
                        IntegerTextField(value: $model.maxLength, range: 1 ... 15)
                            .frame(maxWidth: 150)
                    }
                    .accessibilityLabel(
                        NSLocalizedString(
                            "Maximum length of the names",
                            bundle: Bundle.module,
                            comment: ""
                        )
                    )
                    .accessibilityValue(
                        NSLocalizedString(
                            "%d",
                            tableName: nil,
                            bundle: Bundle.module,
                            value: "\(model.maxLength)",
                            comment: "value of a numeric input value for voice-over"
                        )
                    )

                    VStack {
                        Text(NSLocalizedString("Alternation Probability", bundle: Bundle.module, comment: ""))
                            .minimumScaleFactor(0.5)
                            .help(
                                NSLocalizedString(
                                    "the probability of alternating between vowel and consonant when generating the next letter",
                                    bundle: Bundle.module,
                                    comment: ""
                                )
                            )
                        Slider(value: $model.alternationProbability, in: 0 ... 1)
                            .frame(maxWidth: 150)
                    }
                    .accessibilityLabel(
                        NSLocalizedString(
                            "Probability of switching vowel or consonant",
                            bundle: Bundle.module,
                            comment: ""
                        )
                    )
                    .accessibilityValue(
                        String(
                            format:
                                NSLocalizedString(
                                    "%d percent",
                                    bundle: Bundle.module,
                                    comment: "value of a numeric input value for voice-over"
                                ),
                            Int(model.alternationProbability * 100)
                        )
                    )

                    VStack {
                        Text(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                        IntegerTextField(value: $model.numberOfNames, range: 1 ... 200)
                            .frame(maxWidth: 150)
                    }
                    .accessibilityLabel(NSLocalizedString("names to be generated", bundle: Bundle.module, comment: ""))
                    .accessibilityValue(
                        NSLocalizedString(
                            String(
                                format: NSLocalizedString(
                                    "%d",
                                    bundle: Bundle.module,
                                    comment: ""
                                ),
                                model.numberOfNames
                            ),
                            bundle: Bundle.module,
                            comment: "value of a numeric input value for voice-over"
                        )
                    )
                }
            }
        }
    }
}

#if DEBUG

struct NameGeneratorProbabilisticView_Previews: PreviewProvider {
    static var previews: some View {
        NameGeneratorProbabilisticView(model: NameGeneratorProbabilisticModel())
    }
}

#endif

public struct LetterWeightsInputView: View {
    @Binding var vowelsInput: [LetterWeight]
    let title: String
    let plustButtonAction: () -> Void
    let deleteButtonAction: (LetterWeight.ID) -> Void

    public var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Letter", bundle: Bundle.module, comment: ""))
                        Text(NSLocalizedString("Weight", bundle: Bundle.module, comment: ""))
                            .offset(y: 1)
                        Text(NSLocalizedString(" ", bundle: Bundle.module, comment: ""))
                    }
                    ForEach($vowelsInput) { $letterWeight in

                        VStack(alignment: .center) {
                            TextField("", text: $letterWeight.letter)
                                .textFieldStyle(.roundedBorder)
                            IntegerTextField(value: $letterWeight.frequency, range: 0 ... 20)
                                .frame(maxWidth: 150)
                            Button {
                                deleteButtonAction(letterWeight.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.footnote)
                                    .accessibilityLabel(
                                        NSLocalizedString(
                                            "Delete from \(title)",
                                            bundle: Bundle.module,
                                            comment: ""
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .font(.monospaced(.title3)())

                    Button {
                        plustButtonAction()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(NSLocalizedString("Add to \(title)", bundle: Bundle.module, comment: ""))
                }
            }
        }
    }
}

