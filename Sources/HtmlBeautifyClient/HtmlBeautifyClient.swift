import Dependencies
import Foundation
import JSBeautify

public struct HtmlBeautifyClient {
    public var format: @Sendable (String, HtmlBeautifyMode) async throws -> String
}

public enum HtmlBeautifyMode: String, CaseIterable, Identifiable, Codable {
    case beautify = "Beautify"
    case minify = "Minify"

    public var id: Self { self }
}

extension HtmlBeautifyClient: DependencyKey {
    public static let liveValue: Self = {
        let actor = JSBeautifyActor()
        return Self(
            format: { input, mode in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { throw HtmlBeautifyError.emptyInput }
                guard let actor else { throw HtmlBeautifyError.unavailable }

                let options = htmlOptions(for: mode)
                guard let result = await actor.beautifyHTML(trimmed, options: options) else {
                    throw HtmlBeautifyError.failed
                }
                return result
            }
        )
    }()
}

extension DependencyValues {
    public var htmlBeautify: HtmlBeautifyClient {
        get { self[HtmlBeautifyClient.self] }
        set { self[HtmlBeautifyClient.self] = newValue }
    }
}

public enum HtmlBeautifyError: LocalizedError {
    case emptyInput
    case unavailable
    case failed

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste HTML to format"
        case .unavailable:
            return "HTML formatter is unavailable"
        case .failed:
            return "Unable to format HTML"
        }
    }
}

private func htmlOptions(for mode: HtmlBeautifyMode) -> JSBeautifyFormattingOptions {
    switch mode {
    case .beautify:
        return JSBeautifyFormattingOptions()
    case .minify:
        var options = JSBeautifyFormattingOptions()
        options.indentation = .spaces(0)
        options.newlinesBetweenTokens = .removeAll
        options.lineWrap = .wrap(0)
        options.endWithNewline = false
        options.indentEmptyLines = false
        return options
    }
}
