import Dependencies
import Foundation

// MARK: - Types

public enum UrlEncodeMode: String, CaseIterable, Identifiable, Codable, Equatable {
    case rfc3986 = "RFC3986"
    case formData = "Form Data"

    public var id: Self { self }
}

public enum UrlEncodeDirection: String, CaseIterable, Identifiable, Codable, Equatable {
    case encode = "Encode"
    case decode = "Decode"

    public var id: Self { self }
}

// MARK: - Client

public struct UrlEncodeClient {
    public var encode: @Sendable (String, UrlEncodeMode) -> String
    public var decode: @Sendable (String, Bool) -> String  // Bool = decode plus as space
    public var looksEncoded: @Sendable (String) -> Bool

    public init(
        encode: @escaping @Sendable (String, UrlEncodeMode) -> String,
        decode: @escaping @Sendable (String, Bool) -> String,
        looksEncoded: @escaping @Sendable (String) -> Bool
    ) {
        self.encode = encode
        self.decode = decode
        self.looksEncoded = looksEncoded
    }
}

// MARK: - Dependency Key

extension UrlEncodeClient: DependencyKey {
    public static var liveValue: UrlEncodeClient {
        UrlEncodeClient(
            encode: { input, mode in
                switch mode {
                case .rfc3986:
                    var allowed = CharacterSet.urlQueryAllowed
                    allowed.remove(charactersIn: "!*'();:@&=+$,/?%#[]")
                    return input.addingPercentEncoding(withAllowedCharacters: allowed) ?? input

                case .formData:
                    var allowed = CharacterSet.alphanumerics
                    allowed.insert(charactersIn: "-._~")
                    let encoded = input.addingPercentEncoding(withAllowedCharacters: allowed) ?? input
                    return encoded.replacingOccurrences(of: "%20", with: "+")
                }
            },
            decode: { input, decodePlusAsSpace in
                var processed = input
                if decodePlusAsSpace {
                    processed = processed.replacingOccurrences(of: "+", with: " ")
                }
                return processed.removingPercentEncoding ?? input
            },
            looksEncoded: { input in
                let pattern = "%[0-9A-Fa-f]{2}"
                return input.range(of: pattern, options: .regularExpression) != nil
            }
        )
    }

    public static var previewValue: UrlEncodeClient {
        liveValue
    }

    public static var testValue: UrlEncodeClient {
        UrlEncodeClient(
            encode: { input, _ in "encoded_\(input)" },
            decode: { input, _ in "decoded_\(input)" },
            looksEncoded: { _ in false }
        )
    }
}

// MARK: - Dependency Values

public extension DependencyValues {
    var urlEncode: UrlEncodeClient {
        get { self[UrlEncodeClient.self] }
        set { self[UrlEncodeClient.self] = newValue }
    }
}
