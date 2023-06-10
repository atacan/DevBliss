import ClipboardClient
import ComposableArchitecture
import SwiftUI
import Theme

public struct OutputControlsReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var textToCopy = ""
        var copyButtonAnimating: Bool = false

        public init() {}
    }

    public enum Action: Equatable {
        case copyButtonTouched
        case saveAsButtonTouched
        case copyEnded
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.clipboard) var clipboard

    public var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .copyButtonTouched:
                state.copyButtonAnimating = true

                clipboard.copyString(state.textToCopy)
                return .task {
                    try await mainQueue.sleep(for: .milliseconds(200))
                    return .copyEnded
                }
            case .saveAsButtonTouched:
                return .none
            case .copyEnded:
                state.copyButtonAnimating = false
                return .none
            }
        }
    }
}

extension OutputControlsReducer.State {
    public mutating func setTextToCopy(_ newText: String) -> EffectTask<OutputControlsReducer.Action> {
        textToCopy = newText
        return .none
    }
}

struct OutputControlsView: View {
    let store: StoreOf<OutputControlsReducer>
    @ObservedObject var viewStore: ViewStoreOf<OutputControlsReducer>

    let copyButtonTitle: String
    let saveAsButtonTitle: String

    public init(
        store: StoreOf<OutputControlsReducer> = .init(
            initialState: .init(),
            reducer: OutputControlsReducer()
        ),
        copyButtonTitle: String = "Copy",
        saveAsButtonTitle: String = "Save As..."
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.copyButtonTitle = copyButtonTitle
        self.saveAsButtonTitle = saveAsButtonTitle
    }

    var body: some View {
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
    }
}

struct OutputViewControlsView_Previews: PreviewProvider {
    static var previews: some View {
        OutputControlsView()
    }
}
