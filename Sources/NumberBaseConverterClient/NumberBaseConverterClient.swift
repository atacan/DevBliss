import Dependencies
import Foundation

public struct NumberBaseConverterClient {
    public var convert: @Sendable (String, NumberBase) async throws -> NumberBaseResult
}

public enum NumberBase: Int, CaseIterable, Identifiable, Codable {
    case binary = 2
    case octal = 8
    case decimal = 10
    case hex = 16

    public var id: Self { self }

    public var label: String {
        switch self {
        case .binary: return "Binary"
        case .octal: return "Octal"
        case .decimal: return "Decimal"
        case .hex: return "Hex"
        }
    }
}

public struct NumberBaseResult: Equatable, Codable {
    public var binary: String
    public var octal: String
    public var decimal: String
    public var hex: String
}

extension NumberBaseConverterClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, fromBase in
            let normalized = normalizeInput(input)
            guard !normalized.isEmpty else {
                throw NumberBaseConverterError.emptyInput
            }

            let value = try parseValue(normalized, base: fromBase)
            return NumberBaseResult(
                binary: String(value, radix: NumberBase.binary.rawValue),
                octal: String(value, radix: NumberBase.octal.rawValue),
                decimal: String(value, radix: NumberBase.decimal.rawValue),
                hex: String(value, radix: NumberBase.hex.rawValue)
            )
        }
    )
}

extension DependencyValues {
    public var numberBaseConverter: NumberBaseConverterClient {
        get { self[NumberBaseConverterClient.self] }
        set { self[NumberBaseConverterClient.self] = newValue }
    }
}

public enum NumberBaseConverterError: LocalizedError {
    case emptyInput
    case invalidNumber
    case outOfRange

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Enter a number to convert"
        case .invalidNumber:
            return "Invalid number for the selected base"
        case .outOfRange:
            return "Number is too large to convert"
        }
    }
}

private func normalizeInput(_ input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "_", with: "")
        .replacingOccurrences(of: " ", with: "")

    if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
        return String(trimmed.dropFirst(2))
    }
    if trimmed.hasPrefix("0b") || trimmed.hasPrefix("0B") {
        return String(trimmed.dropFirst(2))
    }
    if trimmed.hasPrefix("0o") || trimmed.hasPrefix("0O") {
        return String(trimmed.dropFirst(2))
    }
    return trimmed
}

private func parseValue(_ input: String, base: NumberBase) throws -> UInt64 {
    guard let value = UInt64(input, radix: base.rawValue) else {
        throw NumberBaseConverterError.invalidNumber
    }
    return value
}
