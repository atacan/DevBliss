import Dependencies
import Foundation
import Observation
import Sharing
import SharedModels
import BlissTheme
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
public final class Base64ImageModel {
    @ObservationIgnored
    @Shared(.base64ImageString) public var base64StringStorage = ""

    @ObservationIgnored
    @Shared(.base64ImageMeta) public var meta = Base64ImageMeta()

    @ObservationIgnored
    @Dependency(\.base64Image) private var base64Image

    @ObservationIgnored
    private var decodeTask: Task<Void, Never>?

    public var base64String: String = ""
    public var imageData: Data?
    public var imageInfo: Base64ImageInfo?
    public var outputFormat: Base64ImageOutputFormat = .dataURL
    public var errorMessage: String?
    public var isProcessing = false

    public var hasImage: Bool { imageData != nil }
    public var outputText: String? { base64String.isEmpty ? nil : base64String }

    public init() {
        base64String = base64StringStorage
        outputFormat = meta.outputFormat

        if let data = meta.imageData {
            imageData = data
            imageInfo = base64Image.getImageInfo(data)
        }
    }

    public func setBase64String(_ input: String) {
        base64String = input
        errorMessage = nil
        $base64StringStorage.withLock { $0 = input }

        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            imageData = nil
            imageInfo = nil
            $meta.withLock { $0.imageData = nil }
            decodeTask?.cancel()
            isProcessing = false
            return
        }

        isProcessing = true
        decodeTask?.cancel()
        decodeTask = Task { [weak self, input = input, base64Image = base64Image] in
            do {
                let data = try base64Image.decodeFromBase64(input)
                await MainActor.run {
                    guard let self else { return }
                    isProcessing = false
                    imageData = data
                    imageInfo = base64Image.getImageInfo(data)
                    $meta.withLock { $0.imageData = data }
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    isProcessing = false
                    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.count > 50 || trimmed.hasPrefix("data:") {
                        errorMessage = error.localizedDescription
                    }
                    imageData = nil
                    imageInfo = nil
                    $meta.withLock { $0.imageData = nil }
                }
            }
        }
    }

    public func setOutputFormat(_ format: Base64ImageOutputFormat) {
        outputFormat = format
        $meta.withLock { $0.outputFormat = format }

        if let imageData {
            let encoded = base64Image.encodeToBase64(imageData, format)
            base64String = encoded
            $base64StringStorage.withLock { $0 = encoded }
        }
    }

    public func loadFileButtonTapped() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .bmp, .tiff, .ico]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            loadImage(data)
        } catch {
            errorMessage = "Failed to load file: \\(error.localizedDescription)"
        }
        #endif
    }

    public func pasteImageFromClipboardTapped() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        if let data = pasteboard.data(forType: .png) {
            loadImage(data)
        } else if let data = pasteboard.data(forType: .tiff),
                  let image = NSImage(data: data),
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) {
            loadImage(pngData)
        } else if let string = pasteboard.string(forType: .string),
                  base64Image.isValidBase64Image(string) {
            setBase64String(string)
        } else {
            errorMessage = "No image found in clipboard"
        }
        #endif
    }

    public func clearImageTapped() {
        imageData = nil
        imageInfo = nil
        base64String = ""
        errorMessage = nil
        $meta.withLock { $0.imageData = nil }
        $base64StringStorage.withLock { $0 = "" }
        decodeTask?.cancel()
        isProcessing = false
    }

    public func saveImageTapped() {
        #if os(macOS)
        guard let imageData else { return }
        let panel = NSSavePanel()
        let mimeType = base64Image.detectMimeType(imageData)
        let (defaultExtension, allowedType): (String, UTType) = {
            switch mimeType {
            case "image/png": return ("png", .png)
            case "image/jpeg": return ("jpg", .jpeg)
            case "image/gif": return ("gif", .gif)
            case "image/webp": return ("webp", .webP)
            default: return ("png", .png)
            }
        }()
        panel.allowedContentTypes = [allowedType]
        panel.nameFieldStringValue = "image.\\(defaultExtension)"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try imageData.write(to: url)
        } catch {
            errorMessage = "Failed to save file: \\(error.localizedDescription)"
        }
        #endif
    }

    public func copyImageTapped() {
        #if os(macOS)
        guard let imageData, let image = NSImage(data: imageData) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        #else
        guard let imageData else { return }
        if let image = UIImage(data: imageData) {
            UIPasteboard.general.image = image
        }
        #endif
    }

    public func copyBase64Tapped() {
        guard !base64String.isEmpty else { return }
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(base64String, forType: .string)
        #else
        UIPasteboard.general.string = base64String
        #endif
    }

    private func loadImage(_ data: Data) {
        imageData = data
        imageInfo = base64Image.getImageInfo(data)
        errorMessage = nil

        let encoded = base64Image.encodeToBase64(data, outputFormat)
        base64String = encoded
        $base64StringStorage.withLock { $0 = encoded }
        $meta.withLock { $0.imageData = data }
    }
}

public struct Base64ImageModelView: View {
    @Bindable var model: Base64ImageModel

