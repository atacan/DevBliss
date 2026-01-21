import Dependencies
import Foundation

public struct AsciiToHexClient {
    public var convert: @Sendable (String, AsciiToHexConfig) async throws -> String
}

public enum HexSeparator: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case space = "Space"

    public var id: Self { self }

    var value: String {
        switch self {
        case .none: return ""
        case .space: return " "
        }
    }
}

public struct AsciiToHexConfig: Equatable, Codable {
    public var uppercase: Bool
    public var separator: HexSeparator

    public init(uppercase: Bool = true, separator: HexSeparator = .space) {
        self.uppercase = uppercase
        self.separator = separator
    }
}

extension AsciiToHexClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            guard input.unicodeScalars.allSatisfy({ $0.value <= 0x7F }) else {
                throw AsciiToHexError.nonAsciiInput
            }

            let hexStrings = input.utf8.map { byte -> String in
                if config.uppercase {
                    return String(format: "%02X", byte)
                }
                return String(format: "%02x", byte)
            }

            return hexStrings.joined(separator: config.separator.value)
        }
    )
}

extension DependencyValues {
    public var asciiToHex: AsciiToHexClient {
        get { self[AsciiToHexClient.self] }
        set { self[AsciiToHexClient.self] = newValue }
    }
}

public enum AsciiToHexError: LocalizedError {
    case nonAsciiInput

    public var errorDescription: String? {
        switch self {
        case .nonAsciiInput:
            return "Input contains non-ASCII characters"
        }
    }
}
