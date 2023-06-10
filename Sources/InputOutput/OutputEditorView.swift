import ClipboardClient
import ComposableArchitecture
import SwiftUI
import Theme

public struct OutputEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: String
        var copyButtonAnimating: Bool = false

        public init(text: String = "") {
            self.text = text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case copyButtonTouched
        case saveAsButtonTouched
        case copyButtonAnimationEnded
    }

    // @Dependency(\.continuousClock) var clock
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.clipboard) var clipboard

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .copyButtonTouched:
                state.copyButtonAnimating = true
                clipboard.copyString(state.text)
                return .task {
                    //                    try await self.clock.sleep(for: .milliseconds(100))
                    try await mainQueue.sleep(for: .milliseconds(200))
                    return .copyButtonAnimationEnded
                }
            case .saveAsButtonTouched:
                return .none
            case .copyButtonAnimationEnded:
                state.copyButtonAnimating = false
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
                HStack {
                    Button(copyButtonTitle) {
                        viewStore.send(.copyButtonTouched)
                    }
                    .foregroundColor(
                        viewStore.copyButtonAnimating
                            ? ThemeColor.Text.success
                            : ThemeColor.Text
                            .controlText
                    )
                    .font(.footnote)
                    .keyboardShortcut("c", modifiers: [.command, .shift])

                    Button(saveAsButtonTitle) {
                        viewStore.send(.saveAsButtonTouched)
                    }
                    .font(.footnote)
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                }
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
        OutputEditorView(store: Store(
            initialState: OutputEditorReducer.State(),
            reducer: OutputEditorReducer()
        ))
    }
}
