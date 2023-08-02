import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

public struct InputEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: String
        var pasteButtonAnimating: Bool = false

        public init(text: String = "") {
            self.text = text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pasteButtonTouched
        // case saveAsButtonTouched
        case pasteButtonAnimationEnded
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
            }
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
        }
        .overlay(
            HStack {
                Button {
                    viewStore.send(.pasteButtonTouched)
                } label: {
                    Image(systemName: "doc.on.clipboard.fill")
                }  // <-Button
                .foregroundColor(
                    viewStore.pasteButtonAnimating
                        ? ThemeColor.Text.success
                        : ThemeColor.Text.controlText
                )
                .font(.footnote)
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .help(NSLocalizedString("Paste from clipboard (Command+Shift+P)", bundle: Bundle.module, comment: ""))
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
                initialState: InputEditorReducer.State(),
                reducer: InputEditorReducer()
            )
        )
    }
}
