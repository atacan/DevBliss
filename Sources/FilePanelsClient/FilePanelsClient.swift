#if os(macOS)
    import Cocoa
    import Dependencies

    public struct FilePanelsClient {
        public var openPanel: () -> URL
        public var savePanel: (SavePanelMetadata) -> URL?
        public var save: @Sendable (String, URL) async throws -> Void
        public var saveWithPanel: (SavePanelMetadata) -> Void
    }

    private func _openPanel() -> URL {
        let openPanel = NSOpenPanel()
        //                   openPanel.allowedFileTypes = ["txt"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        guard response == .OK, let loadURL = openPanel.url else {
            fatalError()
        }
        return loadURL
    }

    private func _savePanel(_ metadata: SavePanelMetadata) -> URL? {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.allowsOtherFileTypes = true
        savePanel.isExtensionHidden = false
        savePanel.title = metadata.title
        savePanel.message = metadata.message
        savePanel.prompt = metadata.prompt
        let response = savePanel.runModal()
        guard response == .OK, let saveURL = savePanel.url else {
            return nil
        }
        return saveURL
    }

    private func _save(text: String, url: URL) async throws {
        if url.isFileURL {
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
        else {
            // if it is a directory, create a new file in the directory
            let newUrl = url.appendingPathComponent("untitled.txt")
            try text.write(to: newUrl, atomically: true, encoding: .utf8)
        }
    }

    private func _saveWithPanel(_ metadata: SavePanelMetadata) {
        guard let url = _savePanel(metadata) else {
            return
        }
        Task {
            try await _save(text: metadata.textToSave, url: url)
        }
    }

    public struct SavePanelMetadata {
        let title: String
        let message: String
        let prompt: String
        let allowedFileTypes: [String]
        let textToSave: String

        public init(
            title: String = "Save Output as...",
            message: String = "Choose a file name and location to save the output",
            prompt: String = "Save",
            allowedFileTypes: [String] = ["txt"],
            textToSave: String
        ) {
            self.title = title
            self.message = message
            self.prompt = prompt
            self.allowedFileTypes = allowedFileTypes
            self.textToSave = textToSave
        }
    }

    extension FilePanelsClient: DependencyKey {
        public static var liveValue: Self {
            Self(
                openPanel: { _openPanel() },
                savePanel: { _savePanel($0) },
                save: { try await _save(text: $0, url: $1) },
                saveWithPanel: { _saveWithPanel($0) }
            )
        }
    }

    extension DependencyValues {
        public var filePanel: FilePanelsClient.Value {
            get { self[FilePanelsClient.self] }
            set { self[FilePanelsClient.self] = newValue }
        }
    }
#endif
