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
            }  // <-Button
            .foregroundColor(
                viewStore.copyButtonAnimating
                    ? ThemeColor.Text.success
                    : ThemeColor.Text.controlText
            )
            .font(.footnote)
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .help(NSLocalizedString("Copy to clipboard (Command+Shift+C)", bundle: Bundle.module, comment: ""))
            .accessibilityLabel(NSLocalizedString("Copy to clipboard", bundle: Bundle.module, comment: ""))

            Button {
                viewStore.send(.saveAsButtonTouched)
            } label: {
                Image(systemName: "opticaldiscdrive")
            }  // <-Button

            .font(.footnote)
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .help(NSLocalizedString("Save to disk (Command+Shift+S)", bundle: Bundle.module, comment: ""))
            .accessibilityLabel(NSLocalizedString("Save to disk", bundle: Bundle.module, comment: ""))

            Button {
                isOtherToolsPopoverVisible = true
            } label: {
                Image(systemName: "wand.and.rays.inverse")
            }  // <-Button
            .font(.footnote)
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .help(NSLocalizedString("Input it to the other tools (Command+Shift+U)", bundle: Bundle.module, comment: ""))
            .accessibilityLabel(NSLocalizedString("Input it to the other tools", bundle: Bundle.module, comment: ""))
            .popover(isPresented: $isOtherToolsPopoverVisible) {
                VStack(alignment: .leading) {
                    #if os(macOS)
                        popContent
                    #elseif os(iOS)
                        HStack(alignment: .center) {
                            Spacer()
                            Button(action: {
                                isOtherToolsPopoverVisible = false
                            }) {
                                Image(systemName: "xmark.circle")
                                    .opacity(0.8)
                                    .accessibilityLabel(NSLocalizedString("Close pop over", bundle: Bundle.module, comment: ""))
                            }
                            .padding()
                            .buttonStyle(.plain)
                        }  // <-HStack

                        Spacer()
                        popContent
                        Spacer()
                    #endif
                }  // <-VStack
                .padding()
            }
        }
    }

    var popContent: some View {
        Group {
            HStack(alignment: .lastTextBaseline) {
                Image(systemName: "square.and.pencil")
                Text(NSLocalizedString("Move the output to one of the tools as input", bundle: Bundle.module, comment: ""))
                    .lineLimit(nil)
                    .font(.headline)
            }
            .padding(.bottom)
            ForEach(Tool.allCases.filter(\.isInputtable)) { tool in
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
            }  // <-ForEach
        }  // <-Group
    }
}

struct OutputViewControlsView_Previews: PreviewProvider {
    static var previews: some View {
        OutputControlsView()
    }
}
