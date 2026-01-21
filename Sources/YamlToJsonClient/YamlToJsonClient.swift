import Dependencies
import Foundation
import Yams

public struct YamlToJsonClient {
    public var convert: @Sendable (String, YamlToJsonConfig) async throws -> String
}

public struct YamlToJsonConfig: Equatable, Codable {
    public var prettyPrinted: Bool

    public init(prettyPrinted: Bool = true) {
        self.prettyPrinted = prettyPrinted
    }
}

extension YamlToJsonClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            let object = try load(yaml: input)
            let options: JSONSerialization.WritingOptions = config.prettyPrinted ? [.prettyPrinted, .sortedKeys] : []
            let data = try JSONSerialization.data(withJSONObject: object ?? [:], options: options)
            return String(decoding: data, as: UTF8.self)
        }
    )
}

extension DependencyValues {
    public var yamlToJson: YamlToJsonClient {
        get { self[YamlToJsonClient.self] }
        set { self[YamlToJsonClient.self] = newValue }
    }
}
