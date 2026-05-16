import Dependencies
import Foundation
import SwiftASN1
import X509

public struct CertificateDecoderClient {
    public var decode: @Sendable (String) throws -> CertificateDecodeResult
}

public struct CertificateDecodeResult: Equatable, Codable {
    public var subject: String
    public var issuer: String
    public var serialNumber: String
    public var notValidBefore: String
    public var notValidAfter: String
    public var signatureAlgorithm: String
    public var publicKey: String
    public var extensionsCount: Int
    public var summary: String
}

extension CertificateDecoderClient: DependencyKey {
    public static let liveValue = Self(
        decode: { input in
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw CertificateDecoderError.emptyInput }

            let certificate = try parseCertificate(from: trimmed)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let notBefore = formatter.string(from: certificate.notValidBefore)
            let notAfter = formatter.string(from: certificate.notValidAfter)
            let subject = String(describing: certificate.subject)
            let issuer = String(describing: certificate.issuer)
            let serial = String(describing: certificate.serialNumber)
            let signatureAlgorithm = String(describing: certificate.signatureAlgorithm)
            let publicKey = String(describing: certificate.publicKey)
            let extensionsCount = certificate.extensions.count

            let summary = [
                "Subject: \(subject)",
                "Issuer: \(issuer)",
                "Serial: \(serial)",
                "Not Before: \(notBefore)",
                "Not After: \(notAfter)",
                "Signature Algorithm: \(signatureAlgorithm)",
                "Public Key: \(publicKey)",
                "Extensions: \(extensionsCount)",
            ]
            .joined(separator: "\n")

            return CertificateDecodeResult(
                subject: subject,
                issuer: issuer,
                serialNumber: serial,
                notValidBefore: notBefore,
                notValidAfter: notAfter,
                signatureAlgorithm: signatureAlgorithm,
                publicKey: publicKey,
                extensionsCount: extensionsCount,
                summary: summary
            )
        }
    )
}

extension DependencyValues {
    public var certificateDecoder: CertificateDecoderClient {
        get { self[CertificateDecoderClient.self] }
        set { self[CertificateDecoderClient.self] = newValue }
    }
}

public enum CertificateDecoderError: LocalizedError {
    case emptyInput
    case invalidCertificate

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste a PEM or base64 DER certificate"
        case .invalidCertificate:
            return "Invalid certificate data"
        }
    }
}

private func parseCertificate(from input: String) throws -> Certificate {
    if input.contains("BEGIN CERTIFICATE") {
        let pemDocuments = try PEMDocument.parseMultiple(pemString: input)
        guard let pem = pemDocuments.first else { throw CertificateDecoderError.invalidCertificate }
        return try Certificate(derEncoded: pem.derBytes)
    }

    let base64 = input
        .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
        .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
        .replacingOccurrences(of: " ", with: "")

    guard let data = Data(base64Encoded: base64) else {
        throw CertificateDecoderError.invalidCertificate
    }

    return try Certificate(derEncoded: Array(data))
}
