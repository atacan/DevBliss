import Dependencies
import HtmlSwift

public struct HtmlToSwiftClient {
    public var binaryBirds: @Sendable (String) async throws -> String
    public var pointfreeco: @Sendable (String) async throws -> String
}

extension HtmlToSwiftClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            binaryBirds: { html in
                try convertToBinaryBirds(html: html)
            },
            pointfreeco: { html in
                try convertToPointFree(html: html)
            }
        )
    }
}

public extension DependencyValues {
    var htmlToSwift: HtmlToSwiftClient.Value {
        get { self[HtmlToSwiftClient.self] }
        set { self[HtmlToSwiftClient.self] = newValue }
    }
}
