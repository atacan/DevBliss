import Dependencies
import Foundation
import Highlight
import XCTestDynamicOverlay

public struct JsonPrettyClient {
    public var convert: @Sendable (String) async throws -> NSAttributedString
}

enum JsonPrettyClientError: Error {
    case jsonSerial
    case stringEncoding
}

extension JsonPrettyClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .jsonSerial:
            return "JSONSerialization"
        case .stringEncoding:
            return "this didn't work `jsonString = String(data: data, encoding: .utf8)` "
        }
    }
}

extension DependencyValues {
    public var jsonPretty: JsonPrettyClient {
        get { self[JsonPrettyClient.self] }
        set { self[JsonPrettyClient.self] = newValue }
    }
}

extension JsonPrettyClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input in
            try await withCheckedThrowingContinuation { continuation in
                do {
                    let json = try JSONSerialization.jsonObject(with: Data(input.utf8), options: [])
                    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

                    guard let jsonString = String(data: data, encoding: .utf8) else {
                        return continuation.resume(throwing: JsonPrettyClientError.stringEncoding)
                    }

                    let highlighted = JsonSyntaxHighlightProvider.shared.highlight(jsonString, as: .json)
                    return continuation.resume(returning: highlighted)
                } catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    )

    public static let testValue = Self(
        convert: unimplemented("\(Self.self).convert")
    )
}
