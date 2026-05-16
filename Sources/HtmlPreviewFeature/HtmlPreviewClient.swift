import Dependencies
import Foundation

public struct HtmlPreviewClient {
    public var normalize: @Sendable (String) -> String
}

extension HtmlPreviewClient: DependencyKey {
    public static let liveValue = Self(
        normalize: { input in
            input
        }
    )
}

extension DependencyValues {
    public var htmlPreview: HtmlPreviewClient {
        get { self[HtmlPreviewClient.self] }
        set { self[HtmlPreviewClient.self] = newValue }
    }
}
