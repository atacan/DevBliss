import Dependencies
import Foundation
import JSBeautify

public struct JsBeautifyClient {
    public var format: @Sendable (String, JsBeautifyMode) async throws -> String
}

public enum JsBeautifyMode: String, CaseIterable, Identifiable, Codable {
    case beautify = "Beautify"
    case minify = "Minify"

    public var id: Self { self }
}

extension JsBeautifyClient: DependencyKey {
    public static let liveValue: Self = {
        let actor = JSBeautifyActor()
        return Self(
            format: { input, mode in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { throw JsBeautifyError.emptyInput }
                guard let actor else { throw JsBeautifyError.unavailable }

                let options = jsOptions(for: mode)
                guard let result = await actor.beautifyJavaScript(trimmed, options: options) else {
                    throw JsBeautifyError.failed
                }
                return result
            }
        )
    }()
}

extension DependencyValues {
    public var jsBeautify: JsBeautifyClient {
        get { self[JsBeautifyClient.self] }
        set { self[JsBeautifyClient.self] = newValue }
    }
}

public enum JsBeautifyError: LocalizedError {
    case emptyInput
    case unavailable
    case failed

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste JavaScript to format"
        case .unavailable:
            return "JavaScript formatter is unavailable"
        case .failed:
            return "Unable to format JavaScript"
        }
    }
}

private func jsOptions(for mode: JsBeautifyMode) -> JSBeautifyFormattingOptions {
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
