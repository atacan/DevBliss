import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

#if os(macOS)
    import MacSwiftUI
#endif

public struct InputAttributedEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: NSMutableAttributedString
        var pasteButtonAnimating: Bool = false

        public init(text: NSMutableAttributedString = .init()) {
            self.text = text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pasteButtonTouched
        case pasteButtonAnimationEnded
    }

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
                    _ = state.updateText(clip)
                }
                return .task {
                    try await mainQueue.sleep(for: .milliseconds(200))
                    return .pasteButtonAnimationEnded
                }
            case .pasteButtonAnimationEnded:
                state.pasteButtonAnimating = false
                return .none
            }
        }
    }
}

extension InputAttributedEditorReducer.State {
    public mutating func updateText(_ newText: String) -> EffectTask<InputAttributedEditorReducer.Action> {
        text = .init(attributedString: regularAttributedString(newText))
        return .none
    }

    public mutating func updateText(
        _ newText: NSMutableAttributedString
    )
        -> EffectTask<InputAttributedEditorReducer.Action>
    {
        text = newText
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> EffectTask<InputAttributedEditorReducer.Action> {
        text = .init(attributedString: newText)
        return .none
    }
}

public struct InputAttributedEditorView: View {
    let store: StoreOf<InputAttributedEditorReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputAttributedEditorReducer>

    let title: String
    let pasteButtonTitle: String

    public init(
        store: StoreOf<InputAttributedEditorReducer>,
        title: String = "Output",
        pasteButtonTitle: String = "Paste"
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.title = title
        self.pasteButtonTitle = pasteButtonTitle
    }

    public var body: some View {
        VStack(alignment: .leading) {
            //            ZStack(alignment: .trailingLastTextBaseline) {
            HStack {
                Spacer()
                Text(title)
                Spacer()
            }
            #if os(macOS)
                MacEditorView(text: viewStore.binding(\.$text), hasHorizontalScroll: false)
            #elseif os(iOS)
                //                ScrollView {
                //                    Text(AttributedString(viewStore.text))
                //                        .font(.monospaced(.body)())
                //                        .textSelection(.enabled)
                TextEditor(
                    text: viewStore.binding(
                        get: { state in
                            state.text.string
                        },
                        send: { newValue in
                            .binding(.set(\.$text, .init(string: newValue)))
                        }
                    )
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(
                    .init(
                        UIFont.monospacedSystemFont(
                            ofSize: UIFont.systemFontSize,
                            weight: UIFont.Weight.regular
                        )
                    )
                )
            //                }
            #endif
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
struct InputAttributedEditorView_Previews: PreviewProvider {
    static var previews: some View {
        InputAttributedEditorView(
            store: Store(
                initialState: InputAttributedEditorReducer.State(),
                reducer: InputAttributedEditorReducer()
            )
        )
    }
}

func regularAttributedString(_ error: String) -> NSAttributedString {
    #if os(macOS)
        let textColor = NSColor(ThemeColor.Text.editedText)
        let attributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.font:
                NSFont
                .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: NSFont.Weight.regular),
        ]
        let attributedString = NSAttributedString(string: error, attributes: attributes)
    #else
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(ThemeColor.Text.editedText),
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(
                ofSize: UIFont.systemFontSize,
                weight: UIFont.Weight.regular
            ),
        ]
        let attributedString = NSAttributedString(string: error, attributes: attributes)
    #endif
    return attributedString
}
