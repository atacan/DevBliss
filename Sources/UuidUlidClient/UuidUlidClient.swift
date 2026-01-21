import Dependencies
import Foundation
import ULID

public struct UuidUlidClient {
    public var generate: @Sendable (UuidUlidType, Int, Bool) async throws -> String
    public var decode: @Sendable (String) async throws -> UuidUlidDecodeResult
}

public enum UuidUlidType: String, CaseIterable, Identifiable, Codable {
    case uuid = "UUID"
    case ulid = "ULID"

    public var id: Self { self }
}

public struct UuidUlidDecodeResult: Equatable, Codable {
    public var type: UuidUlidType
    public var standard: String
    public var raw: String
    public var version: String
    public var variant: String
    public var timestamp: String
    public var random: String
    public var summary: String
}

extension UuidUlidClient: DependencyKey {
    public static let liveValue = Self(
        generate: { type, count, lowercase in
            guard count > 0 else { throw UuidUlidError.invalidCount }
            let values: [String] = (0..<count).map { _ in
                switch type {
                case .uuid:
                    return UUID().uuidString
                case .ulid:
                    return ULID().ulidString
                }
            }
            let output = values.map { lowercase ? $0.lowercased() : $0 }.joined(separator: "\n")
            return output
        },
        decode: { input in
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw UuidUlidError.emptyInput }

            if let uuid = UUID(uuidString: trimmed) {
                return decodeUUID(uuid)
            }

            if let ulid = ULID(ulidString: trimmed) {
                return decodeULID(ulid)
            }

            throw UuidUlidError.invalidIdentifier
        }
    )
}

extension DependencyValues {
    public var uuidUlid: UuidUlidClient {
        get { self[UuidUlidClient.self] }
        set { self[UuidUlidClient.self] = newValue }
    }
}

public enum UuidUlidError: LocalizedError {
    case invalidCount
    case emptyInput
    case invalidIdentifier

    public var errorDescription: String? {
        switch self {
        case .invalidCount:
            return "Count must be greater than zero"
        case .emptyInput:
            return "Enter a UUID or ULID to decode"
        case .invalidIdentifier:
            return "Input is not a valid UUID or ULID"
        }
    }
}

private func decodeUUID(_ uuid: UUID) -> UuidUlidDecodeResult {
    let bytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
    let version = String((bytes[6] & 0xF0) >> 4)
    let variant = uuidVariant(from: bytes[8])
    let raw = hexString(bytes)

    let summary = [
        "Type: UUID",
        "Standard: \(uuid.uuidString)",
        "Version: \(version)",
        "Variant: \(variant)",
        "Raw: \(raw)",
    ]
    .joined(separator: "\n")

    return UuidUlidDecodeResult(
        type: .uuid,
        standard: uuid.uuidString,
        raw: raw,
        version: version,
        variant: variant,
        timestamp: "-",
        random: "-",
        summary: summary
    )
}

private func decodeULID(_ ulid: ULID) -> UuidUlidDecodeResult {
    let data = [UInt8](ulid.ulidData)
    let timestampData = Array(data.prefix(6))
    let randomData = Array(data.dropFirst(6))

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let timestamp = formatter.string(from: ulid.timestamp)

    let summary = [
        "Type: ULID",
        "Standard: \(ulid.ulidString)",
        "Timestamp: \(timestamp)",
        "Random: \(hexString(randomData))",
        "Raw: \(hexString(data))",
    ]
    .joined(separator: "\n")

    return UuidUlidDecodeResult(
        type: .ulid,
        standard: ulid.ulidString,
        raw: hexString(data),
        version: "-",
        variant: "-",
        timestamp: timestamp,
        random: hexString(randomData),
        summary: summary
    )
}

private func uuidVariant(from byte: UInt8) -> String {
    switch byte & 0xE0 {
    case 0x00, 0x20, 0x40, 0x60:
        return "NCS"
    case 0x80, 0xA0:
        return "RFC 4122"
    case 0xC0:
        return "Microsoft"
    default:
        return "Future"
    }
}

private func hexString(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
}
