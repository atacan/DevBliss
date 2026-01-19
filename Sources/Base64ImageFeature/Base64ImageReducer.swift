import Base64ImageClient
import BlissTheme
import ComposableArchitecture
import SharedModels
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

// MARK: - Reducer

@Reducer
public struct Base64ImageReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.base64ImageIO) public var storage = Base64ImageStorage()
        public var base64String: String = ""
        public var imageData: Data?
        public var imageInfo: Base64ImageInfo?
        public var outputFormat: Base64ImageOutputFormat = .dataURL
        public var errorMessage: String?
        public var isProcessing: Bool = false

        public init() {
            self.base64String = storage.base64String
            if let data = storage.imageData {
                self.imageData = data
            }
            self.outputFormat = storage.outputFormat
        }

        public var hasImage: Bool {
            imageData != nil
        }

        public var outputText: String? {
            base64String.isEmpty ? nil : base64String
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case base64StringChanged(String)
        case outputFormatChanged(Base64ImageOutputFormat)
        case loadFileButtonTapped
        case pasteImageFromClipboardTapped
        case clearImageTapped
        case saveImageTapped
        case copyImageTapped
        case copyBase64Tapped
        case imageLoaded(Data)
        case decodeBase64Response(TaskResult<Data>)
        case encodeImageResponse(String)
    }

    @Dependency(\.base64Image) var base64Image
    private enum CancelID { case decodeRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case let .base64StringChanged(newString):
                state.base64String = newString
                state.errorMessage = nil

                // Save to storage
                state.$storage.withLock { $0.base64String = newString }

                // If empty, clear everything
                guard !newString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.imageData = nil
                    state.imageInfo = nil
                    state.$storage.withLock { $0.imageData = nil }
                    return .none
                }

                // Try to auto-decode if it looks like valid Base64 image
                state.isProcessing = true
                return .run { [base64Image] send in
                    await send(
                        .decodeBase64Response(
                            TaskResult {
                                try base64Image.decodeFromBase64(newString)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.decodeRequest, cancelInFlight: true)

            case let .outputFormatChanged(format):
                state.outputFormat = format
                state.$storage.withLock { $0.outputFormat = format }

                // Re-encode with new format if we have image data
                if let imageData = state.imageData {
                    let encoded = base64Image.encodeToBase64(imageData, format)
                    state.base64String = encoded
                    state.$storage.withLock { $0.base64String = encoded }
                }
                return .none

            case .loadFileButtonTapped:
                #if os(macOS)
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .bmp, .tiff, .ico]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false

                guard panel.runModal() == .OK, let url = panel.url else {
                    return .none
                }

                do {
                    let data = try Data(contentsOf: url)
                    return .send(.imageLoaded(data))
                } catch {
                    state.errorMessage = "Failed to load file: \(error.localizedDescription)"
                    return .none
                }
                #else
                return .none
                #endif

            case .pasteImageFromClipboardTapped:
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                if let data = pasteboard.data(forType: .png) {
                    return .send(.imageLoaded(data))
                } else if let data = pasteboard.data(forType: .tiff) {
                    // Convert TIFF to PNG
                    if let image = NSImage(data: data),
                       let tiffData = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                        return .send(.imageLoaded(pngData))
                    }
                } else if let string = pasteboard.string(forType: .string),
                          base64Image.isValidBase64Image(string) {
                    // Handle pasted Base64 string
                    return .send(.base64StringChanged(string))
                }
                state.errorMessage = "No image found in clipboard"
                #endif
                return .none

            case .clearImageTapped:
                state.imageData = nil
                state.imageInfo = nil
                state.base64String = ""
                state.errorMessage = nil
                state.$storage.withLock {
                    $0.imageData = nil
                    $0.base64String = ""
                }
                return .none

            case .saveImageTapped:
                #if os(macOS)
                guard let imageData = state.imageData else { return .none }

                let panel = NSSavePanel()
                let mimeType = base64Image.detectMimeType(imageData)
                let defaultExtension: String
                let allowedType: UTType

                switch mimeType {
                case "image/png":
                    defaultExtension = "png"
                    allowedType = .png
                case "image/jpeg":
                    defaultExtension = "jpg"
                    allowedType = .jpeg
                case "image/gif":
                    defaultExtension = "gif"
                    allowedType = .gif
                case "image/webp":
                    defaultExtension = "webp"
                    allowedType = .webP
                default:
                    defaultExtension = "png"
                    allowedType = .png
                }

                panel.allowedContentTypes = [allowedType]
                panel.nameFieldStringValue = "image.\(defaultExtension)"

                guard panel.runModal() == .OK, let url = panel.url else {
                    return .none
                }

                do {
                    try imageData.write(to: url)
                } catch {
                    state.errorMessage = "Failed to save file: \(error.localizedDescription)"
                }
                #endif
                return .none

            case .copyImageTapped:
                #if os(macOS)
                guard let imageData = state.imageData,
                      let image = NSImage(data: imageData) else {
                    return .none
                }

                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
                #endif
                return .none

            case .copyBase64Tapped:
                #if os(macOS)
                guard !state.base64String.isEmpty else { return .none }

                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(state.base64String, forType: .string)
                #endif
                return .none

            case let .imageLoaded(data):
                state.imageData = data
                state.imageInfo = base64Image.getImageInfo(data)
                state.errorMessage = nil

                // Encode to Base64 with current format
                let encoded = base64Image.encodeToBase64(data, state.outputFormat)
                state.base64String = encoded

                // Save to storage
                state.$storage.withLock {
                    $0.imageData = data
                    $0.base64String = encoded
                }
                return .none

            case let .decodeBase64Response(.success(data)):
                state.isProcessing = false
                state.imageData = data
                state.imageInfo = base64Image.getImageInfo(data)
                state.errorMessage = nil
                state.$storage.withLock { $0.imageData = data }
                return .none

            case let .decodeBase64Response(.failure(error)):
                state.isProcessing = false
                // Don't show error for every invalid input - only if it looks like an attempt
                let trimmed = state.base64String.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 50 || trimmed.hasPrefix("data:") {
                    state.errorMessage = error.localizedDescription
                }
                state.imageData = nil
                state.imageInfo = nil
                state.$storage.withLock { $0.imageData = nil }
                return .none

            case let .encodeImageResponse(encoded):
                state.base64String = encoded
                state.$storage.withLock { $0.base64String = encoded }
                return .none
            }
        }
    }
}

