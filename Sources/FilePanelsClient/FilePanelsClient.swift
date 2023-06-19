#if os(macOS)
    import Dependencies
    import Cocoa

    public struct FilePanelsClient {
         public var openPanel: () -> URL
        public var savePanel: (SavePanelMetadata) -> URL
        public var save: @Sendable (String, URL) async throws -> Void
    }

    extension FilePanelsClient: DependencyKey {
        public static var liveValue: Self {
            Self(
                openPanel: {
                   let openPanel = NSOpenPanel()
//                   openPanel.allowedFileTypes = ["txt"]
                   openPanel.allowsMultipleSelection = false
                   openPanel.canChooseDirectories = true
                   openPanel.canChooseFiles = true
                   let response = openPanel.runModal()
                    guard response == .OK, let loadURL = openPanel.url else { fatalError() }
                   return loadURL
                },
                savePanel: {metadata in 
                    let savePanel = NSSavePanel()
                    savePanel.canCreateDirectories = true
                    savePanel.canSelectHiddenExtension = true
                    savePanel.allowsOtherFileTypes = true
                    savePanel.isExtensionHidden = false
                    savePanel.title = metadata.title
                    savePanel.message = metadata.message
                    savePanel.prompt = metadata.prompt
                    let response = savePanel.runModal()
                    guard response == .OK, let saveURL = savePanel.url else { fatalError() }
                    return saveURL
                },
                save: { text, url in
                    if url.isFileURL {
                        try text.write(to: url, atomically: true, encoding: .utf8)
                    } else {
                        // if it is a directory, create a new file in the directory
                        let newUrl = url.appendingPathComponent("untitled.txt")
                        try text.write(to: newUrl, atomically: true, encoding: .utf8)

                    }
                }
            )
        }
    }

    extension DependencyValues {
        public var filePanels: FilePanelsClient.Value {
            get { self[FilePanelsClient.self] }
            set { self[FilePanelsClient.self] = newValue }
        }
    }

//public enum FileFolder{
//    case file(URL)
//    case folder([])
//}

    public struct SavePanelMetadata {
        let title: String
        let message: String
        let prompt: String
        let allowedFileTypes: [String]
//        let textToSave: String

        public init(
            title: String = "Save your text",
            message: String = "Choose a location and name your file",
            prompt: String = "Save",
            allowedFileTypes: [String] = []
//            textToSave: String
        ) {
            self.title = title
            self.message = message
            self.prompt = prompt
            self.allowedFileTypes = allowedFileTypes
//            self.textToSave = textToSave
        }
    }

#endif
