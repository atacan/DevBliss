import BlissTheme
import ClipboardClient
import ComposableArchitecture
import FilePanelsClient
import MacSwiftUI
import SwiftUI

public struct OutputEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: String
        var outputControls: OutputControlsReducer.State
        @BindingState var isActivitySheetPresented: Bool = false

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
    #if os(macOS)
        @Dependency(\.filePanel) var filePanel
    #endif

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
                    try await mainQueue.sleep(for: .milliseconds(400))
                    return .outputControls(.copyEnded)
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
            MyPlainTextEditor(
                text: viewStore.binding(\.$text),
                isActivitySheetPresented: viewStore.binding(\.$isActivitySheetPresented)
            )
        }
        .overlay(
            OutputControlsView(
                store:
                    store.scope(
                        state: \.outputControls,
                        action: OutputEditorReducer.Action.outputControls
                    )
            )
            .padding(),

            alignment: .topTrailing
        )
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
