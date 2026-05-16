import Dependencies
import Foundation

public struct SvgToCssClient {
    public var convert: @Sendable (String, SvgToCssConfig) async throws -> String
}

public struct SvgToCssConfig: Equatable, Codable {
    public var includeDataPrefix: Bool
    public var wrapWithCss: Bool

    public init(includeDataPrefix: Bool = true, wrapWithCss: Bool = true) {
        self.includeDataPrefix = includeDataPrefix
        self.wrapWithCss = wrapWithCss
    }
}

extension SvgToCssClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw SvgToCssError.emptyInput
            }

            let cleaned = collapseWhitespace(in: trimmed)
            let encoded = percentEncodeSvg(cleaned)
            let dataUrl = config.includeDataPrefix
                ? "data:image/svg+xml;utf8,\(encoded)"
                : encoded

            if config.wrapWithCss {
                return "background-image: url(\"\(dataUrl)\");"
            }
            return dataUrl
        }
    )
}

extension DependencyValues {
    public var svgToCss: SvgToCssClient {
        get { self[SvgToCssClient.self] }
        set { self[SvgToCssClient.self] = newValue }
    }
}

public enum SvgToCssError: LocalizedError {
    case emptyInput

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste SVG markup to convert"
        }
    }
}

private func collapseWhitespace(in input: String) -> String {
    let parts = input.split { $0.isWhitespace || $0.isNewline }
    return parts.joined(separator: " ")
}

private func percentEncodeSvg(_ input: String) -> String {
    let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~!$&'()*+,;=:@/?")
    var output = ""
    output.reserveCapacity(input.count)

    for scalar in input.unicodeScalars {
        if allowed.contains(scalar) {
            output.unicodeScalars.append(scalar)
        } else {
            let bytes = String(scalar).utf8
            for byte in bytes {
                output += String(format: "%%%02X", byte)
            }
        }
    }

    return output
}
