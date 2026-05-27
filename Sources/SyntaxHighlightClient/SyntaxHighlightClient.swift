import Dependencies
import Foundation
import SwiftHighlight
import XCTestDynamicOverlay

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct SyntaxHighlightClient {
    public var highlightSwift: @Sendable (String) async -> NSAttributedString
    public var highlightMarkdown: @Sendable (String) async -> NSAttributedString
    public var highlightYaml: @Sendable (String) async -> NSAttributedString
}

extension SyntaxHighlightClient: DependencyKey {
    public static var liveValue: Self {
        let highlighter = Highlight()

        return Self(
            highlightSwift: { code in
                await highlighter.registerSwift()
                return await highlight(code, language: "swift", with: highlighter)
            },
            highlightMarkdown: { code in
                await highlighter.registerMarkdown()
                return await highlight(code, language: "markdown", with: highlighter)
            },
            highlightYaml: { code in
                await highlighter.registerYaml()
                return await highlight(code, language: "yaml", with: highlighter)
            }
        )
    }
}

private func highlight(_ code: String, language: String, with highlighter: Highlight) async -> NSAttributedString {
    let renderer = NSAttributedStringRenderer(theme: .dark)
    let result = await highlighter.highlight(code, language: language, renderer: renderer)
    let mutableResult = NSMutableAttributedString(attributedString: result.value)
    applyDefaultForegroundColor(to: mutableResult)
    return mutableResult
}

/// Applies a default foreground color to text that doesn't have one set.
/// Uses system label color which adapts to light/dark mode automatically.
private func applyDefaultForegroundColor(to attributedString: NSMutableAttributedString) {
    let fullRange = NSRange(location: 0, length: attributedString.length)

    #if canImport(AppKit)
    let defaultColor = NSColor.labelColor
    #elseif canImport(UIKit)
    let defaultColor = UIColor.label
    #endif

    attributedString.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, range, _ in
        if value == nil {
            attributedString.addAttribute(.foregroundColor, value: defaultColor, range: range)
        }
    }
}

extension DependencyValues {
    public var syntaxHighlight: SyntaxHighlightClient {
        get { self[SyntaxHighlightClient.self] }
        set { self[SyntaxHighlightClient.self] = newValue }
    }
}

extension SyntaxHighlightClient: TestDependencyKey {
    public static var testValue = Self(
        highlightSwift: { _ in NSAttributedString(string: "") },
        highlightMarkdown: { _ in NSAttributedString(string: "") },
        highlightYaml: { _ in NSAttributedString(string: "") }
    )
}
