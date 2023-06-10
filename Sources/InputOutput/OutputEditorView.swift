import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

public struct OutputEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: String
        var outputControls: OutputControlsReducer.State

        public init(text: String = "", outputControls: OutputControlsReducer.State = .init()) {
            self.text = text
            self.outputControls = outputControls
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case outputControls(OutputControlsReducer.Action)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.clipboard) var clipboard

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()

        // call it before the core reducer, so that animation starts earlier
        Scope(state: \.outputControls, action: /Action.outputControls) {
            OutputControlsReducer()
        }

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .outputControls(.copyButtonTouched):
                clipboard.copyString(state.text)
                return .task {
                    try await mainQueue.sleep(for: .milliseconds(200))
                    return .outputControls(.copyEnded)
                }

            case .outputControls:
                return .none
            }
        }
    }
}

extension OutputEditorReducer.State {
    public mutating func updateText(_ newText: String) -> EffectTask<OutputEditorReducer.Action> {
        text = newText
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> EffectTask<OutputEditorReducer.Action> {
        text = newText.string
        return .none
    }
}

public struct OutputEditorView: View {
    let store: StoreOf<OutputEditorReducer>
    @ObservedObject var viewStore: ViewStoreOf<OutputEditorReducer>

    let title: String
    let copyButtonTitle: String
    let saveAsButtonTitle: String

    public init(
        store: StoreOf<OutputEditorReducer>,
        title: String = "Output",
        copyButtonTitle: String = "Copy",
        saveAsButtonTitle: String = "Save As…"
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.title = title
        self.copyButtonTitle = copyButtonTitle
        self.saveAsButtonTitle = saveAsButtonTitle
    }

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(title)
                Spacer()
            }
            .overlay(
                OutputControlsView(
                    store:
                    store.scope(
                        state: \.outputControls,
                        action: OutputEditorReducer.Action.outputControls
                    )
                )
                .padding(1),

                alignment: .topTrailing
            )
            TextEditor(text: viewStore.binding(\.$text))
                .font(.monospaced(.body)())
        }
    }
}

// SwiftUI preview
struct OutputView_Previews: PreviewProvider {
    static var previews: some View {
        OutputEditorView(
            store: Store(
                initialState: OutputEditorReducer.State(),
                reducer: OutputEditorReducer()
            )
        )
    }
}