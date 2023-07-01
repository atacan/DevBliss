import Dependencies
import Foundation
import SwiftFormat
import XCTestDynamicOverlay

public struct SwiftPrettyClient {
    public var convert: @Sendable (String, String) async throws -> String
}

extension SwiftPrettyClient: DependencyKey {
    public static let liveValue = Self(
        convert: { config, input in
            try await withCheckedThrowingContinuation { continuation in
                let data = Data(config.utf8)
                do {
                    let args = try parseConfigFile(data)
                    let formatOptions = try formatOptionsFor(args)!
                    let formatted = try format(input, options: formatOptions)
                    return continuation.resume(returning: formatted)
                }
                catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    )

    public static let testValue = Self(
        convert: unimplemented("\(Self.self).convert")
    )
}

extension DependencyValues {
    public var swiftPretty: SwiftPrettyClient {
        get { self[SwiftPrettyClient.self] }
        set { self[SwiftPrettyClient.self] = newValue }
    }
}
