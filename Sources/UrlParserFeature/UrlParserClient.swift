import Dependencies
import Foundation

public struct UrlParserClient {
    public var parse: @Sendable (String) throws -> UrlParseResult
    public var shouldAutoParse: @Sendable (String) -> Bool
}

public struct UrlParseResult: Equatable, Codable {
    public var scheme: String
    public var host: String
    public var port: String
    public var path: String
    public var fileName: String
    public var fragment: String
    public var queryJSON: String
}

extension UrlParserClient: DependencyKey {
    public static let liveValue = Self(
        parse: { input in
            guard let components = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let host = components.host else {
                throw UrlParserError.invalidURL
            }

            let path = components.path
            let fileName = URL(string: input)?.lastPathComponent ?? ""
            let queryItems = components.queryItems ?? []
            let queryDict = Dictionary(grouping: queryItems, by: { $0.name })
                .mapValues { items in
                    items.compactMap { $0.value }
                }

            let jsonData = try JSONSerialization.data(withJSONObject: queryDict, options: [.prettyPrinted])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            return UrlParseResult(
                scheme: components.scheme ?? "",
                host: host,
                port: components.port.map(String.init) ?? "",
                path: path,
                fileName: fileName,
                fragment: components.fragment ?? "",
                queryJSON: jsonString
            )
        },
        shouldAutoParse: { input in
            guard let components = URLComponents(string: input) else { return false }
            let count = components.queryItems?.count ?? 0
            return count >= 2
        }
    )
}

extension DependencyValues {
    public var urlParser: UrlParserClient {
        get { self[UrlParserClient.self] }
        set { self[UrlParserClient.self] = newValue }
    }
}

public enum UrlParserError: LocalizedError {
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Enter a valid URL"
        }
    }
}
