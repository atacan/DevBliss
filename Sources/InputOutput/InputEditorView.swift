import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

public struct InputEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: String
        var pasteButtonAnimating: Bool = false
        var inputEditorDrop: InputEditorDropReducer.State

        public init(text: String = "", inputEditorDrop: InputEditorDropReducer.State = .init()) {
            self.text = text
            self.inputEditorDrop = inputEditorDrop
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pasteButtonTouched
        // case saveAsButtonTouched
        case pasteButtonAnimationEnded
        case inputEditorDrop(InputEditorDropReducer.Action)
        case append(String)
        case prepend(String)
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
            case .pasteButtonTouched:
                state.pasteButtonAnimating = true
                if let clip = clipboard.getString() {
                    state.text = clip
                }
                return .task {
                    try await mainQueue.sleep(for: .milliseconds(200))
                    return .pasteButtonAnimationEnded
                }
            // case .saveAsButtonTouched:
            // return .none
            case .pasteButtonAnimationEnded:
                state.pasteButtonAnimating = false
                return .none
            case let .inputEditorDrop(.droppedFileContent(content)):
                state.text = content
                return .none
            case .inputEditorDrop:
                return .none
            case let .append(text):
                return .send(.binding(.set(\.$text, state.text.appending(text))))
            case let .prepend(text):
                return .send(.binding(.set(\.$text, text + state.text)))
            }
        }
        Scope(state: \.inputEditorDrop, action: /Action.inputEditorDrop) {
            InputEditorDropReducer()
        }
    }
}

extension InputEditorReducer.State {
    public mutating func updateText(_ newText: String) -> EffectTask<InputEditorReducer.Action> {
        text = newText
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> EffectTask<InputEditorReducer.Action> {
        text = newText.string
        return .none
    }
}

public struct InputEditorView: View {
    let store: StoreOf<InputEditorReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputEditorReducer>

    let title: String
    let pasteButtonTitle: String

    public init(
        store: StoreOf<InputEditorReducer>,
        title: String = "Input",
        pasteButtonTitle: String = "Paste"
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.title = title
        self.pasteButtonTitle = pasteButtonTitle
    }

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(title)
                Spacer()
            }
            MyPlainTextEditor(text: viewStore.binding(\.$text), isActivitySheetPresented: .constant(false))
                .overlay(content: {
                    InputEditorDropView(
                        store: store.scope(state: \.inputEditorDrop, action: InputEditorReducer.Action.inputEditorDrop)
                    )
                })
        }
        .overlay(
            HStack {
                Button {
                    viewStore.send(.pasteButtonTouched)
                } label: {
                    Image(systemName: "doc.on.clipboard.fill")
                } // <-Button
                .foregroundColor(
                    viewStore.pasteButtonAnimating
                        ? ThemeColor.Text.success
                        : ThemeColor.Text.controlText
                )
                .font(.footnote)
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .help(NSLocalizedString("Paste from clipboard (Command+Shift+P)", bundle: Bundle.module, comment: ""))
                .accessibilityLabel(NSLocalizedString("Paste from clipboard", bundle: Bundle.module, comment: ""))
            }
            .padding(),

            alignment: .topLeading
        )
    }
}

// SwiftUI preview
struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        InputEditorView(
            store: Store(
                initialState: InputEditorReducer.State(
                    inputEditorDrop: .init(isDropInProgress: true)
                ),
                reducer: InputEditorReducer()
            )
        )
        .padding()
    }
}

#if DEBUG
    public struct InputEditorApp: App {
        public init() {}
        public var body: some Scene {
            WindowGroup {
                InputEditorView(
                    store: Store(
                        initialState: .init(
                            inputEditorDrop: .init(isDropInProgress: false)
                        ),
                        reducer: InputEditorReducer()
                            ._printChanges()
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
