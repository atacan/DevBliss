import BlissTheme
import ClipboardClient
import ComposableArchitecture
import FilePanelsClient
import MacSwiftUI
import SwiftUI

@Reducer
public struct OutputEditorReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared public var text: String
        var outputControls: OutputControlsReducer.State
        var isActivitySheetPresented: Bool = false

        public init(text: Shared<String>, outputControls: OutputControlsReducer.State = .init()) {
            self._text = text
            self.outputControls = outputControls
        }

        public init(text: String = "", outputControls: OutputControlsReducer.State = .init()) {
            self._text = Shared(value: text)
            self.outputControls = outputControls
        }

        public var editorText: String {
            get { text }
            set { $text.withLock { $0 = newValue } }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case outputControls(OutputControlsReducer.Action)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.clipboard) var clipboard
    #if os(macOS)
        @Dependency(\.filePanel) var filePanel
    #endif

    public var body: some Reducer<State, Action> {
        BindingReducer()

        // call it before the core reducer, so that animation starts earlier
        Scope(state: \.outputControls, action: \.outputControls) {
            OutputControlsReducer()
        }

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .outputControls(.copyButtonTouched):
                clipboard.copyString(state.text)
                return .run { send in
                    try await mainQueue.sleep(for: .milliseconds(400))
                    await send(.outputControls(.copyEnded))
                }
            case .outputControls(.saveAsButtonTouched):
                #if os(macOS)
                    filePanel.saveWithPanel(.init(textToSave: state.text))
                #else
                    state.isActivitySheetPresented = true
                #endif
                return .none
            case .outputControls:
                return .none
            }
        }
    }
}

extension OutputEditorReducer.State {
    public mutating func updateText(_ newText: String) -> Effect<OutputEditorReducer.Action> {
        $text.withLock { $0 = newText }
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> Effect<OutputEditorReducer.Action> {
        $text.withLock { $0 = newText.string }
        return .none
    }
}

public struct OutputEditorView: View {
    @Bindable var store: StoreOf<OutputEditorReducer>

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
        self.title = title
        self.copyButtonTitle = copyButtonTitle
        self.saveAsButtonTitle = saveAsButtonTitle
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            MyPlainTextEditor(
                text: $store.editorText,
                isActivitySheetPresented: $store.isActivitySheetPresented
            )

            EditorFooterBar {
                Spacer()
                OutputControlsView(
                    store:
                        store.scope(
                            state: \.outputControls,
                            action: OutputEditorReducer.Action.outputControls
                        )
                )
            }
        }
    }
}

// SwiftUI preview
struct OutputView_Previews: PreviewProvider {
    static var previews: some View {
        OutputEditorView(
            store: Store(
                initialState: OutputEditorReducer.State()
            ) {
                OutputEditorReducer()
            }
        )
    }
}

struct MyPlainTextEditor: View {
    @Binding var text: String
    @Binding var isActivitySheetPresented: Bool

    var body: some View {
        #if os(macOS)
            PlainMacEditorView(text: $text)
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
        #elseif os(iOS)
            TextEditor(text: $text)
                .font(.monospaced(.body)())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
                .sheet(isPresented: $isActivitySheetPresented) {
                    ActivityView(
                        isSheetPresented: $isActivitySheetPresented,
                        activityItems: [text],
                        applicationActivities: []
                    )
                }
        #endif
    }
}

#if os(iOS)
    struct ActivityView: UIViewControllerRepresentable {
        @Binding var isSheetPresented: Bool
        var activityItems: [Any]
        var applicationActivities: [UIActivity]?
        func makeUIViewController(
            context: UIViewControllerRepresentableContext<ActivityView>
        ) -> UIActivityViewController {
            let ac = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            ac.completionWithItemsHandler = {
                (
                    activityType: UIActivity.ActivityType?,
                    completed:
                        Bool,
                    arrayReturnedItems: [Any]?,
                    error: Error?
                ) in
                isSheetPresented = false
            }
            return ac
        }

        func updateUIViewController(
            _ uiViewController: UIActivityViewController,
            context: UIViewControllerRepresentableContext<ActivityView>
        ) {}
    }
#endif
