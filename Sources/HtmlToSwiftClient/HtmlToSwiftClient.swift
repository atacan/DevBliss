import Dependencies
import Foundation
import HtmlSwift
import SwiftHighlight
import XCTestDynamicOverlay

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

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

                // Apply default foreground color for text without highlighting (for dark mode visibility)
                let mutableResult = NSMutableAttributedString(attributedString: result.value)
                applyDefaultForegroundColor(to: mutableResult)
                return mutableResult
            }
        )
    }
}

/// Applies a default foreground color to text that doesn't have one set.
/// Uses system label color which adapts to light/dark mode automatically.
private func applyDefaultForegroundColor(to attributedString: NSMutableAttributedString) {
    let fullRange = NSRange(location: 0, length: attributedString.length)

    // Use system label color which is black in light mode, white in dark mode
    #if canImport(AppKit)
    let defaultColor = NSColor.labelColor
    #elseif canImport(UIKit)
    let defaultColor = UIColor.label
    #endif

    // Enumerate through the string and add foreground color where missing
    attributedString.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, range, _ in
        if value == nil {
            attributedString.addAttribute(.foregroundColor, value: defaultColor, range: range)
        }
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
