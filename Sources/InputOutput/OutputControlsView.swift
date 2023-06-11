import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SharedModels
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
        case inputOtherToolButtonTouched(Tool)
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
            case .inputOtherToolButtonTouched:
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

    @State var isOtherToolsPopoverVisible = false

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
            Button {
                viewStore.send(.copyButtonTouched)
            } label: {
                Image(systemName: "doc.on.clipboard")
            } // <-Button
            .foregroundColor(
                viewStore.copyButtonAnimating
                    ? ThemeColor.Text.success
                    : ThemeColor.Text.controlText
            )
            .font(.footnote)
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .help("Copy to clipboard (Command+Shift+C)")

            Button {
                viewStore.send(.saveAsButtonTouched)
            } label: {
                Image(systemName: "opticaldiscdrive")
            } // <-Button

            .font(.footnote)
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .help("Save to disk (Command+Shift+S)")

            Button {
                isOtherToolsPopoverVisible = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            } // <-Button

            .font(.footnote)
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .help("Input it to the other tools (Command+Shift+U)")
            .popover(isPresented: $isOtherToolsPopoverVisible) {
                VStack(alignment: .leading) {
                    ForEach(Tool.allCases) { tool in
                        Button(action: {
                            isOtherToolsPopoverVisible = false
                            viewStore.send(.inputOtherToolButtonTouched(tool))
                        }) {
                            Text(tool.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.01))
                        }
                        .buttonStyle(.plain)
                        Divider()
                    } // <-ForEach
                } // <-VStack
                .padding()
            }
        }
    }
}

struct OutputViewControlsView_Previews: PreviewProvider {
    static var previews: some View {
        OutputControlsView()
    }
}
