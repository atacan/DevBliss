import BlissTheme
import ClipboardClient
import ComposableArchitecture
import FilePanelsClient
import SwiftUI

#if os(macOS)
    import MacSwiftUI
#endif

@Reducer
public struct OutputAttributedEditorReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared public var rawText: String  // Persisted
        public var text: NSMutableAttributedString  // Display (not persisted directly)
        var outputControls: OutputControlsReducer.State
        var isActivitySheetPresented: Bool = false

        // New initializer for persistence
        public init(rawText: Shared<String>, outputControls: OutputControlsReducer.State = .init()) {
            self._rawText = rawText
            self.text = NSMutableAttributedString(string: rawText.wrappedValue)
            self.outputControls = outputControls
        }

        // Convenience initializer
        public init(text: NSMutableAttributedString = .init(), outputControls: OutputControlsReducer.State = .init()) {
            self._rawText = Shared(value: text.string)
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
                clipboard.copyString(state.text.string)
                return .run { send in
                    try await mainQueue.sleep(for: .milliseconds(200))
                    await send(.outputControls(.copyEnded))
                }
            case .outputControls(.saveAsButtonTouched):
                #if os(macOS)
                    filePanel.saveWithPanel(.init(textToSave: state.text.string))
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

extension OutputAttributedEditorReducer.State {
    public mutating func updateText(_ newText: String) -> Effect<OutputAttributedEditorReducer.Action> {
        text = .init(attributedString: regularAttributedString(newText))
        $rawText.withLock { $0 = newText }
        return .none
    }

    public mutating func updateText(
        _ newText: NSMutableAttributedString
    )
        -> Effect<OutputAttributedEditorReducer.Action>
    {
        text = newText
        $rawText.withLock { $0 = newText.string }
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> Effect<OutputAttributedEditorReducer.Action> {
        text = .init(attributedString: newText)
        $rawText.withLock { $0 = newText.string }
        return .none
    }
}

public struct OutputAttributedEditorView: View {
    @Perception.Bindable var store: StoreOf<OutputAttributedEditorReducer>
    @State var isActivitySheetPresented: Bool = false

    let title: String
    let copyButtonTitle: String
    let saveAsButtonTitle: String

    public init(
        store: StoreOf<OutputAttributedEditorReducer>,
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
            #elseif os(iOS)
                ScrollView {
                    Text(AttributedString(store.text))
                        .font(.monospaced(.body)())
                        .textSelection(.enabled)
                        .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
                        .sheet(isPresented: $isActivitySheetPresented) {
                            ActivityView(
                                isSheetPresented: $isActivitySheetPresented,
                                activityItems: [store.text],
                                applicationActivities: []
                            )
                        }
                }
            #endif
        }
        .overlay(
            OutputControlsView(
                store:
                    store
                    .scope(
                        state: \.outputControls,
                        action: OutputAttributedEditorReducer.Action.outputControls
                    )
            )
            .padding(),
            //            } // <-ZStack
            alignment: .topTrailing
        )
    }
}

// SwiftUI preview
struct OutputAttributedEditorView_Previews: PreviewProvider {
    static var previews: some View {
        OutputAttributedEditorView(
            store: Store(
                initialState: OutputAttributedEditorReducer.State()
            ) {
                OutputAttributedEditorReducer()
            }
        )
    }
}

public func errorAttributedString(_ error: String) -> NSAttributedString {
    #if os(macOS)
        let textColor = NSColor(ThemeColor.Text.failure)
        let attributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.font:
                NSFont
                .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: NSFont.Weight.regular),
        ]
        let attributedString = NSAttributedString(string: error, attributes: attributes)
    #else
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(ThemeColor.Text.failure),
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(
                ofSize: UIFont.systemFontSize,
                weight: UIFont.Weight.regular
            ),
        ]
        let attributedString = NSAttributedString(string: error, attributes: attributes)
    #endif
    return attributedString
}
