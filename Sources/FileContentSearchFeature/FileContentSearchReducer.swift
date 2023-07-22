import ComposableArchitecture
import FileContentSearchClient
import FilePanelsClient
import InputOutput
import SwiftUI

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
                state.searchOptions.folder = url.path
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
                return .none
            case .searchResponse(.failure):
                state.isSearching = false
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
            let content = try String(contentsOfFile: file.fileURL)
            _ = state.output.updateText(content)
        }
        catch {
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

    @State private var sortOrder = [KeyPathComparator(\FoundFile.fileURL)]

    public var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text("Search Term")
                TextField("term to search inside the file...", text: viewStore.binding(\.$searchOptions.term))
                } // <-HStack

                HStack {
                    Text("Directory")
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(viewStore.searchOptions.folder)
                            .textSelection(.enabled)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.gray, lineWidth: 2)
                            )
                    }  // <-ScrollView
                    
                    Button {
                        viewStore.send(.directorySelectionButtonTouched)
                    } label: {
                        Image(systemName: "folder.fill.badge.questionmark")
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("Hidden Files and Folders", isOn: viewStore.binding(\.$searchOptions.searchHiddenFiles))
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
                Text("Search")
            }  // <-Button
            .keyboardShortcut(.return, modifiers: [.command])
            .overlay(viewStore.isSearching ? ProgressView() : nil)

            Table(viewStore.foundFiles, selection: viewStore.binding(\.$selectedFiles), sortOrder: $sortOrder) {
                TableColumn("File Path", value: \.fileURL)
                    .width(min: nil, ideal: 450, max: nil)
                TableColumn("Lines", value: \.lines)
                TableColumn("Modified", value: \.modifiedTimeString)
                TableColumn("Git User", value: \.gitUsernameCleaned)
            }

            OutputEditorView(
                store: store.scope(
                    state: \.output,
                    action: FileContentSearchReducer.Action.output
                )
            )

        }  // <-VStack
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

extension ReducerProtocol {
    @inlinable
    public func onChange<ChildState: Equatable>(
        of toLocalState: @escaping (State) -> ChildState,
        perform additionalEffects: @escaping (ChildState, inout State, Action) -> EffectTask<Action>
    ) -> some ReducerProtocol<State, Action> {
        onChange(of: toLocalState) { additionalEffects($1, &$2, $3) }
    }

    @inlinable
    public func onChange<ChildState: Equatable>(
        of toLocalState: @escaping (State) -> ChildState,
        perform additionalEffects: @escaping (ChildState, ChildState, inout State, Action) -> EffectTask<Action>
    ) -> some ReducerProtocol<State, Action> {
        ChangeReducer(base: self, toLocalState: toLocalState, perform: additionalEffects)
    }
}

@usableFromInline
struct ChangeReducer<Base: ReducerProtocol, ChildState: Equatable>: ReducerProtocol {
    @usableFromInline
    let base: Base

    @usableFromInline
    let toLocalState: (Base.State) -> ChildState

    @usableFromInline
    let perform: (ChildState, ChildState, inout Base.State, Base.Action) -> EffectTask<Base.Action>

    @usableFromInline
    init(
        base: Base,
        toLocalState: @escaping (Base.State) -> ChildState,
        perform: @escaping (ChildState, ChildState, inout Base.State, Base.Action) -> EffectTask<Base.Action>
    ) {
        self.base = base
        self.toLocalState = toLocalState
        self.perform = perform
    }

    @inlinable
    public func reduce(into state: inout Base.State, action: Base.Action) -> EffectTask<Base.Action> {
        let previousLocalState = toLocalState(state)
        let effects = base.reduce(into: &state, action: action)
        let localState = toLocalState(state)

        return previousLocalState != localState
            ? .merge(effects, perform(previousLocalState, localState, &state, action))
            : effects
    }
}
