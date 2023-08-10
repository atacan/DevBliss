#if os(macOS)
    import ComposableArchitecture
    import FileContentSearchClient
    import FilePanelsClient
    import InputOutput
    import SplitView
    import SwiftUI
    import TCAEnchance

    public struct FileContentSearchReducer: ReducerProtocol {
        public init() {}
        public struct State: Equatable {
            @BindingState var searchOptions: SearchOptions
            @BindingState var selectedFiles = Set<FoundFile.ID>()
            var foundFiles: IdentifiedArrayOf<FoundFile> = []
            var output: OutputEditorReducer.State
            var isSearching: Bool = false

            public init(
                searchOptions: SearchOptions = .init(),
                output: OutputEditorReducer.State = .init()
            ) {
                self.searchOptions = searchOptions
                self.output = output
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
            case output(OutputEditorReducer.Action)
            case tableSortOrderChanged([KeyPathComparator<FoundFile>])
        }

        @Dependency(\.fileContentSearch) var fileContentSearch
        #if os(macOS)
            @Dependency(\.filePanel) var filePanel
        #endif

        private enum CancelID { case generationRequest }

        public var body: some ReducerProtocol<State, Action> {
            BindingReducer()
            Reduce<State, Action> { state, action in
                switch action {
                case let .binding(action) where action.keyPath == \.$selectedFiles:
                    selectedFilesChanged(&state)
                    return .none
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
                    state.output.updateText("\(foundFiles.count) files found.")
                    return .none
                case let .searchResponse(.failure(error)):
                    state.isSearching = false
                    print(error)
                    state.output.updateText(error.localizedDescription)
                    return .none
                case let .tableSortOrderChanged(comparator):
                    state.foundFiles.sort(using: comparator)
                    return .none
                case .output:
                    return .none
                }
            }
            .onChange(of: \.selectedFiles) { selected, state, _ in
                selectedFilesChanged(&state)
                return .none
            }

            Scope(state: \.output, action: /Action.output) {
                OutputEditorReducer()
            }
        }

        private func selectedFilesChanged(_ state: inout State) {
            guard state.selectedFiles.count == 1,
                  let file = state.foundFiles[id: state.selectedFiles.first!]
            else {
                return
            }
            do {
                // TODO: read the file asynchronously with a client. the content will be a response action handled by the reducer
                let content = try String(contentsOf: file.fileURL)
                _ = state.output.updateText(content)
            } catch {
                _ = state.output.updateText("\(error)")
            }
        }
    }

    public struct FileContentSearchView: View {
        let store: Store<FileContentSearchReducer.State, FileContentSearchReducer.Action>
        @ObservedObject var viewStore: ViewStore<FileContentSearchReducer.State, FileContentSearchReducer.Action>

        public init(store: StoreOf<FileContentSearchReducer>) {
            self.store = store
            self.viewStore = ViewStore(store)
        }

        @State private var sortOrder = [
            KeyPathComparator(\FoundFile.fileURL.absoluteString),
            KeyPathComparator(\FoundFile.lines),
        ]

        public var body: some View {
            VSplitView {
                VStack(alignment: .center) {
                    inputView

                    Table(viewStore.foundFiles, selection: viewStore.binding(\.$selectedFiles), sortOrder: $sortOrder) {
                        TableColumn(
                            NSLocalizedString("File Path", bundle: Bundle.module, comment: ""),
                            value: \.fileURL.absoluteString
                        )
                        .width(min: nil, ideal: 450, max: nil)
                        TableColumn(NSLocalizedString("Lines", bundle: Bundle.module, comment: ""), value: \.lines)
                        TableColumn(
                            NSLocalizedString("Modified", bundle: Bundle.module, comment: ""),
                            value: \.modifiedTimeString
                        )
                        TableColumn(
                            NSLocalizedString("Git User", bundle: Bundle.module, comment: ""),
                            value: \.gitUsernameCleaned
                        )
                    }
                    .onChange(of: sortOrder) { newValue in
                        viewStore.send(.tableSortOrderChanged(newValue))
                    }
                } // <-VStack
                OutputEditorView(
                    store: store.scope(
                        state: \.output,
                        action: FileContentSearchReducer.Action.output
                    ),
                    title: NSLocalizedString("File Content", bundle: Bundle.module, comment: "")
                )
            }
        }

        var inputView: some View {
            VStack(alignment: .center) {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text(NSLocalizedString("Search Term", bundle: Bundle.module, comment: ""))
                        TextField(
                            NSLocalizedString("term to search inside the file...", bundle: Bundle.module, comment: ""),
                            text: viewStore.binding(\.$searchOptions.term)
                        )
                    } // <-HStack

                    HStack {
                        HStack(alignment: .center) {
                            Text(NSLocalizedString("Directory", bundle: Bundle.module, comment: ""))

                            Button {
                                viewStore.send(.directorySelectionButtonTouched)
                            } label: {
                                Image(systemName: "folder.fill")
                            }
                        } // <-HStack
                        .onTapGesture {
                            viewStore.send(.directorySelectionButtonTouched)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(viewStore.searchOptions.folder)
                                .textSelection(.enabled)
                                .padding(4)
                                .frame(minWidth: 30)
                        } // <-ScrollView
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(nsColor: .systemGray), lineWidth: 1)
                        )
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Toggle(
                        NSLocalizedString("Search also hidden files and folders", bundle: Bundle.module, comment: ""),
                        isOn: viewStore.binding(\.$searchOptions.searchHiddenFiles)
                    )
                    .toggleStyle(.checkbox)
                }
                .frame(maxWidth: 450)

                // Toggle(
                //     "Case Sensitive",
                //     isOn: viewStore.binding(\.$searchOptions.caseSensitive)
                // )
                // .toggleStyle(.checkbox)

                // TextField(
                //     "File Extensions",
                //     text: viewStore.binding(\.$searchOptions.fileExtensions)
                // )
                // .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    viewStore.send(.searchButtonTouched)
                } label: {
                    Text(NSLocalizedString("Search", bundle: Bundle.module, comment: ""))
                } // <-Button
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Start searching (Cmd+Return)", bundle: Bundle.module, comment: ""))
                .overlay(viewStore.isSearching ? ProgressView() : nil)
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
                        output: .init()
                    ),
                    reducer: FileContentSearchReducer()
                )
            )
        }
    }
#else
    import ComposableArchitecture

    public struct FileContentSearchReducer: ReducerProtocol {
        public init() {}
        public struct State: Equatable { public init() {} }
        public enum Action: Equatable {}
        public var body: some ReducerProtocol<State, Action> {
            EmptyReducer()
        }
    }
#endif

#if DEBUG
    public struct FileContentSearchApp: App {
        public init() {}

        public var body: some Scene {
            WindowGroup {
                FileContentSearchView(
                    store: Store(
                        initialState: .init(searchOptions: SearchOptions(searchTerm: "import")),
                        reducer: FileContentSearchReducer()
                    )
                )
            }
            #if os(macOS)
            .windowStyle(.titleBar)
            .windowToolbarStyle(.unified(showsTitle: true))
            #endif
        }
    }

#endif
