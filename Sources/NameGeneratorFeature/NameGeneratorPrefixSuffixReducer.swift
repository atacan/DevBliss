import BlissTheme
import Dependencies
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class NameGeneratorPrefixSuffixModel {
    public var prefixesInput: String
    public var suffixesInput: String
    public var inputSeparator: String
    public var numberOfNames: Int

    @ObservationIgnored
    @Dependency(\.nameGenerator) private var nameGenerator

    public init(
        prefixesInput: String = [
            "Jo", "Bel", "Har", "San", "Le", "Gra", "Mel", "Ed", "Ari", "Theo", "Lau", "Phil", "Mat", "Rach",
            "Mich", "Chris",
            "An", "Jes", "Zach", "Deb", "Rob", "Steph", "Bri", "Pat", "Sam", "Kat", "Vic", "Nico", "Alex", "El",
            "Gab",
        ]
        .joined(separator: ";"),
        suffixesInput: String = [
            "na",
            "la",
            "ron",
            "ton",
            "ine",
            "bell",
            "dor",
            "ber",
            "lie",
            "der",
            "ney",
            "dy",
            "son",
            "lan",
            "th",
            "ce",
            "cie",
            "cy",
            "sy",
            "ca",
            "ty",
            "ny",
            "ris",
            "is",
            "sey",
            "nie",
            "len",
            "ken",
            "ben",
            "den",
            "men",
            "jen",
        ]
        .joined(separator: ";"),
        inputSeparator: String = ";",
        numberOfNames: Int = 10
    ) {
        self.prefixesInput = prefixesInput
        self.suffixesInput = suffixesInput
        self.inputSeparator = inputSeparator
        self.numberOfNames = numberOfNames
    }

    public var prefixes: [String] {
        prefixesInput.components(separatedBy: inputSeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public var suffixes: [String] {
        suffixesInput.components(separatedBy: inputSeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public func generate() async -> String {
        let names = await nameGenerator.generateUsing(namePrefixes: prefixes, nameSuffixes: suffixes, times: numberOfNames)
        return names.joined(separator: "\n")
    }
}

public struct NameGeneratorPrefixSuffixView: View {
    @Bindable var model: NameGeneratorPrefixSuffixModel

    public init(model: NameGeneratorPrefixSuffixModel) {
        self.model = model
    }

    public var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Prefixes", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Prefixes", bundle: Bundle.module, comment: ""),
                        text: $model.prefixesInput
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.monospaced(.title3)())
                }
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Separator", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Separator", bundle: Bundle.module, comment: ""),
                        text: $model.inputSeparator
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.monospaced(.title3)())
                    .frame(maxWidth: 60)
                }
                .help(
                    NSLocalizedString(
                        "string to be used to split input into a list",
                        bundle: Bundle.module,
                        comment: ""
                    )
                )
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Suffixes", bundle: Bundle.module, comment: ""))
                    TextField(
                        NSLocalizedString("Suffixes", bundle: Bundle.module, comment: ""),
                        text: $model.suffixesInput
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
                    .help(
                        NSLocalizedString(
                            "string to be used to split input into a list",
                            bundle: Bundle.module,
                            comment: ""
                        )
                    )
                }
            }

            HStack(alignment: .bottom) {
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
                    NSLocalizedString(
                        "\(model.numberOfNames)",
                        bundle: Bundle.module,
                        comment: "value of a numeric input value for voice-over"
                    )
                )
            }  // <-HStack
        }
    }
}

// preview
#if DEBUG

struct NameGeneratorPrefixSuffixView_Previews: PreviewProvider {
    static var previews: some View {
        let namePrefixesMock = [
            "Jo", "Bel", "Har", "San", "Le", "Gra", "Mel", "Ed", "Ari", "Theo", "Lau", "Phil", "Mat", "Rach",
            "Mich", "Chris",
            "An", "Jes", "Zach", "Deb", "Rob", "Steph", "Bri", "Pat", "Sam", "Kat", "Vic", "Nico", "Alex", "El",
            "Gab",
        ]
        let nameSuffixesMock = [
            "na", "la", "ron", "ton", "ine", "bell", "dor", "ber", "lie", "der", "ney", "dy", "son", "lan", "th",
            "ce", "cie",
            "cy", "sy", "ca", "ty", "ny", "ris", "is", "sey", "nie", "len", "ken", "ben", "den", "men", "jen",
        ]
        return NameGeneratorPrefixSuffixView(
            model: NameGeneratorPrefixSuffixModel(
                prefixesInput: namePrefixesMock.joined(separator: ";"),
                suffixesInput: nameSuffixesMock.joined(separator: ";")
            )
        )
    }
}

#endif

