import Dependencies
import Foundation

public struct XmlFormatClient {
    public var format: @Sendable (String, XmlFormatMode) async throws -> String
}

public enum XmlFormatMode: String, CaseIterable, Identifiable, Codable {
    case beautify = "Beautify"
    case minify = "Minify"

    public var id: Self { self }
}

extension XmlFormatClient: DependencyKey {
    public static let liveValue = Self(
        format: { input, mode in
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw XmlFormatError.emptyInput }

            guard let data = trimmed.data(using: .utf8) else { throw XmlFormatError.invalidEncoding }
            let document = try XMLDocument(data: data, options: .nodePreserveAll)

            switch mode {
            case .beautify:
                return document.xmlString(options: [.nodePrettyPrint])
            case .minify:
                return document.xmlString(options: [.nodeCompactEmptyElement])
            }
        }
    )
}

extension DependencyValues {
    public var xmlFormat: XmlFormatClient {
        get { self[XmlFormatClient.self] }
        set { self[XmlFormatClient.self] = newValue }
    }
}

public enum XmlFormatError: LocalizedError {
    case emptyInput
    case invalidEncoding

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste XML content to format"
        case .invalidEncoding:
            return "XML input is not valid UTF-8"
        }
    }
}
