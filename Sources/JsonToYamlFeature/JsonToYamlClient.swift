import Dependencies
import Foundation
import Yams

public struct JsonToYamlClient {
    public var convert: @Sendable (String, JsonToYamlConfig) async throws -> String
}

public struct JsonToYamlConfig: Equatable, Codable {
    public var sortKeys: Bool

    public init(sortKeys: Bool = false) {
        self.sortKeys = sortKeys
    }
}

extension JsonToYamlClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            let data = input.data(using: .utf8) ?? Data()
            let object = try JSONSerialization.jsonObject(with: data)
            return try dump(object: object, indent: 2, allowUnicode: true, sortKeys: config.sortKeys)
        }
    )
}

extension DependencyValues {
    public var jsonToYaml: JsonToYamlClient {
        get { self[JsonToYamlClient.self] }
        set { self[JsonToYamlClient.self] = newValue }
    }
}
