import ClipboardClient
import ComposableArchitecture
import SplitView
import SwiftUI
import Theme

public struct InputOutputReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState var input: String
        @BindingState var output: String
        var copyButtonAnimating: Bool

        public init(input: String = "", output: String = "", copyButtonAnimating: Bool = false) {
            self.input = input
            self.output = output
            self.copyButtonAnimating = copyButtonAnimating
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case copyButtonTouched
        case saveAsButtonTouched
        case copyButtonAnimationEnded
    }

//    @Dependency(\.continuousClock) var clock // available in macOS 13
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.clipboard) var clipboard

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .copyButtonTouched:
                state.copyButtonAnimating = true
                clipboard.copyString(state.output)
                return .task {
//                    try await self.clock.sleep(for: .milliseconds(100))
                    try await self.mainQueue.sleep(for: .milliseconds(200))
                    return .copyButtonAnimationEnded
                }
            case .saveAsButtonTouched:
                return .none
            case .copyButtonAnimationEnded:
                state.copyButtonAnimating = false
                return .none
            }
        }
    }
}

public struct InputOutputView: View {
    let store: StoreOf<InputOutputReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputOutputReducer>

    let inputEditorTitle: String
    let outputEditorTitle: String

    public init(store: StoreOf<InputOutputReducer>, inputEditorTitle: String, outputEditorTitle: String) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.inputEditorTitle = inputEditorTitle
        self.outputEditorTitle = outputEditorTitle
    }

    public var body: some View {
        #if os(iOS)
            VSplit {
                inputEditor
            } bottom: {
                outputEditor
            }
        #elseif os(macOS)
            HSplitView {
                inputEditor
                outputEditor
            }
        #endif
    }

    var inputEditor: some View {
        VStack {
            Text(inputEditorTitle)
            TextEditor(text: viewStore.binding(\.$input))
        }
    }

    var outputEditor: some View {
        VStack {
            Text(outputEditorTitle)
            TextEditor(text: viewStore.binding(\.$output))
                .overlay(
                    HStack {
                        Button("Copy") {
                            viewStore.send(.copyButtonTouched)
                        }
                        .foregroundColor(viewStore.copyButtonAnimating ? .green : ThemeColor.Text.controlText)
                        .font(.footnote)
                        .keyboardShortcut("c", modifiers: [.command, .shift])

                        Button("Save As") {
                            viewStore.send(.saveAsButtonTouched)
                        }
                        .font(.footnote)
                        .keyboardShortcut("s", modifiers: [.command, .shift])
                    }
                    .padding(1),

                    alignment: .topTrailing
                )
        }
    }
}

struct InputOutputView_Previews: PreviewProvider {
    static var previews: some View {
        InputOutputView(
            store: Store(
                initialState: .init(),
                reducer: InputOutputReducer()
            ),
            inputEditorTitle: "Input",
            outputEditorTitle: "Output"
        )
    }
}
