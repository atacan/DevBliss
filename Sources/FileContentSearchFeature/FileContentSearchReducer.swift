#if os(macOS)
    import ComposableArchitecture
    import FileContentSearchClient
    import FilePanelsClient
    import FilesClient
    import InputOutput
    import SplitView
    import SwiftUI
    import TCAEnchance

    @Reducer
    public struct FileContentSearchReducer {
        public init() {}
    @ObservableState
        public struct State: Equatable {
            var searchOptions: SearchOptions
            var selectedFiles = Set<FoundFile.ID>()
            var foundFiles: IdentifiedArrayOf<FoundFile>
            var output: OutputEditorReducer.State
            var isSearching: Bool = false
            var isReadingFile: Bool = false

            public init(
                searchOptions: SearchOptions = .init(),
                output: OutputEditorReducer.State = .init(),
                foundFiles: IdentifiedArrayOf<FoundFile> = []
            ) {
                self.searchOptions = searchOptions
                self.output = output
                self.foundFiles = foundFiles
            }

            public var outputText: String {
                output.text
            }
        }

        public enum Action: BindableAction, Equatable {
            case binding(BindingAction<State>)
            case searchButtonTouched
            case directorySelectionButtonTouched
            case searchResponse(TaskResult<[FoundFile]>)
            case selectedFileContentRead(TaskResult<String>)
            case output(OutputEditorReducer.Action)
            case tableSortOrderChanged([KeyPathComparator<FoundFile>])
        }

        @Dependency(\.fileContentSearch) var fileContentSearch
        @Dependency(\.filesClient) var filesClient
        #if os(macOS)
            @Dependency(\.filePanel) var filePanel
        #endif

        private enum CancelID {
            case generationRequest
            case readFileRequest
        }

        //        private enum ReadFileCancelID { case readFileRequest }

        public var body: some Reducer<State, Action> {
            BindingReducer()
            Reduce<State, Action> { state, action in
                switch action {
                case .binding:
                    return .none
                case .directorySelectionButtonTouched:
                    let url = filePanel.openPanel()
                    state.searchOptions.folder = url?.path ?? ""
                    return .none
                case .searchButtonTouched:
                    state.isSearching = true
                    return
                        .run {
                            [options = state.searchOptions] send in
                            await send(
                                .searchResponse(
                                    TaskResult {
                                        try await fileContentSearch.run(options)
                                    }
                                )
                            )
                        }
                        .cancellable(id: CancelID.generationRequest, cancelInFlight: true)
                case let .searchResponse(.success(foundFiles)):
                    state.isSearching = false
                    state.foundFiles = .init(uniqueElements: foundFiles)
                    state.selectedFiles = []
                    return state.output.updateText("\(foundFiles.count) files found.")
                        .map { Action.output($0) }
                case let .searchResponse(.failure(error)):
                    state.isSearching = false
                    return state.output.updateText(error.localizedDescription)
                        .map { Action.output($0) }
                case let .selectedFileContentRead(.success(content)):
                    state.isReadingFile = false
                    return state.output.updateText(content)
                        .map { Action.output($0) }
                case let .selectedFileContentRead(.failure(error)):
                    state.isReadingFile = false
                    return state.output.updateText(error.localizedDescription)
                        .map { Action.output($0) }
                case let .tableSortOrderChanged(comparator):
                    state.foundFiles.sort(using: comparator)
                    return .none
                case .output:
                    return .none
                }
            }
            .onChange(of: \.selectedFiles) { selected, state, _ in
                selectedFilesChanged(&state)
            }

            Scope(state: \.output, action: \.output) {
                OutputEditorReducer()
            }
        }

        private func selectedFilesChanged(_ state: inout State) -> Effect<Action> {
            guard state.selectedFiles.count == 1,
                let file = state.foundFiles[id: state.selectedFiles.first!]
            else {
                state.isReadingFile = false
                return .cancel(id: CancelID.readFileRequest)
            }
            state.isReadingFile = true
            return
                .run {
                    send in
                    await send(
                        .selectedFileContentRead(
                            TaskResult {
                                try await filesClient.read(file.fileURL)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.readFileRequest, cancelInFlight: true)
        }
    }

    public struct FileContentSearchView: View {
        @Bindable var store: Store<FileContentSearchReducer.State, FileContentSearchReducer.Action>

        public init(store: StoreOf<FileContentSearchReducer>) {
            self.store = store
        }

        @State private var sortOrder = [
            KeyPathComparator(\FoundFile.modifiedTime, order: .reverse)
        ]

        public var body: some View {
            VSplitView {
                VStack(alignment: .center) {
                    inputView

                    Table(store.foundFiles, selection: $store.selectedFiles, sortOrder: $sortOrder) {
                        TableColumn(
                            NSLocalizedString("File Path", bundle: Bundle.module, comment: ""),
                            value: \.fileURL.absoluteString
                        )
                        .width(min: nil, ideal: 400, max: nil)
                        TableColumn(NSLocalizedString("Lines", bundle: Bundle.module, comment: ""), value: \.lines)
                            .width(min: nil, ideal: 80, max: nil)
                        TableColumn(
                            NSLocalizedString("Modified", bundle: Bundle.module, comment: ""),
                            value: \.modifiedTimeString
                        )
                        .width(min: nil, ideal: 100, max: nil)
                        TableColumn(
                            NSLocalizedString("Git User", bundle: Bundle.module, comment: ""),
                            value: \.gitUsernameCleaned
                        )
                        .width(min: nil, ideal: 100, max: nil)
                    }
                    .onChange(of: sortOrder) { newValue in
                        store.send(.tableSortOrderChanged(newValue))
                    }
                }  // <-VStack
                OutputEditorView(
                    store: store.scope(
                        state: \.output,
                        action: FileContentSearchReducer.Action.output
                    ),
                    title: NSLocalizedString("File Content", bundle: Bundle.module, comment: "")
                )
                .overlay(store.isReadingFile ? ProgressView() : nil)
            }
        }

        var inputView: some View {
            VStack(alignment: .center) {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text(NSLocalizedString("Search Term", bundle: Bundle.module, comment: ""))

                        TextField(
                            NSLocalizedString("term to search inside the file...", bundle: Bundle.module, comment: ""),
                            text: $store.searchOptions.term
                        )
                        .onSubmit {
                            store.send(.directorySelectionButtonTouched)
                        }
                    }  // <-HStack

                    HStack {
                        HStack(alignment: .center) {
                            Text(NSLocalizedString("Directory", bundle: Bundle.module, comment: ""))

                            Button {
                                store.send(.directorySelectionButtonTouched)
                            } label: {
                                Image(systemName: "folder.fill")
                            }
                            .keyboardShortcut(.init("o"), modifiers: [.command])
                            .help(NSLocalizedString("Choose directory (Cmd+O)", bundle: Bundle.module, comment: ""))
                        }  // <-HStack
                        .onTapGesture {
                            store.send(.directorySelectionButtonTouched)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(store.searchOptions.folder)
                                .textSelection(.enabled)
                                .padding(4)
                                .frame(minWidth: 30)
                        }  // <-ScrollView
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(nsColor: .systemGray), lineWidth: 1)
                        )
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Toggle(
                        NSLocalizedString("Search also hidden files and folders", bundle: Bundle.module, comment: ""),
                        isOn: $store.searchOptions.searchHiddenFiles
                    )
                    .toggleStyle(.checkbox)

                    Toggle(
                        NSLocalizedString("Search in sub-directories", bundle: Bundle.module, comment: ""),
                        isOn: $store.searchOptions.searchInsideSubdirectories
                    )
                    .toggleStyle(.checkbox)

                    Toggle(
                        NSLocalizedString("Search in packaged files", bundle: Bundle.module, comment: ""),
                        isOn: $store.searchOptions.searchInsidePackages
                    )
                    .toggleStyle(.checkbox)
                }
                .frame(maxWidth: 450)

                // Toggle(
                //     "Case Sensitive",
                //     isOn: store.binding(\.$searchOptions.caseSensitive)
                // )
                // .toggleStyle(.checkbox)

                // TextField(
                //     "File Extensions",
                //     text: store.binding(\.$searchOptions.fileExtensions)
                // )
                // .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    store.send(.searchButtonTouched)
                } label: {
                    Text(NSLocalizedString("Search", bundle: Bundle.module, comment: ""))
                }  // <-Button
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Start searching (Cmd+Return)", bundle: Bundle.module, comment: ""))
                .overlay(store.isSearching ? ProgressView() : nil)
                .padding(.bottom, 2)
            }
        }
    }

    struct SwiftUIView_Previews: PreviewProvider {
        static var previews: some View {
            FileContentSearchView(
                store: Store(
                    initialState: .init(
                        searchOptions: .init(
                            searchTerm: "atacan",
                            searchFolder: "/Users/atacan/Documents/myway/Repositories/scripts/backup",
                            searchHiddenFiles: false
                        ),
                        output: .init(text: "Something inside\nthis file is very important", outputControls: .init()),
                        foundFiles: IdentifiedArrayOf(
                            uniqueElements: [
                                FoundFile(
                                    fileURL: URL(string: "Users/atacan/amazement/secret.swift")!,
                                    lineNumbers: [23, 34, 43],
                                    modifiedTime: Date(timeIntervalSince1970: 12300),
                                    gitUsername: "atacan"
                                )
                            ]
                        )
                    )
                ) {
                    FileContentSearchReducer()
                }
            )
        }
    }

    #if DEBUG
        public struct FileContentSearchApp: App {
            public init() {}

            public var body: some Scene {
                WindowGroup {
                    FileContentSearchView(
                        store: Store(
                            initialState: .init(searchOptions: SearchOptions(searchTerm: "import"))
                        ) {
                            FileContentSearchReducer()
                                ._printChanges()
                        }
                    )
                }
                #if os(macOS)
                    .windowStyle(.titleBar)
                    .windowToolbarStyle(.unified(showsTitle: true))
                #endif
            }
        }

    #endif

#else
    import ComposableArchitecture

    public struct FileContentSearchReducer: Reducer {
        public init() {}
    @ObservableState
        public struct State: Equatable { public init() {} }
        public enum Action: Equatable {}
        public var body: some Reducer<State, Action> {
            EmptyReducer()
        }
    }

#endif
