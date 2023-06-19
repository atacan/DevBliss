import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

#if os(macOS)
    import MacSwiftUI
#endif

public struct OutputAttributedEditorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var text: NSMutableAttributedString
        var outputControls: OutputControlsReducer.State

        public init(text: NSMutableAttributedString = .init(), outputControls: OutputControlsReducer.State = .init()) {
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
        @Dependency(\.filePanels) var filePanels
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
                clipboard.copyString(state.text.string)
                return .task {
                    try await mainQueue.sleep(for: .milliseconds(200))
                    return .outputControls(.copyEnded)
                }
            case .outputControls(.saveAsButtonTouched):
                #if os(macOS)
                    filePanels.savePanel(.init(textToSave: state.text.string))
                #endif
                return .none

            case .outputControls:
                return .none
            }
        }
    }
}

extension OutputAttributedEditorReducer.State {
    public mutating func updateText(_ newText: String) -> EffectTask<OutputAttributedEditorReducer.Action> {
        text = .init(attributedString: regularAttributedString(newText))
        return .none
    }

    public mutating func updateText(
        _ newText: NSMutableAttributedString
    )
        -> EffectTask<OutputAttributedEditorReducer.Action>
    {
        text = newText
        return .none
    }

    public mutating func updateText(_ newText: NSAttributedString) -> EffectTask<OutputAttributedEditorReducer.Action> {
        text = .init(attributedString: newText)
        return .none
    }
}

public struct OutputAttributedEditorView: View {
    let store: StoreOf<OutputAttributedEditorReducer>
    @ObservedObject var viewStore: ViewStoreOf<OutputAttributedEditorReducer>

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
        self.viewStore = ViewStore(store)
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
                MacEditorView(text: viewStore.binding(\.$text), hasHorizontalScroll: false)
            #elseif os(iOS)
                ScrollView {
                    Text(AttributedString(viewStore.text))
                        .font(.monospaced(.body)())
                        .textSelection(.enabled)
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
                initialState: OutputAttributedEditorReducer.State(),
                reducer: OutputAttributedEditorReducer()
            )
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
