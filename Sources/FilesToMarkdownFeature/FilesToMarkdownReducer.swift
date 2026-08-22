#if os(macOS)
    import BlissTheme
    import CommandLineClient
    import Dependencies
    import FilePanelsClient
    import InputOutput
    import SharedModels
    import Sharing
    import SwiftUI

    @MainActor
    @Observable
    public final class FilesToMarkdownModel {
        @ObservationIgnored
        @Shared(.toolOutput("filesToMarkdown")) public var outputText = ""

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.selectedPath))
        public var selectedPath: String = ""

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.includeHidden))
        public var includeHidden: Bool = false

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.respectGitignore))
        public var respectGitignore: Bool = true

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.extensionFilter))
        public var extensionFilter: String = CombineOptions.defaultExtensions.joined(separator: ", ")

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.includeFileList))
        public var includeFileList: Bool = false

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.prefixText))
        public var prefixText: String = ""

        @ObservationIgnored
        @Shared(.appStorage(SettingsKey.FilesToMarkdown.suffixText))
        public var suffixText: String = ""

        public var isIncluding = false
        public var discoveredFiles: [DiscoveredFile] = []
        public var skippedBinaryCount = 0

        @ObservationIgnored
        @Dependency(\.filePanel) private var filePanel

        @ObservationIgnored
        @Dependency(\.commandLine) private var commandLine

        @ObservationIgnored
        private var combineTask: Task<Void, Never>?

        public init() {}

        public var includedExtensions: Set<String> {
            Set(
                extensionFilter
                    .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == " " || $0 == "\t" })
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ". \t")) }
                    .filter { !$0.isEmpty }
                    .map { $0.lowercased() }
            )
        }

        public func makeCombineOptions() -> CombineOptions {
            CombineOptions(
                folderPath: selectedPath,
                includeHidden: includeHidden,
                respectGitignore: respectGitignore,
                includedExtensions: includedExtensions,
                includeFileList: includeFileList,
                prefix: prefixText,
                suffix: suffixText
            )
        }

        public func chooseButtonTapped() {
            guard let url = filePanel.openPanel() else { return }
            $selectedPath.withLock { $0 = url.path }
            combineButtonTouched()
        }

        public func combineButtonTouched() {
            combineTask?.cancel()
            let options = makeCombineOptions()

            guard !options.folderPath.isEmpty else {
                $outputText.withLock { $0 = "Choose a file or folder first." }
                return
            }

            isIncluding = true
            discoveredFiles = []
            skippedBinaryCount = 0

            combineTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let baseURL = URL(fileURLWithPath: options.folderPath)
                    var files = try await FileDiscovery.discover(at: baseURL, options: options)

                    if options.respectGitignore {
                        files = try await FileDiscovery.filteringGitIgnored(
                            baseURL: baseURL,
                            candidates: files,
                            commandLine: self.commandLine
                        )
                    }

                    self.discoveredFiles = files

                    var contents: [String: String] = [:]
                    var skipped = 0
                    for (index, file) in files.enumerated() {
                        try Task.checkCancellation()
                        if let text = try await FileDiscovery.readText(at: file.url) {
                            contents[file.relativePath] = text
                        } else {
                            skipped += 1
                        }
                        if index % 50 == 0 { await Task.yield() }
                    }

                    try Task.checkCancellation()
                    let result = MarkdownAssembler.assemble(
                        files: files,
                        contentProvider: { contents[$0.relativePath] },
                        options: options
                    )

                    self.isIncluding = false
                    self.skippedBinaryCount = skipped
                    self.$outputText.withLock { $0 = result.markdown }
                } catch is CancellationError {
                    self.isIncluding = false
                } catch {
                    self.isIncluding = false
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }

        public func cancel() {
            combineTask?.cancel()
            combineTask = nil
            isIncluding = false
        }
    }

    enum FileDiscovery {
        static let maxFileSizeBytes: Int64 = 50_000_000

        static func discover(at url: URL, options: CombineOptions) async throws -> [DiscoveredFile] {
            let fileManager = FileManager.default
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                throw FileNotFoundError(path: url.path)
            }

            guard isDirectory.boolValue else {
                return [DiscoveredFile(url: url, relativePath: url.lastPathComponent)]
            }

            var enumerationOptions: FileManager.DirectoryEnumerationOptions = []
            if !options.includeHidden { enumerationOptions.insert(.skipsHiddenFiles) }

            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: enumerationOptions
            ) else {
                throw FileNotFoundError(path: url.path)
            }

            var files: [DiscoveredFile] = []
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard resourceValues.isRegularFile == true else { continue }
                if !options.includedExtensions.isEmpty {
                    let ext = fileURL.pathExtension.lowercased()
                    guard options.includedExtensions.contains(ext) else { continue }
                }
                files.append(DiscoveredFile(url: fileURL, relativePath: relativePath(of: fileURL, in: url)))
            }

            return files.sorted { $0.relativePath < $1.relativePath }
        }

        static func filteringGitIgnored(
            baseURL: URL,
            candidates: [DiscoveredFile],
            commandLine: CommandLineClient
        ) async throws -> [DiscoveredFile] {
            guard candidates.count > 1 else { return candidates }

            let folder = shellQuoted(baseURL.path)

            let insideRepo = try await commandLine.run("git -C \(folder) rev-parse --is-inside-work-tree")
            guard insideRepo.text.trimmingCharacters(in: .whitespacesAndNewlines) == "true" else {
                return candidates
            }

            let listing = try await commandLine.run("git -C \(folder) ls-files --cached --others --exclude-standard")
            let visiblePaths = Set(listing.text.split(separator: "\n").map(String.init))

            return candidates.filter { visiblePaths.contains($0.relativePath) }
        }

        static func readText(at url: URL) throws -> String? {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            guard Int64(size) <= maxFileSizeBytes else { return nil }
            let data = try Data(contentsOf: url)
            return String(data: data, encoding: .utf8)
        }

        static func relativePath(of fileURL: URL, in baseURL: URL) -> String {
            let filePath = fileURL.standardizedFileURL.path
            let basePath = baseURL.standardizedFileURL.path
            guard filePath.hasPrefix(basePath + "/") else {
                return fileURL.lastPathComponent
            }
            return String(filePath.dropFirst(basePath.count + 1))
        }

        static func shellQuoted(_ path: String) -> String {
            "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }
    }

    struct FileNotFoundError: LocalizedError {
        let path: String
        var errorDescription: String? { "No file or folder found at \(path)" }
    }

    public struct FilesToMarkdownModelView: View {
        @Bindable var model: FilesToMarkdownModel
        private let onSendOutputToTool: ((String, Tool) -> Void)?

        public init(
            model: FilesToMarkdownModel,
            onSendOutputToTool: ((String, Tool) -> Void)? = nil
        ) {
            self.model = model
            self.onSendOutputToTool = onSendOutputToTool
        }

        public var body: some View {
            TwoPaneToolView(
                actionTitle: "Combine",
                actionHelp: "Combine files into Markdown (Cmd+Return)",
                isLoading: model.isIncluding,
                performAction: model.combineButtonTouched,
                splitSettings: .init(
                    fractionKey: SettingsKey.FilesToMarkdown.splitViewFraction,
                    layoutKey: SettingsKey.FilesToMarkdown.splitViewLayout,
                    primaryLabel: "Included Files",
                    secondaryLabel: "Markdown"
                )
            ) {
                configurationView
            } primary: {
                fileListPane
            } secondary: {
                PlainOutputTextPane(
                    title: "Markdown",
                    text: outputTextBinding,
                    minHeight: 140,
                    onSendToTool: sendOutputToTool
                )
            }
        }

        private var configurationView: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text("Folder")
                    Button {
                        model.chooseButtonTapped()
                    } label: {
                        Image(systemName: "folder.fill")
                    }
                    .keyboardShortcut(.init("o"), modifiers: [.command])
                    .help("Choose file or folder (Cmd+O)")

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(model.selectedPath.isEmpty ? "No file or folder selected" : model.selectedPath)
                        .foregroundStyle(model.selectedPath.isEmpty ? .secondary : .primary)
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

                HStack(spacing: 16) {
                    Toggle("Include hidden files", isOn: binding(\.$includeHidden))
                        .toggleStyle(.checkbox)
                    Toggle("Respect .gitignore", isOn: binding(\.$respectGitignore))
                        .toggleStyle(.checkbox)
                    Toggle("Include file list", isOn: binding(\.$includeFileList))
                        .toggleStyle(.checkbox)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Extensions")
                            .font(.subheadline)
                        TextField(
                            "e.g. swift, md, json",
                            text: binding(\.$extensionFilter)
                        )
                    }
                    VStack(alignment: .leading) {
                        Text("Prefix")
                            .font(.subheadline)
                        TextField(
                            "Before everything ({folderName}, {fileCount}, {date})",
                            text: binding(\.$prefixText)
                        )
                    }
                    VStack(alignment: .leading) {
                        Text("Suffix")
                            .font(.subheadline)
                        TextField(
                            "After everything",
                            text: binding(\.$suffixText)
                        )
                    }
                }
                .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 8)
        }

        private var fileListPane: some View {
            TextPane(title: "Included Files (\(model.discoveredFiles.count))") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(model.discoveredFiles) { file in
                            Text(file.relativePath)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if model.skippedBinaryCount > 0 {
                            Text("\(model.skippedBinaryCount) non-text files skipped")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } trailingActions: {
                CopyToClipboardButton {
                    model.discoveredFiles.map(\.relativePath).joined(separator: "\n")
                }
            }
        }

        private var sendOutputToTool: ((Tool) -> Void)? {
            guard let onSendOutputToTool else { return nil }
            return { tool in
                onSendOutputToTool(model.outputText, tool)
            }
        }

        private var outputTextBinding: Binding<String> {
            Binding(
                get: { model.outputText },
                set: { newValue in model.$outputText.withLock { $0 = newValue } }
            )
        }

        private func binding<T>(_ keyPath: KeyPath<FilesToMarkdownModel, Shared<T>>) -> Binding<T> {
            Binding(
                get: { model[keyPath: keyPath].wrappedValue },
                set: { newValue in model[keyPath: keyPath].withLock { $0 = newValue } }
            )
        }
    }

    @MainActor
    public struct FilesToMarkdownFeaturePreviews: PreviewProvider {
        public static var previews: some View {
            FilesToMarkdownModelView(model: FilesToMarkdownModel())
        }
    }
#else
    import SharedModels
    import SwiftUI

    @MainActor
    @Observable
    public final class FilesToMarkdownModel {
        public init() {}
    }

    public struct FilesToMarkdownModelView: View {
        public init(model: FilesToMarkdownModel, onSendOutputToTool: ((String, Tool) -> Void)? = nil) {}
        public var body: some View { Text("Files to Markdown is only available on macOS") }
    }
#endif
