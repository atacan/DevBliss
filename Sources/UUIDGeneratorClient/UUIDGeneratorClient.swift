import Dependencies
import Foundation

public struct UUIDGeneratorClient {
    public var generate: @Sendable (Int) async throws -> [String]

    public func generating(_ count: Int, _ textCase: TextCase = .upper) async throws -> String {
        let uuids = try await generate(count).joined(separator: "\n")
        switch textCase {
        case .lower:
            return uuids.lowercased()
        case .upper:
            return uuids
        }
    }
}

extension UUIDGeneratorClient: DependencyKey {
    public static let liveValue = Self(
        generate: { count in
            (1 ... count).map { _ in UUID().uuidString }
        }
    )
}

extension DependencyValues {
    public var uuidGenerator: UUIDGeneratorClient {
        get { self[UUIDGeneratorClient.self] }
        set { self[UUIDGeneratorClient.self] = newValue }
    }
}

public enum TextCase: CaseIterable {
    case lower
    case upper
}
