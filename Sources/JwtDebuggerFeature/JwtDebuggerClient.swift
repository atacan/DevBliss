import CryptoKit
import Dependencies
import Foundation
import JWTDecode
import Security

public struct JwtClaimItem: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let value: String

    public init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

public enum JwtSignatureVerification: Equatable {
    case verified
    case invalid
    case noSecret
    case unsupportedAlgorithm(String)
    case invalidToken
    case missingAlgorithm
    case invalidKey
}

public struct JwtDebugInspection: Equatable {
    public let headerJSON: String
    public let payloadJSON: String
    public let signature: String
    public let algorithm: String?
    public let claims: [JwtClaimItem]
    public let verification: JwtSignatureVerification

    public init(
        headerJSON: String,
        payloadJSON: String,
        signature: String,
        algorithm: String?,
        claims: [JwtClaimItem],
        verification: JwtSignatureVerification
    ) {
        self.headerJSON = headerJSON
        self.payloadJSON = payloadJSON
        self.signature = signature
        self.algorithm = algorithm
        self.claims = claims
        self.verification = verification
    }
}

public enum JwtDebuggerError: LocalizedError, Equatable {
    case emptyToken
    case invalidPartCount(Int)
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .emptyToken:
            return "JWT token is empty"
        case let .invalidPartCount(count):
            return "JWT must have 3 parts, got \(count)"
        case .invalidJSON:
            return "Decoded token is not valid JSON"
        }
    }
}

public struct JwtDebuggerClient {
    public var inspect: @Sendable (String, String?) async throws -> JwtDebugInspection

    public init(inspect: @escaping @Sendable (String, String?) async throws -> JwtDebugInspection) {
        self.inspect = inspect
    }
}

extension JwtDebuggerClient: DependencyKey {
    public static let liveValue = Self(
        inspect: { token, secret in
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw JwtDebuggerError.emptyToken
            }

            let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 3 else {
                throw JwtDebuggerError.invalidPartCount(parts.count)
            }

            let jwt = try decode(jwt: trimmed)

            let headerJSON = try prettyPrintedJSON(from: jwt.header)
            let payloadJSON = try prettyPrintedJSON(from: jwt.body)
            let algorithm = jwt.header["alg"] as? String
            let signature = String(parts[2])
            let claims = buildClaims(from: jwt)

            let verification = verifySignature(
                headerPart: String(parts[0]),
                payloadPart: String(parts[1]),
                signaturePart: signature,
                algorithm: algorithm,
                secret: secret
            )

            return JwtDebugInspection(
                headerJSON: headerJSON,
                payloadJSON: payloadJSON,
                signature: signature,
                algorithm: algorithm,
                claims: claims,
                verification: verification
            )
        }
    )

    public static let testValue = Self(
        inspect: unimplemented("\(Self.self).inspect")
    )
}

public extension DependencyValues {
    var jwtDebugger: JwtDebuggerClient {
        get { self[JwtDebuggerClient.self] }
        set { self[JwtDebuggerClient.self] = newValue }
    }
}

private func prettyPrintedJSON(from object: Any) throws -> String {
    guard JSONSerialization.isValidJSONObject(object) else {
        throw JwtDebuggerError.invalidJSON
    }

    let data = try JSONSerialization.data(
        withJSONObject: object,
        options: [.prettyPrinted, .sortedKeys]
    )

    return String(data: data, encoding: .utf8) ?? "{}"
}

private func buildClaims(from jwt: JWT) -> [JwtClaimItem] {
    var claims: [JwtClaimItem] = []

    if let issuer = jwt.issuer {
        claims.append(.init(title: "Issuer (iss)", value: issuer))
    }

    if let subject = jwt.subject {
        claims.append(.init(title: "Subject (sub)", value: subject))
    }

    if let audience = jwt.audience?.joined(separator: ", ") {
        claims.append(.init(title: "Audience (aud)", value: audience))
    }

    if let issuedAt = formatTimestampClaim(jwt.claim(name: "iat")) {
        claims.append(.init(title: "Issued At (iat)", value: issuedAt))
    }

    if let notBefore = formatTimestampClaim(jwt.claim(name: "nbf")) {
        claims.append(.init(title: "Not Before (nbf)", value: notBefore))
    }

    if let expiresAt = formatTimestampClaim(jwt.claim(name: "exp")) {
        claims.append(.init(title: "Expiration (exp)", value: expiresAt))
    }

    if let identifier = jwt.identifier {
        claims.append(.init(title: "JWT ID (jti)", value: identifier))
    }

    return claims
}

private func formatTimestampClaim(_ claim: Claim) -> String? {
    guard let timestamp = claim.double else {
        return nil
    }

    let date = Date(timeIntervalSince1970: timestamp)
    let formatted = jwtDateFormatter.string(from: date)
    return "\(Int(timestamp)) (\(formatted))"
}

private let jwtDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
    formatter.timeZone = .current
    return formatter
}()

