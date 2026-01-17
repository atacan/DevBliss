import Dependencies
import Demark
import Foundation

public struct HtmlToMarkdownClient: Sendable {
    public var convert: @MainActor @Sendable (String, HtmlToMarkdownConfig) async throws -> String
}

public struct HtmlToMarkdownConfig: Equatable, Sendable, Codable {
    public var engine: ConversionEngine
    public var headingStyle: DemarkHeadingStyle
    public var bulletListMarker: String
    public var codeBlockStyle: DemarkCodeBlockStyle

    public init(
        engine: ConversionEngine = .turndown,
        headingStyle: DemarkHeadingStyle = .atx,
        bulletListMarker: String = "-",
        codeBlockStyle: DemarkCodeBlockStyle = .fenced
    ) {
        self.engine = engine
        self.headingStyle = headingStyle
        self.bulletListMarker = bulletListMarker
        self.codeBlockStyle = codeBlockStyle
    }
}

// Make Demark types Codable for persistence
extension ConversionEngine: @retroactive Codable {}
extension DemarkHeadingStyle: @retroactive Codable {}
extension DemarkCodeBlockStyle: @retroactive Codable {}

extension HtmlToMarkdownClient: DependencyKey {
    public static let liveValue = Self(
        convert: { @MainActor html, config in
            let demark = Demark()
            let options = DemarkOptions(
                engine: config.engine,
                headingStyle: config.headingStyle,
                bulletListMarker: config.bulletListMarker,
                codeBlockStyle: config.codeBlockStyle
            )
            return try await demark.convertToMarkdown(html, options: options)
        }
    )
}

extension DependencyValues {
    public var htmlToMarkdown: HtmlToMarkdownClient {
        get { self[HtmlToMarkdownClient.self] }
        set { self[HtmlToMarkdownClient.self] = newValue }
    }
}
