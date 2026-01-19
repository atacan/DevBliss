import Dependencies
import Foundation
import SharedModels

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Image Info

public struct Base64ImageInfo: Equatable {
    public let width: Int
    public let height: Int
    public let fileSize: Int
    public let mimeType: String

    public init(width: Int, height: Int, fileSize: Int, mimeType: String) {
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.mimeType = mimeType
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    public var dimensionsString: String {
        "\(width) x \(height) px"
    }
}

// MARK: - Client

public struct Base64ImageClient {
    /// Encode image data to Base64 string with the specified format
    public var encodeToBase64: @Sendable (Data, Base64ImageOutputFormat) -> String

    /// Decode Base64 string to image data (handles data URLs automatically)
    public var decodeFromBase64: @Sendable (String) throws -> Data

    /// Get image info from data
    public var getImageInfo: @Sendable (Data) -> Base64ImageInfo?

    /// Detect MIME type from image data
    public var detectMimeType: @Sendable (Data) -> String

    /// Check if a string is valid Base64 image data
    public var isValidBase64Image: @Sendable (String) -> Bool
}

// MARK: - Dependency Key

extension Base64ImageClient: DependencyKey {
    public static let liveValue = Self(
        encodeToBase64: { data, format in
            let base64String = data.base64EncodedString()
            let mimeType = detectMimeTypeFromData(data)

            switch format {
            case .rawString:
                return base64String
            case .dataURL:
                return "data:\(mimeType);base64,\(base64String)"
            case .cssAttribute:
                return "background-image: url('data:\(mimeType);base64,\(base64String)');"
            }
        },
        decodeFromBase64: { input in
            let processedInput = removeDataURLPrefix(from: input.trimmingCharacters(in: .whitespacesAndNewlines))

            guard let data = Data(base64Encoded: processedInput, options: .ignoreUnknownCharacters) else {
                throw Base64ImageError.invalidBase64
            }

            // Verify it's actually image data
            let mimeType = detectMimeTypeFromData(data)
            guard mimeType.hasPrefix("image/") else {
                throw Base64ImageError.notImageData
            }

            return data
        },
        getImageInfo: { data in
            let mimeType = detectMimeTypeFromData(data)

            #if os(macOS)
            guard let image = NSImage(data: data),
                  let rep = image.representations.first else {
                return nil
            }
            return Base64ImageInfo(
                width: rep.pixelsWide,
                height: rep.pixelsHigh,
                fileSize: data.count,
                mimeType: mimeType
            )
            #else
            guard let image = UIImage(data: data) else {
                return nil
            }
            return Base64ImageInfo(
                width: Int(image.size.width * image.scale),
                height: Int(image.size.height * image.scale),
                fileSize: data.count,
                mimeType: mimeType
            )
            #endif
        },
        detectMimeType: { data in
            detectMimeTypeFromData(data)
        },
        isValidBase64Image: { input in
            let processedInput = removeDataURLPrefix(from: input.trimmingCharacters(in: .whitespacesAndNewlines))

            guard let data = Data(base64Encoded: processedInput, options: .ignoreUnknownCharacters) else {
                return false
            }

            let mimeType = detectMimeTypeFromData(data)
            return mimeType.hasPrefix("image/")
        }
    )
}

// MARK: - Dependency Values

extension DependencyValues {
    public var base64Image: Base64ImageClient {
        get { self[Base64ImageClient.self] }
        set { self[Base64ImageClient.self] = newValue }
    }
}

// MARK: - Errors

public enum Base64ImageError: LocalizedError {
    case invalidBase64
    case notImageData
    case encodingFailed
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidBase64:
            return "The input is not valid Base64"
        case .notImageData:
            return "The decoded data is not a valid image"
        case .encodingFailed:
            return "Failed to encode the image"
        case .decodingFailed:
            return "Failed to decode the image"
        }
    }
}

// MARK: - Helper Functions

private func detectMimeTypeFromData(_ data: Data) -> String {
    guard data.count >= 8 else { return "application/octet-stream" }

    let bytes = [UInt8](data.prefix(12))

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
        return "image/png"
    }

    // JPEG: FF D8 FF
    if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
        return "image/jpeg"
    }

    // GIF: 47 49 46 38 (GIF8)
    if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) {
        return "image/gif"
    }

    // WebP: 52 49 46 46 ... 57 45 42 50 (RIFF....WEBP)
    if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) && data.count >= 12 {
        let webpSignature = [UInt8](data[8..<12])
        if webpSignature == [0x57, 0x45, 0x42, 0x50] {
            return "image/webp"
        }
    }

    // BMP: 42 4D (BM)
    if bytes.starts(with: [0x42, 0x4D]) {
        return "image/bmp"
    }

    // ICO: 00 00 01 00
    if bytes.starts(with: [0x00, 0x00, 0x01, 0x00]) {
        return "image/x-icon"
    }

    // TIFF: 49 49 2A 00 (little endian) or 4D 4D 00 2A (big endian)
    if bytes.starts(with: [0x49, 0x49, 0x2A, 0x00]) || bytes.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
        return "image/tiff"
    }

    return "application/octet-stream"
}

private func removeDataURLPrefix(from input: String) -> String {
    // Pattern: data:[<mediatype>][;base64],<data>
    let pattern = #"^data:[^;,]*;?base64,"#
    if let range = input.range(of: pattern, options: .regularExpression) {
        return String(input[range.upperBound...])
    }
    return input
}
