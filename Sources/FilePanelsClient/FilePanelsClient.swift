#if os(macOS)
    import Dependencies
    import Cocoa

    public struct FilePanelsClient {
        // public var openPanel: () -> URL
        public var savePanel: (SavePanelMetadata) -> Void
    }

    extension FilePanelsClient: DependencyKey {
        public static var liveValue: Self {
            Self(
                // openPanel: { NSOpenPanel() },
                savePanel: { saveWithPanel($0) }
            )
        }
    }

    private func saveWithPanel(_ metadata: SavePanelMetadata) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.allowsOtherFileTypes = true
        savePanel.isExtensionHidden = false
        savePanel.title = metadata.title
        savePanel.message = metadata.message
        savePanel.prompt = metadata.prompt
        let response = savePanel.runModal()
        guard response == .OK, let saveURL = savePanel.url else { return }
        try? metadata.textToSave.write(to: saveURL, atomically: true, encoding: .utf8)
    }

    public struct SavePanelMetadata {
        let title: String
        let message: String
        let prompt: String
        let allowedFileTypes: [String]
        let textToSave: String
    }

#endif
