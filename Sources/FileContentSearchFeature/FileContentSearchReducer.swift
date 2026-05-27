#if os(macOS)
import BlissTheme
import CommandLineClient
import Dependencies
import FilePanelsClient
import FilesClient
import Foundation
import SplitView
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
public final class FileContentSearchModel {
    public var searchOptions: SearchOptions
    public var selectedFiles = Set<FoundFile.ID>()
    public var foundFiles: [FoundFile]
    public var outputText = ""
    public var isSearching = false
    public var isReadingFile = false

    @ObservationIgnored
    @Dependency(\.fileContentSearch) private var fileContentSearch

    @ObservationIgnored
    @Dependency(\.filesClient) private var filesClient

    @ObservationIgnored
    @Dependency(\.filePanel) private var filePanel

    @ObservationIgnored
    private var searchTask: Task<Void, Never>?

    @ObservationIgnored
    private var readTask: Task<Void, Never>?

    public init(
        searchOptions: SearchOptions = .init(),
        foundFiles: [FoundFile] = []
    ) {
        self.searchOptions = searchOptions
        self.foundFiles = foundFiles
    }

    public func setSearchTerm(_ text: String) {
        searchOptions.term = text
    }

    public func setSearchFolder(_ folder: String) {
        searchOptions.folder = folder
    }

    public func setSearchHiddenFiles(_ value: Bool) {
        searchOptions.searchHiddenFiles = value
    }

    public func setSearchInsidePackages(_ value: Bool) {
        searchOptions.searchInsidePackages = value
    }

    public func setSearchInsideSubdirectories(_ value: Bool) {
        searchOptions.searchInsideSubdirectories = value
    }

    public func searchButtonTapped() {
        searchTask?.cancel()
        isSearching = true
        let options = searchOptions

        searchTask = Task { [weak self, options = options, fileContentSearch = fileContentSearch] in
            do {
                let found = try await fileContentSearch.run(options)
                await MainActor.run {
                    guard let self else { return }
                    self.isSearching = false
                    self.foundFiles = found
                    self.selectedFiles = []
                    self.outputText = "\(found.count) files found."
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.isSearching = false
                    self.outputText = error.localizedDescription
                }
            }
        }
    }

    public func openFolderSelectionButtonTapped() {
        searchOptions.folder = filePanel.openPanel()?.path ?? searchOptions.folder
    }

    public func setSelectedFiles(_ selected: Set<FoundFile.ID>) {
        selectedFiles = selected
        selectedFilesChanged()
    }

    public func sortFoundFiles(_ comparators: [KeyPathComparator<FoundFile>]) {
        foundFiles.sort(using: comparators)
    }

    private func selectedFilesChanged() {
        guard selectedFiles.count == 1, let id = selectedFiles.first, let file = foundFiles.first(where: { $0.id == id }) else {
            isReadingFile = false
            readTask?.cancel()
            return
        }

        isReadingFile = true
        readTask?.cancel()
        readTask = Task { [weak self, file = file, filesClient = filesClient] in
            do {
                let content = try await filesClient.read(file.fileURL)
                await MainActor.run {
                    guard let self else { return }
                    self.isReadingFile = false
                    self.outputText = content
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.isReadingFile = false
                    self.outputText = error.localizedDescription
                }
            }
        }
    }
}

public struct FileContentSearchView: View {
    @Bindable var model: FileContentSearchModel
    @State private var sortOrder = [KeyPathComparator(\FoundFile.modifiedTime, order: .reverse)]

    public init(model: FileContentSearchModel) {
        self.model = model
    }

