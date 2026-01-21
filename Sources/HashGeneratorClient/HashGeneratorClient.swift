import CryptoKit
import Dependencies
import Foundation

public struct HashGeneratorClient {
    public var hashes: @Sendable (String, HashGeneratorConfig) async throws -> HashGeneratorResult
}

public struct HashGeneratorConfig: Equatable, Codable {
    public var uppercase: Bool

    public init(uppercase: Bool = false) {
        self.uppercase = uppercase
    }
}

public struct HashGeneratorResult: Equatable, Codable {
    public var md5: String
    public var sha1: String
    public var sha256: String
    public var sha384: String
    public var sha512: String
}

extension HashGeneratorClient: DependencyKey {
    public static let liveValue = Self(
        hashes: { input, config in
            let data = Data(input.utf8)
            return HashGeneratorResult(
                md5: hexString(Insecure.MD5.hash(data: data), uppercase: config.uppercase),
                sha1: hexString(Insecure.SHA1.hash(data: data), uppercase: config.uppercase),
                sha256: hexString(SHA256.hash(data: data), uppercase: config.uppercase),
                sha384: hexString(SHA384.hash(data: data), uppercase: config.uppercase),
                sha512: hexString(SHA512.hash(data: data), uppercase: config.uppercase)
            )
        }
    )
}

extension DependencyValues {
    public var hashGenerator: HashGeneratorClient {
        get { self[HashGeneratorClient.self] }
        set { self[HashGeneratorClient.self] = newValue }
    }
}

private func hexString<D: Digest>(_ digest: D, uppercase: Bool) -> String {
    digest.map { byte in
        uppercase ? String(format: "%02X", byte) : String(format: "%02x", byte)
    }
    .joined()
}
