import Dependencies
import Foundation

public struct BackslashEscapeClient {
    public var convert: @Sendable (String, BackslashEscapeMode) async throws -> String
}

public enum BackslashEscapeMode: String, CaseIterable, Identifiable, Codable {
    case escape = "Escape"
    case unescape = "Unescape"

    public var id: Self { self }
}

extension BackslashEscapeClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, mode in
            switch mode {
            case .escape:
                return escapeString(input)
            case .unescape:
                return unescapeString(input)
            }
        }
    )
}

extension DependencyValues {
    public var backslashEscape: BackslashEscapeClient {
        get { self[BackslashEscapeClient.self] }
        set { self[BackslashEscapeClient.self] = newValue }
    }
}

private func escapeString(_ input: String) -> String {
    var result = ""

    for scalar in input.unicodeScalars {
        switch scalar {
        case "\\":
            result += "\\\\"
        case "\"":
            result += "\\\""
        case "\n":
            result += "\\n"
        case "\r":
            result += "\\r"
        case "\t":
            result += "\\t"
        case "\u{08}":
            result += "\\b"
        case "\u{0C}":
            result += "\\f"
        default:
            if scalar.value < 0x20 {
                result += "\\u" + hexString(scalar.value, digits: 4)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
    }

    return result
}

private func unescapeString(_ input: String) -> String {
    var result = ""
    let scalars = Array(input.unicodeScalars)
    var index = 0

    while index < scalars.count {
        guard scalars[index] == "\\" else {
            result.unicodeScalars.append(scalars[index])
            index += 1
            continue
        }

        guard index + 1 < scalars.count else {
            result += "\\"
            break
        }

        switch scalars[index + 1] {
        case "\\":
            result += "\\"
            index += 2
        case "\"":
            result += "\""
            index += 2
        case "/":
            result += "/"
            index += 2
        case "b":
            result += "\u{08}"
            index += 2
        case "f":
            result += "\u{0C}"
            index += 2
        case "n":
            result += "\n"
            index += 2
        case "r":
            result += "\r"
            index += 2
        case "t":
            result += "\t"
            index += 2
        case "0":
            result += "\0"
            index += 2
        case "u":
            index = parseUnicodeEscape(scalars, at: index, into: &result)
        case "x":
            index = parseHexByteEscape(scalars, at: index, into: &result)
        default:
            result += "\\"
            result.unicodeScalars.append(scalars[index + 1])
            index += 2
        }
    }

    return result
}

private func parseUnicodeEscape(_ scalars: [Unicode.Scalar], at start: Int, into result: inout String) -> Int {
    let hexStart = start + 2
    let afterFirst = hexStart + 4

    guard let first = hexValue(in: scalars, at: hexStart, length: 4) else {
        result += "\\u"
        return start + 2
    }

    if isHighSurrogate(first),
        scalars.count >= afterFirst + 6,
        scalars[afterFirst] == "\\",
        scalars[afterFirst + 1] == "u",
        let second = hexValue(in: scalars, at: afterFirst + 2, length: 4),
        isLowSurrogate(second)
    {
        let combined = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
        result.unicodeScalars.append(Unicode.Scalar(combined)!)
        return afterFirst + 6
    }

    if let scalar = Unicode.Scalar(first) {
        result.unicodeScalars.append(scalar)
        return afterFirst
    }

    for offset in start..<afterFirst {
        result.unicodeScalars.append(scalars[offset])
    }
    return afterFirst
}

private func parseHexByteEscape(_ scalars: [Unicode.Scalar], at start: Int, into result: inout String) -> Int {
    let hexStart = start + 2

    guard let value = hexValue(in: scalars, at: hexStart, length: 2), let scalar = Unicode.Scalar(value) else {
        result += "\\x"
        return start + 2
    }

    result.unicodeScalars.append(scalar)
    return hexStart + 2
}

private func hexValue(in scalars: [Unicode.Scalar], at start: Int, length: Int) -> UInt32? {
    guard start + length <= scalars.count else { return nil }

    var value: UInt32 = 0
    for offset in start..<(start + length) {
        guard let digit = hexDigit(of: scalars[offset]) else { return nil }
        value = value << 4 | digit
    }
    return value
}

private func hexDigit(of scalar: Unicode.Scalar) -> UInt32? {
    switch scalar {
    case "0"..."9":
        return scalar.value - 48
    case "a"..."f":
        return scalar.value - 87
    case "A"..."F":
        return scalar.value - 55
    default:
        return nil
    }
}

private func hexString(_ value: UInt32, digits: Int) -> String {
    let hex = String(value, radix: 16, uppercase: false)
    return String(repeating: "0", count: max(0, digits - hex.count)) + hex
}

private func isHighSurrogate(_ value: UInt32) -> Bool {
    (0xD800...0xDBFF).contains(value)
}

private func isLowSurrogate(_ value: UInt32) -> Bool {
    (0xDC00...0xDFFF).contains(value)
}
