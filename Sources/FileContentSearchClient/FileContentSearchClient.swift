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

    @Sendable
    func grepFolder(options: SearchOptions) async throws -> [FoundFile] {
        let folderUrl = URL(fileURLWithPath: options.folder)
        var fmOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !options.searchHiddenFiles {
            fmOptions.insert(.skipsHiddenFiles)
        }
        let files = walkDirectory(
            at: folderUrl,
            options: fmOptions,
            folderCondition: { url in
//                if let isHidden = try? url.resourceValues(forKeys: [.isHiddenKey]).isHidden {
//                    return isHidden == options.searchHiddenFiles
//                        && url.lastPathComponent.hasPrefix(".")
//                        == options
//                        .searchHiddenFiles
//                } else {
//                if options.searchHiddenFiles {return true} else{
//                    return !url.lastPathComponent.hasPrefix(".")
//                }
                true
//                }
            }
        ) { url in
            guard let typeIdentifier = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
                  let isHidden = try? url.resourceValues(forKeys: [.isHiddenKey]).isHidden,
                  (isHidden == options.searchHiddenFiles) || (options.searchHiddenFiles)
            else {
                return false
            }
            return typeIdentifier.conforms(to: UTType.text)
        }

        // concurrently run grepFile for each file
        let foundFiles = try await withThrowingTaskGroup(of: FoundFile?.self, returning: [FoundFile].self) { group in
            for try await file in files {
//                print(file)
                group.addTask {
                    try await grepFile(options: options, fileUrl: file)
                }
                // otherwise it throws "too many files open" error
                await Task.yield()
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
        var lineNumbers: [Int] = []
        var lineNumber = 1

//        for try await line in fileUrl.lines {
//            if line.contains(options.term) {
//                lineNumbers.append(lineNumber)
//            }
//            lineNumber += 1
//        }

//        let qfle = QFile(fileURL: fileUrl)
//        try qfle.open()
//        defer{qfle.close()}
//        while let line = try qfle.readLine() {
//            if line.contains(options.term) {
//                lineNumbers.append(lineNumber)
//            }
//            lineNumber += 1
//        }

        let handle = try FileHandle(forReadingFrom: fileUrl)
        defer { try? handle.close() }
        for try await line in handle.bytes.lines {
            if line.contains(options.term) {
                lineNumbers.append(lineNumber)
            }
            lineNumber += 1
        }

        guard !lineNumbers.isEmpty else {
            return nil
        }

        let modificationTime = try getModificationTime(for: fileUrl)

        return try await FoundFile(
            fileURL: fileUrl,
            lineNumbers: lineNumbers,
            modifiedTime: modificationTime,
            gitUsername: getLastCommitAuthor(for: fileUrl)
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

    func getLastCommitAuthor(for fileURL: URL) async throws -> String? {
        @Dependency(\.commandLine) var commandLine
        let command =
            "cd \(fileURL.deletingLastPathComponent().path) && git log -1 --pretty=format:%an -- \(fileURL.lastPathComponent)"
        let output = try await commandLine.run(command)
        return output.text.trimmingCharacters(in: .whitespacesAndNewlines)
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
    func walkDirectory(
        at url: URL,
        options: FileManager.DirectoryEnumerationOptions,
        folderCondition: @escaping (URL) -> Bool,
        fileCondition: @escaping (URL) -> Bool
    ) -> AsyncStream<URL> {
        AsyncStream { continuation in
            Task {
                let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: nil,
                    options: options
                )

                while let fileURL = enumerator?.nextObject() as? URL {
                    if fileURL.hasDirectoryPath,
                       folderCondition(fileURL) {
                        for await item in walkDirectory(
                            at: fileURL,
                            options: options,
                            folderCondition: folderCondition,
                            fileCondition: fileCondition
                        ) {
                            continuation.yield(item)
                        }
                    } else if fileCondition(fileURL) {
                        continuation.yield(fileURL)
                    }
                }
                continuation.finish()
            }
        }
    }

#endif

class QFile {
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    deinit {
        // You must close before releasing the last reference.
        precondition(self.file == nil)
    }

    let fileURL: URL

    private var file: UnsafeMutablePointer<FILE>?

    func open() throws {
        guard let f = fopen(fileURL.path, "r") else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        file = f
    }

    func close() {
        if let f = file {
            file = nil
            let success = fclose(f) == 0
            assert(success)
        }
    }

    func readLine(maxLength: Int = 1024) throws -> String? {
        guard let f = file else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EBADF), userInfo: nil)
        }
        var buffer = [CChar](repeating: 0, count: maxLength)
        guard fgets(&buffer, Int32(maxLength), f) != nil else {
            if feof(f) != 0 {
                return nil
            } else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            }
        }
        return String(cString: buffer)
    }
}
