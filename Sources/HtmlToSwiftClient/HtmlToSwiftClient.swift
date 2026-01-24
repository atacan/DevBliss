import Dependencies
import Foundation
import HtmlSwift
import SwiftHighlight
import XCTestDynamicOverlay

public struct HtmlToSwiftClient {
    public var binaryBirds: @Sendable (String, HtmlOutputComponent) async throws -> String
    public var pointfreeco: @Sendable (String, HtmlOutputComponent) async throws -> String
    public var highlightSwift: @Sendable (String) async -> NSAttributedString

    public func convert(_ html: String, for dsl: SwiftDSL, output: HtmlOutputComponent) async throws -> String {
        switch dsl {
        case .binaryBirds:
            return try await binaryBirds(html, output)
        case .pointFree:
            return try await pointfreeco(html, output)
        }
    }
}

extension HtmlToSwiftClient: DependencyKey {
    public static var liveValue: Self {
        // Create a shared Highlight instance for reuse
        let highlighter = Highlight()

        return Self(
            binaryBirds: { html, component in
                try convertToBinaryBirds(html: html, component: component)
            },
            pointfreeco: { html, component in
                try convertToPointFree(html: html, component: component)
            },
            highlightSwift: { code in
                await highlighter.registerSwift()
                let renderer = NSAttributedStringRenderer(theme: .dark)
                let result = await highlighter.highlight(code, language: "swift", renderer: renderer)
                return result.value
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
        binaryBirds: unimplemented("\(Self.self).binaryBirds"),
        pointfreeco: unimplemented("\(Self.self).pointFree"),
        highlightSwift: unimplemented("\(Self.self).highlightSwift")
    )
}
