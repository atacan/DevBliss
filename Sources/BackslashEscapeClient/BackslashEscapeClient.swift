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
    input
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
        .replacingOccurrences(of: "\0", with: "\\0")
}

private func unescapeString(_ input: String) -> String {
    var result = ""
    var iterator = input.makeIterator()

    while let char = iterator.next() {
        if char != "\\" {
            result.append(char)
            continue
        }

        guard let next = iterator.next() else {
            result.append("\\")
            break
        }

        switch next {
        case "\\":
            result.append("\\")
        case "\"":
            result.append("\"")
        case "n":
            result.append("\n")
        case "r":
            result.append("\r")
        case "t":
            result.append("\t")
        case "0":
            result.append("\0")
        case "u":
            if let unicode = parseUnicodeEscape(&iterator) {
                result.append(unicode)
            } else {
                result.append("\\u")
            }
        case "x":
            if let byte = parseHexByte(&iterator) {
                if let scalar = UnicodeScalar(Int(byte)) {
                    result.append(Character(scalar))
                }
            } else {
                result.append("\\x")
            }
        default:
            result.append(next)
        }
    }

    return result
}

private func parseUnicodeEscape(_ iterator: inout String.Iterator) -> Character? {
    var buffer = ""

    guard let first = iterator.next() else { return nil }

    if first == "{" {
        while let char = iterator.next() {
            if char == "}" { break }
            buffer.append(char)
        }
        guard let value = UInt32(buffer, radix: 16), let scalar = UnicodeScalar(value) else { return nil }
        return Character(scalar)
    }

    buffer.append(first)
    buffer.append(contentsOf: collect(iterator: &iterator, count: 3))
    guard buffer.count == 4, let value = UInt32(buffer, radix: 16), let scalar = UnicodeScalar(value) else { return nil }
    return Character(scalar)
}

private func parseHexByte(_ iterator: inout String.Iterator) -> UInt8? {
    let chars = collect(iterator: &iterator, count: 2)
    guard chars.count == 2 else { return nil }
    return UInt8(chars, radix: 16)
}

private func collect(iterator: inout String.Iterator, count: Int) -> String {
    var buffer = ""
    for _ in 0..<count {
        guard let char = iterator.next() else { break }
        buffer.append(char)
    }
    return buffer
}
