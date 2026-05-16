import Dependencies
import Foundation
import QRCode

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct QrCodeToolClient {
    public var generate: @Sendable (String, QrCodeGenerationConfig) async throws -> QrCodeGenerationResult
    public var decode: @Sendable (String) async throws -> [String]
}

public struct QrCodeGenerationConfig: Equatable, Codable {
    public var dimension: Int
    public var errorCorrection: QrCodeErrorCorrection

    public init(dimension: Int = 256, errorCorrection: QrCodeErrorCorrection = .high) {
        self.dimension = dimension
        self.errorCorrection = errorCorrection
    }
}

public enum QrCodeErrorCorrection: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case quantize = "Quantize"
    case high = "High"

    public var id: Self { self }

    var qrCodeValue: QRCode.ErrorCorrection {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .quantize: return .quantize
        case .high: return .high
        }
    }
}

public struct QrCodeGenerationResult: Equatable, Codable {
    public var base64PNG: String
}

extension QrCodeToolClient: DependencyKey {
    public static let liveValue = Self(
        generate: { input, config in
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw QrCodeToolError.emptyInput }

            let document = QRCode.Document(utf8String: trimmed, errorCorrection: config.errorCorrection.qrCodeValue)
            guard let data = document.imageData(.png(dpi: 72), dimension: config.dimension) else {
                throw QrCodeToolError.generationFailed
            }
            return QrCodeGenerationResult(base64PNG: data.base64EncodedString())
        },
        decode: { input in
            let data = try loadImageData(from: input)
            let messages = detectMessages(from: data)
            guard !messages.isEmpty else { throw QrCodeToolError.noCodesFound }
            return messages
        }
    )
}

extension DependencyValues {
    public var qrCodeTool: QrCodeToolClient {
        get { self[QrCodeToolClient.self] }
        set { self[QrCodeToolClient.self] = newValue }
    }
}

public enum QrCodeToolError: LocalizedError {
    case emptyInput
    case generationFailed
    case invalidImage
    case noCodesFound

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Enter content to generate a QR code"
        case .generationFailed:
            return "Failed to generate QR code image"
        case .invalidImage:
            return "Provide a valid image path or base64 image data"
        case .noCodesFound:
            return "No QR codes found in the image"
        }
    }
}

private func loadImageData(from input: String) throws -> Data {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw QrCodeToolError.emptyInput }

    if FileManager.default.fileExists(atPath: trimmed) {
        return try Data(contentsOf: URL(fileURLWithPath: trimmed))
    }

    if let data = Data(base64Encoded: trimmed, options: .ignoreUnknownCharacters) {
        return data
    }

    throw QrCodeToolError.invalidImage
}

private func detectMessages(from data: Data) -> [String] {
    #if os(macOS)
    guard let image = NSImage(data: data), let features = QRCode.DetectQRCodes(in: image) else {
        return []
    }
    #else
    guard let image = UIImage(data: data), let features = QRCode.DetectQRCodes(in: image) else {
        return []
    }
    #endif

    return features.compactMap { $0.messageString }
}