    public var body: some View {
        VSplitView {
            VStack(alignment: .center) {
                inputView

                Table(
                    model.foundFiles,
                    selection: Binding(
                        get: { model.selectedFiles },
                        set: { model.setSelectedFiles($0) }
                    ),
                    sortOrder: $sortOrder
                ) {
                    TableColumn(NSLocalizedString("File Path", bundle: Bundle.module, comment: ""), value: \.fileURL.absoluteString)
                        .width(min: nil, ideal: 400, max: nil)
                    TableColumn(NSLocalizedString("Lines", bundle: Bundle.module, comment: ""), value: \.lines)
                        .width(min: nil, ideal: 80, max: nil)
                    TableColumn(NSLocalizedString("Modified", bundle: Bundle.module, comment: ""), value: \.modifiedTimeString)
                        .width(min: nil, ideal: 100, max: nil)
                    TableColumn(NSLocalizedString("Git User", bundle: Bundle.module, comment: ""), value: \.gitUsernameCleaned)
                        .width(min: nil, ideal: 100, max: nil)
                }
                .onChange(of: sortOrder) { _, newValue in
                    model.sortFoundFiles(newValue)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("File Content", bundle: Bundle.module, comment: ""))
                    .font(.headline)
                    .padding(.horizontal, 8)

                TextEditor(text: $model.outputText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
            .overlay(model.isReadingFile ? ProgressView() : nil)
        }
    }

    var inputView: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text(NSLocalizedString("Search Term", bundle: Bundle.module, comment: ""))
                TextField(
                    NSLocalizedString("term to search inside the file...", bundle: Bundle.module, comment: ""),
                    text: Binding(get: { model.searchOptions.term }, set: { model.setSearchTerm($0) })
                )
            }

            HStack {
                HStack(alignment: .center) {
                    Text(NSLocalizedString("Directory", bundle: Bundle.module, comment: ""))
                    Button {
                        model.openFolderSelectionButtonTapped()
                    } label: {
                        Image(systemName: "folder.fill")
                    }
                    .keyboardShortcut(.init("o"), modifiers: [.command])
                    .help(NSLocalizedString("Choose directory (Cmd+O)", bundle: Bundle.module, comment: ""))
                }
                .onTapGesture {
                    model.openFolderSelectionButtonTapped()
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(model.searchOptions.folder)
                        .textSelection(.enabled)
                        .padding(4)
                        .frame(minWidth: 30)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(ThemeColor.Background.systemGray, lineWidth: 1)
                )
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())

            Toggle("Search also hidden files and folders", isOn: Binding(get: { model.searchOptions.searchHiddenFiles }, set: { model.setSearchHiddenFiles($0) }))
                .toggleStyle(.checkbox)
            Toggle("Search in sub-directories", isOn: Binding(get: { model.searchOptions.searchInsideSubdirectories }, set: { model.setSearchInsideSubdirectories($0) }))
                .toggleStyle(.checkbox)
            Toggle("Search in packaged files", isOn: Binding(get: { model.searchOptions.searchInsidePackages }, set: { model.setSearchInsidePackages($0) }))
                .toggleStyle(.checkbox)

            LoadingButton(
                NSLocalizedString("Search", bundle: Bundle.module, comment: ""),
                isLoading: model.isSearching
            ) {
                model.searchButtonTapped()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Start searching (Cmd+Return)", bundle: Bundle.module, comment: ""))
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 8)
    }
}

public struct SearchOptions: Equatable {
    public var term: String
    public var folder: String
    public var searchHiddenFiles: Bool
    public var searchInsidePackages: Bool
    public var searchInsideSubdirectories: Bool

    public init(
        searchTerm: String = .init(),
        searchFolder: String = .init(),
        searchHiddenFiles: Bool = false,
        searchInsidePackages: Bool = true,
        searchInsideSubdirectories: Bool = true
    ) {
        self.term = searchTerm
        self.folder = searchFolder
        self.searchHiddenFiles = searchHiddenFiles
        self.searchInsidePackages = searchInsidePackages
        self.searchInsideSubdirectories = searchInsideSubdirectories
    }
}

public struct FoundFile: Equatable, Identifiable {
    public let fileURL: URL
    public let lineNumbers: [Int]
    public let modifiedTime: Date
    public let gitUsername: String?
    public let id = UUID()

    public init(fileURL: URL, lineNumbers: [Int], modifiedTime: Date, gitUsername: String?) {
        self.fileURL = fileURL
        self.lineNumbers = lineNumbers
        self.modifiedTime = modifiedTime
        self.gitUsername = gitUsername
    }

    public var lines: String {
        lineNumbers.map(String.init).joined(separator: ", ")
    }

    public var modifiedTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: modifiedTime)
    }

    public var gitUsernameCleaned: String { gitUsername ?? "" }
}

@MainActor
public struct FileContentSearchModelPreview: PreviewProvider {
    public static var previews: some View {
        FileContentSearchView(
            model: FileContentSearchModel(
                searchOptions: .init(searchTerm: "example", searchFolder: "/Users/example/projects"),
                foundFiles: [
                    FoundFile(
                        fileURL: URL(string: "Users/example/projects/file.swift")!,
                        lineNumbers: [23, 34, 43],
                        modifiedTime: Date(timeIntervalSince1970: 12300),
                        gitUsername: "developer"
                    )
                ]
            )
        )
    }
}

