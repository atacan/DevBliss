import Dependencies
import HtmlSwift

public struct HtmlToSwiftClient {
    public var binaryBirds: @Sendable (String) async throws -> String
    public var pointfreeco: @Sendable (String) async throws -> String

    public func convert(_ html: String, for dsl: SwiftDSL, output: HtmlOutputComponent) async throws -> String {
        try htmlToSwift(html, for: dsl, component: output)
    }
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

extension DependencyValues {
    public var htmlToSwift: HtmlToSwiftClient.Value {
        get { self[HtmlToSwiftClient.self] }
        set { self[HtmlToSwiftClient.self] = newValue }
    }
}
