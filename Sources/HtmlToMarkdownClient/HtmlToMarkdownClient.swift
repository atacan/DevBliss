import Dependencies
import Demark
import Foundation

@MainActor
public struct HtmlToMarkdownClient {
    public var convert: (String, HtmlToMarkdownConfig) async throws -> String
}

public struct HtmlToMarkdownConfig: Equatable, Sendable {
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

extension HtmlToMarkdownClient: DependencyKey {
    @MainActor
    public static let liveValue = Self(
        convert: { html, config in
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
