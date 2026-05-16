import Dependencies
import Foundation
import SwiftFormat

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
                    let formatOptions = try formatOptionsFor(args.first ?? [:])!
                    let result = try format(input, options: formatOptions)
                    return continuation.resume(returning: result.output)
                } catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    )
}

extension DependencyValues {
    public var swiftPretty: SwiftPrettyClient {
        get { self[SwiftPrettyClient.self] }
        set { self[SwiftPrettyClient.self] = newValue }
    }
}
