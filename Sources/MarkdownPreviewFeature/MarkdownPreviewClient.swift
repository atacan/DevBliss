import Dependencies
import Foundation

public struct MarkdownPreviewClient {
    public var normalize: @Sendable (String) -> String
}

extension MarkdownPreviewClient: DependencyKey {
    public static let liveValue = Self(
        normalize: { input in
            input
        }
    )
}

extension DependencyValues {
    public var markdownPreview: MarkdownPreviewClient {
        get { self[MarkdownPreviewClient.self] }
        set { self[MarkdownPreviewClient.self] = newValue }
    }
}
