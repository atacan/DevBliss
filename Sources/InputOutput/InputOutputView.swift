import ClipboardClient
import ComposableArchitecture
import SplitView
import SwiftUI
import Theme

public struct InputOutputReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState public var input: String
        public var output: OutputReducer.State

        public init(input: String = "", output: OutputReducer.State = .init()) {
            self.input = input
            self.output = output
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case output(OutputReducer.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .output:
                return .none
            }
        }

        Scope(state: \.output, action: /Action.output) {
            OutputReducer()
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
                .font(.monospaced(.body)())
        }
    }

    var outputEditor: some View {
        OutputView(
            store: store.scope(
                state: \.output,
                action: InputOutputReducer.Action.output
            ),
            title: outputEditorTitle
        )
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
