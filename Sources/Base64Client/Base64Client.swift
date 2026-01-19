import Dependencies
import Foundation

public struct Base64Client {
    public var encode: @Sendable (String) async throws -> String
    public var decode: @Sendable (String, Base64Config) async throws -> String
    public var isValidBase64: @Sendable (String) -> Bool
}

public enum Base64Mode: String, CaseIterable, Identifiable, Codable {
    case encode = "Encode"
    case decode = "Decode"

    public var id: Self { self }
}

public struct Base64Config: Equatable, Codable {
    public var autoDetect: Bool
    public var autoRemoveDataURLPrefix: Bool
    public var autoRemoveNullBytes: Bool

    public init(
        autoDetect: Bool = true,
        autoRemoveDataURLPrefix: Bool = true,
        autoRemoveNullBytes: Bool = true
    ) {
        self.autoDetect = autoDetect
        self.autoRemoveDataURLPrefix = autoRemoveDataURLPrefix
        self.autoRemoveNullBytes = autoRemoveNullBytes
    }
}

extension Base64Client: DependencyKey {
    public static let liveValue = Self(
        encode: { input in
            guard let data = input.data(using: .utf8) else {
                throw Base64Error.encodingFailed
            }
            return data.base64EncodedString()
        },
        decode: { input, config in
            var processedInput = input

            // Auto-remove data URL prefix (e.g., "data:text/plain;base64,")
            if config.autoRemoveDataURLPrefix {
                processedInput = removeDataURLPrefix(from: processedInput)
            }

            guard let data = Data(base64Encoded: processedInput) else {
                throw Base64Error.invalidBase64
            }

            guard var decoded = String(data: data, encoding: .utf8) else {
                throw Base64Error.notValidUTF8
            }

            // Auto-remove null bytes at the end
            if config.autoRemoveNullBytes {
                decoded = removeTrailingNullBytes(from: decoded)
            }

            return decoded
        },
        isValidBase64: { input in
            let processedInput = removeDataURLPrefix(from: input)
            guard let data = Data(base64Encoded: processedInput) else {
                return false
            }
            // Check if it can be decoded to valid UTF-8
            return String(data: data, encoding: .utf8) != nil
        }
    )
}

extension DependencyValues {
    public var base64: Base64Client {
        get { self[Base64Client.self] }
        set { self[Base64Client.self] = newValue }
    }
}

public enum Base64Error: LocalizedError {
    case encodingFailed
    case invalidBase64
    case notValidUTF8

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode the input string"
        case .invalidBase64:
            return "The input is not valid Base64"
        case .notValidUTF8:
            return "The decoded data is not valid UTF-8 text"
        }
    }
}

// MARK: - Helper Functions

private func removeDataURLPrefix(from input: String) -> String {
    // Pattern: data:[<mediatype>][;base64],<data>
    let pattern = #"^data:[^;,]*;?base64,"#
    if let range = input.range(of: pattern, options: .regularExpression) {
        return String(input[range.upperBound...])
    }
    return input
}

private func removeTrailingNullBytes(from input: String) -> String {
    var result = input
    while result.hasSuffix("\0") {
        result.removeLast()
    }
    return result
}