// MARK: - View

public struct Base64ImageView: View {
    @Bindable var store: StoreOf<Base64ImageReducer>

    public init(store: StoreOf<Base64ImageReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Error message
            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            // Main content
            HSplitView {
                // Left: Base64 String Section
                stringSection
                    .frame(minWidth: 300)

                // Right: Image Section
                imageSection
                    .frame(minWidth: 300)
            }
        }
    }

    // MARK: - String Section

    @ViewBuilder
    private var stringSection: some View {
        VStack(spacing: 12) {
            // Header with output format picker
            HStack {
                Text("Base64 String")
                    .font(.headline)

                Spacer()

                Picker("Format", selection: Binding(
                    get: { store.outputFormat },
                    set: { store.send(.outputFormatChanged($0)) }
                )) {
                    ForEach(Base64ImageOutputFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Text editor for Base64
            TextEditor(text: Binding(
                get: { store.base64String },
                set: { store.send(.base64StringChanged($0)) }
            ))
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            #if os(macOS)
            .background(Color(nsColor: .textBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    #if os(macOS)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    #endif
            )
            .padding(.horizontal, 12)

            // Copy button
            HStack {
                Spacer()

                Button {
                    store.send(.copyBase64Tapped)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(store.base64String.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private var imageSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Image Preview")
                    .font(.headline)

                Spacer()

                if let info = store.imageInfo {
                    Text("\(info.dimensionsString) - \(info.formattedSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Image preview area
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    #if os(macOS)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    #endif
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            #if os(macOS)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            #endif
                    )

                if let imageData = store.imageData {
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

                if store.isProcessing {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 12)

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    store.send(.loadFileButtonTapped)
                } label: {
                    Label("Load File...", systemImage: "folder")
                }

                Button {
                    store.send(.pasteImageFromClipboardTapped)
                } label: {
                    Label("Paste", systemImage: "clipboard")
                }

                Spacer()

                Button {
                    store.send(.clearImageTapped)
                } label: {
                    Label("Clear", systemImage: "xmark")
                }
                .disabled(!store.hasImage)

                Button {
                    store.send(.saveImageTapped)
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(!store.hasImage)

                Button {
                    store.send(.copyImageTapped)
                } label: {
                    Label("Copy Image", systemImage: "photo.on.rectangle")
                }
                .disabled(!store.hasImage)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Preview

struct Base64ImageReducer_Previews: PreviewProvider {
    static var previews: some View {
        Base64ImageView(store: .init(initialState: .init()) { Base64ImageReducer() })
            .frame(width: 800, height: 500)
    }
}
