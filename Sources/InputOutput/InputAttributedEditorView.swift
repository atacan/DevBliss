import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

#if os(macOS)
    import MacSwiftUI
#endif

public struct InputAttributedEditorReducer: Reducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        public var text: NSMutableAttributedString
        var pasteButtonAnimating: Bool = false
        var inputEditorDrop: InputEditorDropReducer.State

        public init(
            text: NSMutableAttributedString = .init(),
            inputEditorDrop: InputEditorDropReducer.State = .init()
        ) {
            self.text = text
            self.inputEditorDrop = inputEditorDrop
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pasteButtonTouched
        case pasteButtonAnimationEnded
        case inputEditorDrop(InputEditorDropReducer.Action)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.clipboard) var clipboard

    public var body: some Reducer<State, Action> {
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
                return .run { send in
                    try await mainQueue.sleep(for: .milliseconds(200))
                    await send(.pasteButtonAnimationEnded)
                }
            case .pasteButtonAnimationEnded:
                state.pasteButtonAnimating = false
                return .none
            case let .inputEditorDrop(.droppedFileContent(content)):
                return state.updateText(content)
            case .inputEditorDrop:
                return .none
            }
        }
        Scope(state: \.inputEditorDrop, action: /Action.inputEditorDrop) {
            InputEditorDropReducer()
        }
    }
}

extension InputAttributedEditorReducer.State {
    public mutating func updateText(_ newText: String) -> Effect<InputAttributedEditorReducer.Action> {
        text = .init(attributedString: regularAttributedString(newText))
        return .none
    }

    public mutating func updateText(
        _ newText: NSMutableAttributedString
    )
        -> Effect<InputAttributedEditorReducer.Action>
    {
        text = newText
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> Effect<InputAttributedEditorReducer.Action> {
        text = .init(attributedString: newText)
        return .none
    }

    public mutating func removeColorFromAttributedString() {
        text.enumerateAttributes(in: NSRange(location: 0, length: text.length), options: []) { attributes, range, _ in
            if let _ = attributes[NSAttributedString.Key.backgroundColor] {
                text.removeAttribute(NSAttributedString.Key.backgroundColor, range: range)
            }
        }
    }
}

public struct InputAttributedEditorView: View {
    @Perception.Bindable var store: StoreOf<InputAttributedEditorReducer>

    let title: String
    let pasteButtonTitle: String

    public init(
        store: StoreOf<InputAttributedEditorReducer>,
        title: String = "Output",
        pasteButtonTitle: String = "Paste"
    ) {
        self.store = store
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
                MacEditorView(text: $store.text, hasHorizontalScroll: false)
                    .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
                    .overlay(content: {
                        InputEditorDropView(
                            store: store.scope(
                                state: \.inputEditorDrop,
                                action: InputAttributedEditorReducer.Action.inputEditorDrop
                            )
                        )
                    })
            #elseif os(iOS)
                //                ScrollView {
                //                    Text(AttributedString(store.text))
                //                        .font(.monospaced(.body)())
                //                        .textSelection(.enabled)
                TextEditor(
                    text: store.binding(
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
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
                .overlay(content: {
                    InputEditorDropView(
                        store: store.scope(
                            state: \.inputEditorDrop,
                            action: InputAttributedEditorReducer.Action.inputEditorDrop
                        )
                    )
                })
            //                }
            #endif
        }
        .overlay(
            HStack {
                Button {
                    store.send(.pasteButtonTouched)
                } label: {
                    Image(systemName: "doc.on.clipboard.fill")
                }  // <-Button
                .foregroundColor(
                    store.pasteButtonAnimating
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
struct InputAttributedEditorView_Previews: PreviewProvider {
    static var previews: some View {
        InputAttributedEditorView(
            store: Store(
                initialState: InputAttributedEditorReducer.State()
            ) {
                InputAttributedEditorReducer()
            }
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
