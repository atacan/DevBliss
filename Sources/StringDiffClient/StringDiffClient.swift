import Dependencies
import Foundation
import JSDiff

public struct StringDiffClient {
    public var diff: @Sendable (DiffType, String, String) async -> [Change]
}

extension StringDiffClient: DependencyKey {
    public static let liveValue = Self(
        diff: { type, old, new in
            guard let jsDiff = JSDiff() else { return [] }
            return await jsDiff.diff(type, old, new)
        }
    )
}

extension DependencyValues {
    public var stringDiff: StringDiffClient {
        get { self[StringDiffClient.self] }
        set { self[StringDiffClient.self] = newValue }
    }
}
