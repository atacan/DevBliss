import Dependencies
import Foundation

public struct RandomStringGeneratorClient {
    public var generate: @Sendable (Int, RandomStringConfig) async throws -> String
}

public struct RandomStringConfig: Equatable, Codable {
    public var includeLowercase: Bool
    public var includeUppercase: Bool
    public var includeDigits: Bool
    public var includeSymbols: Bool

    public init(
        includeLowercase: Bool = true,
        includeUppercase: Bool = true,
        includeDigits: Bool = true,
        includeSymbols: Bool = false
    ) {
        self.includeLowercase = includeLowercase
        self.includeUppercase = includeUppercase
        self.includeDigits = includeDigits
        self.includeSymbols = includeSymbols
    }
}

extension RandomStringGeneratorClient: DependencyKey {
    public static let liveValue = Self(
        generate: { length, config in
            guard length > 0 else {
                throw RandomStringGeneratorError.invalidLength
            }

            var alphabet = ""
            if config.includeLowercase { alphabet += "abcdefghijklmnopqrstuvwxyz" }
            if config.includeUppercase { alphabet += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
            if config.includeDigits { alphabet += "0123456789" }
            if config.includeSymbols { alphabet += "!@#$%^&*()-_=+[]{}|;:,.<>?" }

            guard !alphabet.isEmpty else {
                throw RandomStringGeneratorError.emptyAlphabet
            }

            var generator = SystemRandomNumberGenerator()
            var output = ""
            output.reserveCapacity(length)

            for _ in 0..<length {
                let index = Int.random(in: 0..<alphabet.count, using: &generator)
                let charIndex = alphabet.index(alphabet.startIndex, offsetBy: index)
                output.append(alphabet[charIndex])
            }

            return output
        }
    )
}

extension DependencyValues {
    public var randomStringGenerator: RandomStringGeneratorClient {
        get { self[RandomStringGeneratorClient.self] }
        set { self[RandomStringGeneratorClient.self] = newValue }
    }
}

public enum RandomStringGeneratorError: LocalizedError {
    case invalidLength
    case emptyAlphabet

    public var errorDescription: String? {
        switch self {
        case .invalidLength:
            return "Length must be greater than zero"
        case .emptyAlphabet:
            return "Select at least one character set"
        }
    }
}
