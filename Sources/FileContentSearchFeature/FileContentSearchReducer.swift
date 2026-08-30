#if os(macOS)
import BlissTheme
import Dependencies
import FilePanelsClient
import FilesClient
import Foundation
import Ripgrep
import SplitView
import SwiftUI

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
    public let id = UUID()

    public init(fileURL: URL, lineNumbers: [Int], modifiedTime: Date) {
        self.fileURL = fileURL
        self.lineNumbers = lineNumbers
        self.modifiedTime = modifiedTime
    }

    public var lines: String {
        lineNumbers.map(String.init).joined(separator: ", ")
    }

    public var modifiedTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: modifiedTime)
    }
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
                        modifiedTime: Date(timeIntervalSince1970: 12300)
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

    var rgOptions = RipgrepOptions()
    rgOptions.includeHidden = options.searchHiddenFiles

    // A line containing several matches yields one match per match; group them into line numbers per file.
    var lineNumbersByFile: [URL: [Int]] = [:]
    do {
        for try await match in Ripgrep.search(options.term, in: folderUrl, options: rgOptions) {
            guard isIncluded(match.fileURL, root: folderUrl, options: options) else { continue }
            let lineNumber = Int(match.lineNumber)
            if lineNumbersByFile[match.fileURL]?.last != lineNumber {
                lineNumbersByFile[match.fileURL, default: []].append(lineNumber)
            }
        }
    } catch let error as RipgrepError {
        throw error.asNSError
    }

    return try lineNumbersByFile
        .sorted { $0.key.path < $1.key.path }
        .map { fileURL, lineNumbers in
            FoundFile(
                fileURL: fileURL,
                lineNumbers: lineNumbers,
                modifiedTime: try getModificationTime(for: fileURL)
            )
        }
}

/// Ripgrep always traverses recursively and has no concept of macOS packages,
/// so `searchInsideSubdirectories` and `searchInsidePackages` are enforced by
/// filtering the matches after the search.
private func isIncluded(_ fileURL: URL, root: URL, options: SearchOptions) -> Bool {
    if !options.searchInsideSubdirectories, fileURL.deletingLastPathComponent().path != root.path {
        return false
    }
    guard !options.searchInsidePackages else { return true }

    var directory = fileURL.deletingLastPathComponent()
    while directory.path.hasPrefix(root.path), directory.path != root.path {
        if (try? directory.resourceValues(forKeys: [.isPackageKey]))?.isPackage == true {
            return false
        }
        let parent = directory.deletingLastPathComponent()
        if parent.path == directory.path { break }
        directory = parent
    }
    return true
}

private func getModificationTime(for url: URL) throws -> Date {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard let date = attributes[.modificationDate] as? Date else {
        throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get modification time"])
    }
    return date
}

extension RipgrepError {
    /// The model displays `error.localizedDescription`, which is unhelpful for
    /// plain `Error` values.
    var asNSError: NSError {
        let message: String
        switch self {
        case .invalidPattern(let description):
            message = String(format: NSLocalizedString("Invalid search pattern: %@", bundle: Bundle.module, comment: ""), description)
        case .invalidArgument(let description):
            message = String(format: NSLocalizedString("Invalid search folder: %@", bundle: Bundle.module, comment: ""), description)
        case .io(let description):
            message = description
        case .internalError(let description):
            message = description
        }
        return NSError(domain: "FileContentSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
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
