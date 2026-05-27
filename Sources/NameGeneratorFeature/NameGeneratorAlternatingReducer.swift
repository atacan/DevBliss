import BlissTheme
import Dependencies
import Foundation
import Observation
import SharedModels
import SwiftUI

@MainActor
@Observable
public final class NameGeneratorAlternatingModel {
    public var vowelsInput: String
    public var consonantsInput: String
    public var inputSeparator: String
    public var minLength: Int
    public var maxLength: Int
    public var numberOfNames: Int

    @ObservationIgnored
    @Dependency(\.nameGenerator) private var nameGenerator

    public init(
        vowelsInput: String = "aeiou",
        consonantsInput: String = "bcdfghjklmnpqrstvwxyz",
        inputSeparator: String = "",
        minLength: Int = 3,
        maxLength: Int = 10,
        numberOfNames: Int = 10
    ) {
        self.vowelsInput = vowelsInput
        self.consonantsInput = consonantsInput
        self.inputSeparator = inputSeparator
        self.minLength = minLength
        self.maxLength = maxLength
        self.numberOfNames = numberOfNames
    }

    public var vowels: [String] {
        vowelsInput.components(separatedBy: inputSeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public var consonants: [String] {
        consonantsInput.components(separatedBy: inputSeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public func generate() async -> String {
        let names = await nameGenerator.generateAlternating(
            vowels: vowelsInput,
            consonants: consonantsInput,
            minLength: minLength,
            maxLength: maxLength,
            times: numberOfNames
        )
        return names.joined(separator: "\n")
    }
}

public struct NameGeneratorAlternatingView: View {
    @Bindable var model: NameGeneratorAlternatingModel

    public init(model: NameGeneratorAlternatingModel) {
        self.model = model
    }

    public var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Vowels", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Prefixes", bundle: Bundle.module, comment: ""),
                        text: $model.vowelsInput
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Separator", bundle: Bundle.module, comment: ""),
                        text: $model.inputSeparator
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Consonants", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Suffixes", bundle: Bundle.module, comment: ""),
                        text: $model.consonantsInput
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: "")).foregroundColor(.clear)
                    TextField(
                        NSLocalizedString("Separator", bundle: Bundle.module, comment: ""),
                        text: $model.inputSeparator
                    )
                    .font(.monospaced(.title3)())
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
                }
            }

            HStack {
                VStack {
                    Text(NSLocalizedString("Min. length", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: $model.minLength, range: 1 ... 15)
                        .frame(maxWidth: 150)
                }
                .accessibilityLabel(
                    NSLocalizedString(
                        "Minimum length of the names",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                .accessibilityValue(
                    NSLocalizedString(
                        "\(model.minLength)",
                        bundle: Bundle.module,
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
                        "\(model.maxLength)",
                        bundle: Bundle.module,
                        comment: "value of a numeric input value for voice-over"
                    )
                )

                VStack {
                    Text(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: $model.numberOfNames, range: 1 ... 200)
                        .frame(maxWidth: 150)
                }
                .accessibilityLabel(
                    NSLocalizedString(
                        "Number of names",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
                .accessibilityValue(
                    String(
                        format: NSLocalizedString(
                            "%d",
                            bundle: Bundle.module,
                            comment: "value of a numeric input value for voice-over"
                        ),
                        model.numberOfNames
                    )
                )
            }
        }
    }
}

#if DEBUG
struct NameGeneratorAlternatingView_Previews: PreviewProvider {
    static var previews: some View {
        NameGeneratorAlternatingView(model: NameGeneratorAlternatingModel())
    }
}
#endif

// BUG: on macOS although the value stays 1+, the text field shows zero
public struct IntegerTextField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    public var body: some View {
        HStack {
            Stepper(
                value: Binding(
                    get: { value },
                    set: { value = $0.clamped(to: range) }
                )
            ) {
                TextField(
                    "",
                    text: Binding(
                        get: { "\(value)" },
                        set: {
                            if let newValue = Int($0) {
                                value = newValue.clamped(to: range)
                            }
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 250)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

