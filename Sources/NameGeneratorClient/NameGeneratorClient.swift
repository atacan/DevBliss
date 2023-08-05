import Dependencies
import Foundation

public struct NameGeneratorClient {
    public var generateUsingPrefixSuffix: @Sendable ([String], [String]) async -> String
    public var generateAlternatingVowelsConsonants: @Sendable (String, String, Int, Int) async -> String
    public var generateProbabilistic: @Sendable (NameGenerator) async -> String

    public func generateUsing(namePrefixes: [String], nameSuffixes: [String]) async -> String {
        await generateUsingPrefixSuffix(namePrefixes, nameSuffixes)
    }

    public func generateAlternating(
        vowels: String,
        consonants: String,
        minLength: Int,
        maxLength: Int
    ) async -> String {
        await generateAlternatingVowelsConsonants(vowels, consonants, minLength, maxLength)
    }

    public func generate(probabilisticWith nameGenerator: NameGenerator) async -> String {
        await generateProbabilistic(nameGenerator)
    }

    public func generateUsing(namePrefixes: [String], nameSuffixes: [String], times: Int) async -> [String] {
        await withTaskGroup(of: String.self) { group in
            for _ in 0 ..< times {
                group.addTask {
                    await generateUsingPrefixSuffix(namePrefixes, nameSuffixes)
                }
            }
            return await group.reduce(into: []) { result, name in
                result.append(name)
            }
        }
    }

    public func generateAlternating(
        vowels: String,
        consonants: String,
        minLength: Int,
        maxLength: Int,
        times: Int
    ) async -> [String] {
        await withTaskGroup(of: String.self) { group in
            for _ in 0 ..< times {
                group.addTask {
                    await generateAlternatingVowelsConsonants(vowels, consonants, minLength, maxLength)
                }
            }
            return await group.reduce(into: []) { result, name in
                result.append(name)
            }
        }
    }

    public func generate(probabilisticWith nameGenerator: NameGenerator, times: Int) async -> [String] {
        await withTaskGroup(of: String.self) { group in
            for _ in 0 ..< times {
                group.addTask {
                    await generateProbabilistic(nameGenerator)
                }
            }
            return await group.reduce(into: []) { result, name in
                result.append(name)
            }
        }
    }
}

extension NameGeneratorClient: DependencyKey {
    public static let liveValue = Self(
        generateUsingPrefixSuffix: { namePrefixes, nameSuffixes in
            let prefix = namePrefixes.randomElement() ?? ""
            let suffix = nameSuffixes.randomElement() ?? ""
            return prefix + suffix
        },
        generateAlternatingVowelsConsonants: { vowels, consonants, minLength, maxLength in
            let nameLength = Int.random(in: minLength ... maxLength)  // Random length between minLength and maxLength

            var randomName = ""
            randomName.reserveCapacity(nameLength)

            for i in 0 ..< nameLength {
                let letterString = i % 2 == 0 ? consonants : vowels
                let index = Int.random(in: 0 ..< letterString.count)

                let letterIndex = letterString.index(letterString.startIndex, offsetBy: index)
                randomName.append(letterString[letterIndex])
            }

            return randomName.capitalized
        },
        generateProbabilistic: generateRandomName(using:)
    )
}

extension DependencyValues {
    public var nameGenerator: NameGeneratorClient {
        get { self[NameGeneratorClient.self] }
        set { self[NameGeneratorClient.self] = newValue }
    }
}

public struct LetterWeight: Equatable, Identifiable {
    public let id = UUID()
    public var letter: String
    public var frequency: Int

    public init(
        letter: String,
        frequency: Int
    ) {
        self.letter = letter
        self.frequency = frequency
    }
}

public struct NameGenerator {
    let vowels: [String]
    let consonants: [String]
    let minLength: Int
    let maxLength: Int
    let alternationProbability: Double

    public init(
        vowels: [LetterWeight],
        consonants: [LetterWeight],
        minLength: Int,
        maxLength: Int,
        alternationProbability: Double
    ) {
        self.vowels = vowels.flatMap { Array(repeating: $0.letter, count: $0.frequency) }
        self.consonants = consonants.flatMap { Array(repeating: $0.letter, count: $0.frequency) }
        self.minLength = minLength
        self.maxLength = maxLength
        self.alternationProbability = alternationProbability
    }
}

@Sendable
func generateRandomName(using nameGenerator: NameGenerator) -> String {
    let nameLength = Int.random(in: nameGenerator.minLength ... nameGenerator.maxLength)
    var randomName = ""
    var isNextLetterVowel = Bool.random()

    for _ in 0 ..< nameLength {
        let letterArray = isNextLetterVowel ? nameGenerator.vowels : nameGenerator.consonants
        let index = Int.random(in: 0 ..< letterArray.count)
        randomName += letterArray[index]

        // Decide whether to switch the type of letter for the next iteration
        let shouldSwitch = Double.random(in: 0 ... 1) < nameGenerator.alternationProbability
        if shouldSwitch {
            isNextLetterVowel.toggle()
        }
    }

    return randomName.capitalized
}

let vowels = [
    LetterWeight(letter: "a", frequency: 8),
    LetterWeight(letter: "e", frequency: 12),
    LetterWeight(letter: "i", frequency: 7),
    LetterWeight(letter: "o", frequency: 8),
    LetterWeight(letter: "u", frequency: 3),
]

let consonants = [
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
]

// let nameGenerator = NameGenerator(vowels: vowels, consonants: consonants, minLength: 5, maxLength: 8)
// let randomName = generateRandomName(using: nameGenerator)