    public init(model: Base64ImageModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }
            #if os(macOS)
            HSplitView { leftColumn; rightColumn }
            #else
            VStack(spacing: 0) { leftColumn; Divider(); rightColumn }
            #endif
        }
    }

    private var leftColumn: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Base64 String")
                    .font(.headline)
                Spacer()
                Picker("Format", selection: Binding(get: { model.outputFormat }, set: { model.setOutputFormat($0) })) {
                    ForEach(Base64ImageOutputFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            TextEditor(text: Binding(get: { model.base64String }, set: { model.setBase64String($0) }))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                #if os(macOS)
                .background(ThemeColor.Background.textBackground)
                #endif
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        #if os(macOS)
                        .stroke(ThemeColor.Background.separator, lineWidth: 1)
                        #endif
                )
                .padding(.horizontal, 12)

            HStack {
                Spacer()
                Button {
                    model.copyBase64Tapped()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(model.base64String.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var rightColumn: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Image").font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        model.loadFileButtonTapped()
                    } label: {
                        Label("Load File…", systemImage: "folder")
                    }
                    Button {
                        model.pasteImageFromClipboardTapped()
                    } label: {
                        Label("Paste", systemImage: "clipboard")
                    }
                    Button {
                        model.clearImageTapped()
                    } label: {
                        Label("Clear", systemImage: "xmark")
                    }
                    .disabled(!model.hasImage)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    #if os(macOS)
                    .fill(ThemeColor.Background.windowBackground)
                    #endif
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            #if os(macOS)
                            .stroke(ThemeColor.Background.separator, lineWidth: 1)
                            #endif
                    )

                if let imageData = model.imageData {
                    #if os(macOS)
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    }
                    #else
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    }
                    #endif
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No image loaded")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("Load a file, paste from clipboard, or enter Base64 string")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }

                if model.isProcessing {
                    ProgressView().controlSize(.large)
                }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 12) {
                Button {
                    model.saveImageTapped()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(!model.hasImage)
                Button {
                    model.copyImageTapped()
                } label: {
                    Label("Copy Image", systemImage: "photo.on.rectangle")
                }
                .disabled(!model.hasImage)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            if let info = model.imageInfo {
                Text("\\(info.dimensionsString) - \\(info.formattedSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

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
        "\\(width) x \\(height) px"
    }
}

public struct Base64ImageClient {
    public var encodeToBase64: @Sendable (Data, Base64ImageOutputFormat) -> String
    public var decodeFromBase64: @Sendable (String) throws -> Data
    public var getImageInfo: @Sendable (Data) -> Base64ImageInfo?
    public var detectMimeType: @Sendable (Data) -> String
    public var isValidBase64Image: @Sendable (String) -> Bool

    public static let liveValue = Self(
        encodeToBase64: { data, format in
            let base64String = data.base64EncodedString()
            let mimeType = detectMimeTypeFromData(data)
            switch format {
            case .rawString:
                return base64String
            case .dataURL:
                return "data:\\(mimeType);base64,\\(base64String)"
            case .cssAttribute:
                return "background-image: url('data:\\(mimeType);base64,\\(base64String)');"
            }
        },
        decodeFromBase64: { input in
            let processedInput = removeDataURLPrefix(from: input.trimmingCharacters(in: .whitespacesAndNewlines))
            guard let data = Data(base64Encoded: processedInput, options: .ignoreUnknownCharacters) else {
                throw Base64ImageError.invalidBase64
            }
            let mimeType = detectMimeTypeFromData(data)
            guard mimeType.hasPrefix("image/") else {
                throw Base64ImageError.notImageData
            }
            return data
        },
        getImageInfo: { data in
            let mimeType = detectMimeTypeFromData(data)
            #if os(macOS)
            guard let image = NSImage(data: data), let rep = image.representations.first else {
                return nil
            }
            return Base64ImageInfo(width: rep.pixelsWide, height: rep.pixelsHigh, fileSize: data.count, mimeType: mimeType)
            #else
            guard let image = UIImage(data: data) else { return nil }
            return Base64ImageInfo(width: Int(image.size.width * image.scale), height: Int(image.size.height * image.scale), fileSize: data.count, mimeType: mimeType)
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

extension Base64ImageClient: DependencyKey {}

extension Base64ImageClient: Sendable {}

extension DependencyValues {
    public var base64Image: Base64ImageClient {
        get { self[Base64ImageClient.self] }
        set { self[Base64ImageClient.self] = newValue }
    }
}

public enum Base64ImageError: LocalizedError {
    case invalidBase64
    case notImageData
    case encodingFailed
    case decodingFailed
}

private func detectMimeTypeFromData(_ data: Data) -> String {
    guard data.count >= 8 else { return "application/octet-stream" }
    let bytes = [UInt8](data.prefix(12))

    if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return "image/png" }
    if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
    if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) { return "image/gif" }
    if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) && data.count >= 12 {
        let webpSignature = [UInt8](data[8..<12])
        if webpSignature == [0x57, 0x45, 0x42, 0x50] { return "image/webp" }
    }
    if bytes.starts(with: [0x42, 0x4D]) { return "image/bmp" }
    if bytes.starts(with: [0x00, 0x00, 0x01, 0x00]) { return "image/x-icon" }
    if bytes.starts(with: [0x49, 0x49, 0x2A, 0x00]) || bytes.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
        return "image/tiff"
    }
    return "application/octet-stream"
}

private func removeDataURLPrefix(from input: String) -> String {
    let pattern = #"^data:[^;,]*;?base64,"#
    if let range = input.range(of: pattern, options: .regularExpression) {
        return String(input[range.upperBound...])
    }
    return input
}

struct Base64ImageModelView_Previews: PreviewProvider {
    static var previews: some View {
        Base64ImageModelView(model: .init())
    }
}
