import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SwiftUI

public struct OutputControlsReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var copyButtonAnimating: Bool = false

        public init() {}
    }

    public enum Action: Equatable {
        case copyButtonTouched
        case saveAsButtonTouched
        case copyEnded
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .copyButtonTouched:
                state.copyButtonAnimating = true
                return .none
            case .saveAsButtonTouched:
                return .none
            case .copyEnded:
                state.copyButtonAnimating = false
                return .none
            }
        }
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
