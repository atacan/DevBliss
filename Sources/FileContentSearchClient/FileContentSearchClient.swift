import Foundation

#if os(macOS)
    import CommandLineClient
    import Dependencies
    import Foundation
    import UniformTypeIdentifiers
    import XCTestDynamicOverlay

    public struct FileContentSearchClient {
        public var run: @Sendable (SearchOptions) async throws -> [FoundFile]
    }

    extension FileContentSearchClient: DependencyKey {
        public static var liveValue = Self(
            run: { try await grepFolder(options: $0) }
        )
    }

    // refactor this by using url.lines instead of grep
    @Sendable
    func grepFolder(options: SearchOptions) async throws -> [FoundFile] {
        let folderUrl = URL(fileURLWithPath: options.folder)
        // list the files in the folder
        //        let files: [URL] = try FileManager.default.contentsOfDirectory(at: folderUrl,
        //        includingPropertiesForKeys: nil)
        //            .filter { url in
        //                guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).contentType
        //                else {
        //                    return false
        //                }
        ////                return UTTypeConformsTo(typeIdentifier as CFString, kUTTypeText)
        //                return UTType.conforms(typeIdentifier)(to: UTType.text)
        //            }

        //        let files = try FileManager.default.contentsOfDirectory(at: folderUrl, includingPropertiesForKeys:
        //        nil)
        let fmOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        let files = walkDirectory(at: folderUrl, options: fmOptions)
            .filter { url in
                guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
                    return false
                }
                return UTTypeConformsTo(typeIdentifier as CFString, kUTTypeText)
            }

        // concurrently run grepFile for each file
        let foundFiles = try await withThrowingTaskGroup(of: FoundFile?.self, returning: [FoundFile].self) { group in
            for await file in files {
                group.addTask {
                    try await grepFile(options: options, fileUrl: file)
                }
            }

            return try await group.reduce(into: []) { result, file in
                if let file {
                    result.append(file)
                }
            }
        }

        return foundFiles
    }

    @Sendable
    func grepFile(options: SearchOptions, fileUrl: URL) async throws -> FoundFile? {
        let lines = fileUrl.lines
        var lineNumbers: [Int] = []
        var lineNumber = 1

        for try await line in lines {
            if line.contains(options.term) {
                lineNumbers.append(lineNumber)
            }
            lineNumber += 1
        }

        guard !lineNumbers.isEmpty else {
            return nil
        }

        let modificationTime = try getModificationTime(for: fileUrl)

        return FoundFile(
            fileURL: fileUrl,
            lineNumbers: lineNumbers,
            modifiedTime: modificationTime,
            gitUsername: nil // TODO: get from another func
        )
    }

    func getModificationTime(for url: URL) throws -> Date {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let date = attributes[.modificationDate] as? Date {
            return date
        } else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get modification time"]
            )
        }
    }

    extension DependencyValues {
        public var fileContentSearch: FileContentSearchClient {
            get { self[FileContentSearchClient.self] }
            set { self[FileContentSearchClient.self] = newValue }
        }
    }

    public struct SearchOptions: Equatable {
        public var term: String
        public var folder: String
        public var searchHiddenFiles: Bool

        public init(
            searchTerm: String = .init(),
            searchFolder: String = .init(),
            searchHiddenFiles: Bool = false
        ) {
            self.term = searchTerm
            self.folder = searchFolder
            self.searchHiddenFiles = searchHiddenFiles
        }
    }

    public struct FoundFile: Equatable, Identifiable {
        public let fileURL: URL
        public let lineNumbers: [Int]
        public let modifiedTime: Date
        public let gitUsername: String?
        public let id: UUID = .init()

        public init(
            fileURL: URL,
            lineNumbers: [Int],
            modifiedTime: Date,
            gitUsername: String?
        ) {
            self.fileURL = fileURL
            self.lineNumbers = lineNumbers
            self.modifiedTime = modifiedTime
            self.gitUsername = gitUsername
        }

        public var lines: String {
            lineNumbers.map(String.init).joined(separator: ", ")
        }

        public var modifiedTimeString: String {
            let modifiedTimeFormatter = DateFormatter()
            modifiedTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return modifiedTimeFormatter.string(from: modifiedTime)
        }

        public var gitUsernameCleaned: String {
            gitUsername ?? ""
        }
    }

    // Recursive iteration
    func walkDirectory(at url: URL, options: FileManager.DirectoryEnumerationOptions) -> AsyncStream<URL> {
        AsyncStream { continuation in
            Task {
                let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: nil,
                    options: options
                )

                while let fileURL = enumerator?.nextObject() as? URL {
                    if fileURL.hasDirectoryPath {
                        for await item in walkDirectory(at: fileURL, options: options) {
                            continuation.yield(item)
                        }
                    } else {
                        continuation.yield(fileURL)
                    }
                }
                continuation.finish()
            }
        }
    }

#endif
