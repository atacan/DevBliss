import Dependencies
import Foundation

public struct HexToAsciiClient {
    public var convert: @Sendable (String, HexToAsciiConfig) async throws -> String
}

public struct HexToAsciiConfig: Equatable, Codable {
    public var allowSeparators: Bool

    public init(allowSeparators: Bool = true) {
        self.allowSeparators = allowSeparators
    }
}

extension HexToAsciiClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            let hexDigits = try normalizeHexDigits(input, allowSeparators: config.allowSeparators)
            guard hexDigits.count % 2 == 0 else {
                throw HexToAsciiError.oddLength
            }

            var bytes = [UInt8]()
            bytes.reserveCapacity(hexDigits.count / 2)

            var index = hexDigits.startIndex
            while index < hexDigits.endIndex {
                let nextIndex = hexDigits.index(index, offsetBy: 2)
                let pair = String(hexDigits[index..<nextIndex])
                guard let byte = UInt8(pair, radix: 16) else {
                    throw HexToAsciiError.invalidHexPair
                }
                bytes.append(byte)
                index = nextIndex
            }

            guard let output = String(bytes: bytes, encoding: .ascii) else {
                throw HexToAsciiError.nonAsciiOutput
            }

            return output
        }
    )
}

extension DependencyValues {
    public var hexToAscii: HexToAsciiClient {
        get { self[HexToAsciiClient.self] }
        set { self[HexToAsciiClient.self] = newValue }
    }
}

public enum HexToAsciiError: LocalizedError {
    case oddLength
    case invalidCharacter
    case invalidHexPair
    case nonAsciiOutput

    public var errorDescription: String? {
        switch self {
        case .oddLength:
            return "Hex input has an odd number of digits"
        case .invalidCharacter:
            return "Hex input contains invalid characters"
        case .invalidHexPair:
            return "Hex input contains an invalid byte"
        case .nonAsciiOutput:
            return "Decoded bytes are not valid ASCII"
        }
    }
}

private func normalizeHexDigits(_ input: String, allowSeparators: Bool) throws -> String {
    var digits = ""
    digits.reserveCapacity(input.count)

    var iterator = input.makeIterator()
    while let char = iterator.next() {
        if char == "0" {
            if let next = iterator.next() {
                if next == "x" || next == "X" {
                    continue
                }
                digits.append(char)
                if isHexDigit(next) {
                    digits.append(next)
                } else if allowSeparators, isSeparator(next) {
                    continue
                } else if next.isWhitespace {
                    continue
                } else {
                    throw HexToAsciiError.invalidCharacter
                }
            } else {
                digits.append(char)
            }
            continue
        }

        if isHexDigit(char) {
            digits.append(char)
            continue
        }

        if char.isWhitespace {
            continue
        }

        if allowSeparators, isSeparator(char) {
            continue
        }

        throw HexToAsciiError.invalidCharacter
    }

    return digits
}

private func isHexDigit(_ char: Character) -> Bool {
    guard char.unicodeScalars.count == 1, let scalar = char.unicodeScalars.first else { return false }
    switch scalar.value {
    case 48...57, 65...70, 97...102:
        return true
    default:
        return false
    }
}

private func isSeparator(_ char: Character) -> Bool {
    switch char {
    case "-", ":", ",", ";":
        return true
    default:
        return false
    }
}
