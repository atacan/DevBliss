import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct FilesClient {
    public var read: @Sendable (URL) async throws -> String
}

extension FilesClient: DependencyKey {
    public static var liveValue = Self(
        read: { try String(contentsOf: $0) }
    )
}

extension DependencyValues {
    public var filesClient: FilesClient {
        get { self[FilesClient.self] }
        set { self[FilesClient.self] = newValue }
    }
}
