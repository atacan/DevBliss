import Dependencies
import HtmlSwift
import XCTestDynamicOverlay

public struct HtmlToSwiftClient {
    public var binaryBirds: @Sendable (String, HtmlOutputComponent) async throws -> String
    public var pointfreeco: @Sendable (String, HtmlOutputComponent) async throws -> String

    public func convert(_ html: String, for dsl: SwiftDSL, output: HtmlOutputComponent) async throws -> String {
        switch dsl {
        case .binaryBirds:
            try await self.binaryBirds(html, output)
        case .pointFree:
            try await self.pointfreeco(html, output)
        }
    }
}

extension HtmlToSwiftClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            binaryBirds: { html, component in
                try convertToBinaryBirds(html: html, component: component)
            },
            pointfreeco: { html, component in
                try convertToPointFree(html: html, component: component)
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

extension HtmlToSwiftClient: TestDependencyKey {
    public static var testValue: HtmlToSwiftClient = Self(
        binaryBirds: XCTUnimplemented("\(Self.self).binaryBirds"),
        pointfreeco: XCTUnimplemented("\(Self.self).pointFree")
    )
}
