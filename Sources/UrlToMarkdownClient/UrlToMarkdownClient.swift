import Demark
import Dependencies
import Foundation
import HtmlToMarkdownClient

public struct UrlToMarkdownClient: Sendable {
    public var convert: @MainActor @Sendable (URL, HtmlToMarkdownConfig, UrlLoadingConfig) async throws -> String
}

public struct UrlLoadingConfig: Equatable, Sendable, Codable {
    public var timeout: TimeInterval
    public var waitForIdle: Bool
    public var idleDelay: TimeInterval
    public var contentSelector: String

    public init(
        timeout: TimeInterval = 30,
        waitForIdle: Bool = true,
        idleDelay: TimeInterval = 0.5,
        contentSelector: String = ""
    ) {
        self.timeout = timeout
        self.waitForIdle = waitForIdle
        self.idleDelay = idleDelay
        self.contentSelector = contentSelector
    }
}

extension UrlToMarkdownClient: @MainActor DependencyKey {
    @MainActor
    public static let liveValue = {
        let demark = Demark()
        return Self(
            convert: { @MainActor url, config, loadingConfig in
                let options = DemarkOptions(
                    engine: config.engine,
                    headingStyle: config.headingStyle,
                    bulletListMarker: config.bulletListMarker,
                    codeBlockStyle: config.codeBlockStyle
                )
                let loadingOptions = URLLoadingOptions(
                    timeout: loadingConfig.timeout,
                    waitForIdle: loadingConfig.waitForIdle,
                    idleDelay: loadingConfig.idleDelay,
                    contentSelector: loadingConfig.contentSelector.isEmpty ? nil : loadingConfig.contentSelector
                )
                return try await demark.convertToMarkdown(url: url, options: options, loadingOptions: loadingOptions)
            }
        )
    }()
}

extension DependencyValues {
    public var urlToMarkdown: UrlToMarkdownClient {
        get { self[UrlToMarkdownClient.self] }
        set { self[UrlToMarkdownClient.self] = newValue }
    }
}