private func verifySignature(
    headerPart: String,
    payloadPart: String,
    signaturePart: String,
    algorithm: String?,
    secret: String?
) -> JwtSignatureVerification {
    guard let secret = secret, !secret.isEmpty else {
        return .noSecret
    }

    guard let algorithm = algorithm, !algorithm.isEmpty else {
        return .missingAlgorithm
    }

    let signingInput = "\(headerPart).\(payloadPart)"
    let normalizedAlg = algorithm.uppercased()

    switch normalizedAlg {
    case "HS256":
        let expected = hmacBase64Url(SHA256.self, signingInput: signingInput, secret: secret)
        return expected == signaturePart ? .verified : .invalid
    case "HS384":
        let expected = hmacBase64Url(SHA384.self, signingInput: signingInput, secret: secret)
        return expected == signaturePart ? .verified : .invalid
    case "HS512":
        let expected = hmacBase64Url(SHA512.self, signingInput: signingInput, secret: secret)
        return expected == signaturePart ? .verified : .invalid
    case "RS256":
        return verifyAsymmetricSignature(
            signingInput: signingInput,
            signaturePart: signaturePart,
            keyString: secret,
            keyType: kSecAttrKeyTypeRSA,
            algorithm: .rsaSignatureMessagePKCS1v15SHA256
        )
    case "RS384":
        return verifyAsymmetricSignature(
            signingInput: signingInput,
            signaturePart: signaturePart,
            keyString: secret,
            keyType: kSecAttrKeyTypeRSA,
            algorithm: .rsaSignatureMessagePKCS1v15SHA384
        )
    case "RS512":
        return verifyAsymmetricSignature(
            signingInput: signingInput,
            signaturePart: signaturePart,
            keyString: secret,
            keyType: kSecAttrKeyTypeRSA,
            algorithm: .rsaSignatureMessagePKCS1v15SHA512
        )
    case "ES256":
        return verifyAsymmetricSignature(
            signingInput: signingInput,
            signaturePart: signaturePart,
            keyString: secret,
            keyType: kSecAttrKeyTypeECSECPrimeRandom,
            algorithm: .ecdsaSignatureMessageX962SHA256,
            signatureFormat: .ecdsaRaw
        )
    case "ES384":
        return verifyAsymmetricSignature(
            signingInput: signingInput,
            signaturePart: signaturePart,
            keyString: secret,
            keyType: kSecAttrKeyTypeECSECPrimeRandom,
            algorithm: .ecdsaSignatureMessageX962SHA384,
            signatureFormat: .ecdsaRaw
        )
    case "ES512":
        return verifyAsymmetricSignature(
            signingInput: signingInput,
            signaturePart: signaturePart,
            keyString: secret,
            keyType: kSecAttrKeyTypeECSECPrimeRandom,
            algorithm: .ecdsaSignatureMessageX962SHA512,
            signatureFormat: .ecdsaRaw
        )
    default:
        return .unsupportedAlgorithm(algorithm)
    }
}

private func hmacBase64Url<H: HashFunction>(
    _ hash: H.Type,
    signingInput: String,
    secret: String
) -> String {
    let key = SymmetricKey(data: Data(secret.utf8))
    let data = Data(signingInput.utf8)
    let signature = HMAC<H>.authenticationCode(for: data, using: key)
    return base64UrlEncode(Data(signature))
}

private func base64UrlEncode(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}

private enum SignatureFormat {
    case raw
    case ecdsaRaw
}

private func verifyAsymmetricSignature(
    signingInput: String,
    signaturePart: String,
    keyString: String,
    keyType: CFString,
    algorithm: SecKeyAlgorithm,
    signatureFormat: SignatureFormat = .raw
) -> JwtSignatureVerification {
    guard let signatureData = base64UrlDecode(signaturePart) else {
        return .invalidToken
    }

    let verificationSignature: Data
    switch signatureFormat {
    case .raw:
        verificationSignature = signatureData
    case .ecdsaRaw:
        guard let derSignature = ecdsaDerSignature(from: signatureData) else {
            return .invalidToken
        }
        verificationSignature = derSignature
    }

    guard let keyData = keyData(from: keyString) else {
        return .invalidKey
    }

    let attributes: [String: Any] = [
        kSecAttrKeyType as String: keyType,
        kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
    ]

    guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil) else {
        return .invalidKey
    }

    let messageData = Data(signingInput.utf8)
    var error: Unmanaged<CFError>?
    let isValid = SecKeyVerifySignature(
        key,
        algorithm,
        messageData as CFData,
        verificationSignature as CFData,
        &error
    )

    if error != nil {
        return .invalidKey
    }

    return isValid ? .verified : .invalid
}

private func keyData(from keyString: String) -> Data? {
    let trimmed = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        return nil
    }

    let lines = trimmed
        .split(whereSeparator: \.isNewline)
        .filter { !$0.hasPrefix("-----") }
    let base64 = lines.joined().replacingOccurrences(of: " ", with: "")

    if let data = Data(base64Encoded: base64) {
        return data
    }

    return Data(base64Encoded: trimmed)
}

private func ecdsaDerSignature(from raw: Data) -> Data? {
    guard raw.count % 2 == 0 else {
        return nil
    }

    let half = raw.count / 2
    let r = raw.prefix(half)
    let s = raw.suffix(half)

    let derR = derInteger(from: Data(r))
    let derS = derInteger(from: Data(s))

    let totalLength = derR.count + derS.count
    guard let lengthBytes = derLength(totalLength) else {
        return nil
    }

    var sequence = Data([0x30])
    sequence.append(contentsOf: lengthBytes)
    sequence.append(derR)
    sequence.append(derS)
    return sequence
}

private func derInteger(from raw: Data) -> Data {
    var bytes = [UInt8](raw)
    while bytes.count > 1 && bytes.first == 0 {
        bytes.removeFirst()
    }

    if let first = bytes.first, first & 0x80 == 0x80 {
        bytes.insert(0x00, at: 0)
    }

    var data = Data([0x02])
    data.append(contentsOf: derLength(bytes.count) ?? [])
    data.append(contentsOf: bytes)
    return data
}

private func derLength(_ length: Int) -> [UInt8]? {
    guard length >= 0 else {
        return nil
    }
    if length < 0x80 {
        return [UInt8(length)]
    }
    var value = length
    var bytes: [UInt8] = []
    while value > 0 {
        bytes.insert(UInt8(value & 0xFF), at: 0)
        value >>= 8
    }
    guard bytes.count < 0x80 else {
        return nil
    }
    return [0x80 | UInt8(bytes.count)] + bytes
}
