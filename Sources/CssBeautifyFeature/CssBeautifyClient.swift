import Dependencies
import Foundation
import JSBeautify

public struct CssBeautifyClient {
    public var format: @Sendable (String, CssBeautifyMode) async throws -> String
}

public enum CssBeautifyMode: String, CaseIterable, Identifiable, Codable {
    case beautify = "Beautify"
    case minify = "Minify"

    public var id: Self { self }
}

extension CssBeautifyClient: DependencyKey {
    public static let liveValue: Self = {
        let actor = JSBeautifyActor()
        return Self(
            format: { input, mode in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { throw CssBeautifyError.emptyInput }
                guard let actor else { throw CssBeautifyError.unavailable }

                let options = cssOptions(for: mode)
                guard let result = await actor.beautifyCSS(trimmed, options: options) else {
                    throw CssBeautifyError.failed
                }
                return result
            }
        )
    }()
}

extension DependencyValues {
    public var cssBeautify: CssBeautifyClient {
        get { self[CssBeautifyClient.self] }
        set { self[CssBeautifyClient.self] = newValue }
    }
}

public enum CssBeautifyError: LocalizedError {
    case emptyInput
    case unavailable
    case failed

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste CSS to format"
        case .unavailable:
            return "CSS formatter is unavailable"
        case .failed:
            return "Unable to format CSS"
        }
    }
}

private func cssOptions(for mode: CssBeautifyMode) -> JSBeautifyFormattingOptions {
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
