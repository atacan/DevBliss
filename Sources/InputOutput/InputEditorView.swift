import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

@Reducer
public struct InputEditorReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared public var text: String
        var pasteButtonAnimating: Bool = false
        var inputEditorDrop: InputEditorDropReducer.State

        // New initializer accepting Shared<String>
        public init(text: Shared<String>, inputEditorDrop: InputEditorDropReducer.State = .init()) {
            self._text = text
            self.inputEditorDrop = inputEditorDrop
        }

        // Convenience initializer for non-persisted use (previews, tests)
        public init(text: String = "", inputEditorDrop: InputEditorDropReducer.State = .init()) {
            self._text = Shared(value: text)
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

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.inputEditorDrop, action: \.inputEditorDrop) {
            InputEditorDropReducer()
        }
        Reduce<State, Action> { state, action -> Effect<Action> in
            switch action {
            case .binding:
                return .none
            case .pasteButtonTouched:
                state.pasteButtonAnimating = true
                if let clip = clipboard.getString() {
                    state.$text.withLock { $0 = clip }
                }
                return .run { send in
                    try await mainQueue.sleep(for: .milliseconds(200))
                    await send(.pasteButtonAnimationEnded)
                }
            // case .saveAsButtonTouched:
            // return .none
            case .pasteButtonAnimationEnded:
                state.pasteButtonAnimating = false
                return .none
            case let .inputEditorDrop(.droppedFileContent(content)):
                state.$text.withLock { $0 = content }
                return .none
            case .inputEditorDrop:
                return .none
            case let .append(text):
                state.$text.withLock { $0.append(text) }
                return .none
            case let .prepend(text):
                state.$text.withLock { $0 = text + $0 }
                return .none
            }
        }
    }
}

extension InputEditorReducer.State {
    public mutating func updateText(_ newText: String) -> Effect<InputEditorReducer.Action> {
        $text.withLock { $0 = newText }
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> Effect<InputEditorReducer.Action> {
        $text.withLock { $0 = newText.string }
        return .none
    }
}

public struct InputEditorView: View {
    @Perception.Bindable var store: StoreOf<InputEditorReducer>

    let title: String
    let pasteButtonTitle: String

    public init(
        store: StoreOf<InputEditorReducer>,
        title: String = "Input",
        pasteButtonTitle: String = "Paste"
    ) {
        self.store = store
        self.title = title
        self.pasteButtonTitle = pasteButtonTitle
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            MyPlainTextEditor(text: $store.text, isActivitySheetPresented: .constant(false))
                .overlay(content: {
                    InputEditorDropView(
                        store: store.scope(state: \.inputEditorDrop, action: InputEditorReducer.Action.inputEditorDrop)
                    )
                })

            EditorFooterBar {
                EditorFooterButton(
                    pasteButtonTitle,
                    systemImage: "doc.on.clipboard.fill",
                    isAnimating: store.pasteButtonAnimating
                ) {
                    store.send(.pasteButtonTouched)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .help(NSLocalizedString("Paste from clipboard (Command+Shift+P)", bundle: Bundle.module, comment: ""))
                .accessibilityLabel(NSLocalizedString("Paste from clipboard", bundle: Bundle.module, comment: ""))

                Spacer()
            }
        }
    }
}

// SwiftUI preview
struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        InputEditorView(
            store: Store(
                initialState: InputEditorReducer.State(
                    inputEditorDrop: .init(isDropInProgress: true)
                )
            ) {
                InputEditorReducer()
            }
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
                        )
                    ) {
                        InputEditorReducer()
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