public struct FileContentSearchClient {
    public var run: @Sendable (SearchOptions) async throws -> [FoundFile]

    public init(run: @escaping @Sendable (SearchOptions) async throws -> [FoundFile]) {
        self.run = run
    }

    public static let liveValue = Self(run: grepFolder(options:))
}

extension FileContentSearchClient: DependencyKey {}

extension DependencyValues {
    public var fileContentSearch: FileContentSearchClient {
        get { self[FileContentSearchClient.self] }
        set { self[FileContentSearchClient.self] = newValue }
    }
}

@Sendable
private func grepFolder(options: SearchOptions) async throws -> [FoundFile] {
    let folderUrl = URL(fileURLWithPath: options.folder)
    var fmOptions: FileManager.DirectoryEnumerationOptions = []
    if !options.searchHiddenFiles { fmOptions.insert(.skipsHiddenFiles) }
    if !options.searchInsidePackages { fmOptions.insert(.skipsPackageDescendants) }
    if !options.searchInsideSubdirectories { fmOptions.insert(.skipsSubdirectoryDescendants) }

    let files = walkDirectory(
        at: folderUrl,
        options: fmOptions
    ) { url in
        guard let typeIdentifier = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
              let isHidden = try? url.resourceValues(forKeys: [.isHiddenKey]).isHidden,
              (isHidden == options.searchHiddenFiles) || options.searchHiddenFiles else {
            return false
        }
        return typeIdentifier.conforms(to: UTType.text)
    }

    let found = try await withThrowingTaskGroup(of: FoundFile?.self, returning: [FoundFile].self) { group in
        var i = 0
        for await file in files {
            group.addTask {
                try await grepFile(options: options, fileUrl: file)
            }
            i += 1
            if i % 100 == 0 { await Task.yield() }
        }
        return try await group.reduce(into: []) { result, file in
            if let file { result.append(file) }
        }
    }
    return found
}

@Sendable
private func grepFile(options: SearchOptions, fileUrl: URL) async throws -> FoundFile? {
    var lineNumbers: [Int] = []
    var lineNumber = 1

    let qfle = QFile(fileURL: fileUrl)
    defer { qfle.close() }
    try qfle.open()
    while let line = try qfle.readLine() {
        if line.contains(options.term) { lineNumbers.append(lineNumber) }
        lineNumber += 1
    }

    guard !lineNumbers.isEmpty else { return nil }
    let modificationTime = try getModificationTime(for: fileUrl)
    return try await FoundFile(fileURL: fileUrl, lineNumbers: lineNumbers, modifiedTime: modificationTime, gitUsername: getLastCommitAuthor(for: fileUrl))
}

private func getModificationTime(for url: URL) throws -> Date {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard let date = attributes[.modificationDate] as? Date else {
        throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get modification time"])
    }
    return date
}

private func getLastCommitAuthor(for fileURL: URL) async throws -> String? {
    @Dependency(\.commandLine) var commandLine
    let command = "cd \\(fileURL.deletingLastPathComponent().path) && git log -1 --pretty=format:%an -- \\(fileURL.lastPathComponent)"
    let output = try await commandLine.run(command)
    return output.text.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func walkDirectory(
    at url: URL,
    options fmOptions: FileManager.DirectoryEnumerationOptions,
    fileCondition: @escaping (URL) -> Bool
) -> AsyncStream<URL> {
    AsyncStream { continuation in
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: fmOptions) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                    if fileAttributes.isRegularFile!, fileCondition(fileURL) {
                        continuation.yield(fileURL)
                    }
                } catch {
                    print(error, fileURL)
                }
            }
            continuation.finish()
        } else {
            continuation.finish()
        }
    }
}

private class QFile {
    init(fileURL: URL) { self.fileURL = fileURL }
    deinit {
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
            _ = fclose(f) == 0
        }
    }

    func readLine(maxLength: Int = 1024) throws -> String? {
        guard let f = file else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(EBADF), userInfo: nil) }
        var buffer = [CChar](repeating: 0, count: maxLength)
        guard fgets(&buffer, Int32(maxLength), f) != nil else {
            if feof(f) != 0 { return nil }
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        return String(cString: buffer)
    }
}
#else
import Observation
import SwiftUI

@MainActor
@Observable
public final class FileContentSearchModel {
    public var outputText: String? { nil }
    public init() {}
}

public struct FileContentSearchView: View {
    public init(model: FileContentSearchModel) {}
    public var body: some View { Text("File search is only available on macOS") }
}
#endif
