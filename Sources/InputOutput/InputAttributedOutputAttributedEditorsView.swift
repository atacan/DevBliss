import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SplitView
import SwiftUI

public struct InputAttributedOutputAttributedEditorsReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var input: InputAttributedEditorReducer.State
        public var output: OutputAttributedEditorReducer.State

        public init(
            input: InputAttributedEditorReducer.State = .init(),
            output: OutputAttributedEditorReducer.State = .init()
        ) {
            self.input = input
            self.output = output
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputAttributedEditorReducer.Action)
        case output(OutputAttributedEditorReducer.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .input:
                return .none
            case .output:
                return .none
            }
        }

        Scope(state: \.input, action: /Action.input) {
            InputAttributedEditorReducer()
        }

        Scope(state: \.output, action: /Action.output) {
            OutputAttributedEditorReducer()
        }
    }
}

public struct InputAttributedOutputAttributedEditorsView: View {
    let store: StoreOf<InputAttributedOutputAttributedEditorsReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputAttributedOutputAttributedEditorsReducer>

    let inputEditorTitle: String
    let outputEditorTitle: String

    let fraction = FractionHolder.usingUserDefaults(0.5, key: "inputOutputSplitFraction")
    @StateObject var layout = LayoutHolder.usingUserDefaults(.vertical, key: "inputOutputSplitLayout")
    //    @StateObject var layout = LayoutHolder(.vertical)
    //    @StateObject var hide = SideHolder.usingUserDefaults(key: "inputOutputSplitSide")
    @StateObject var hide = SideHolder()

    public init(
        store: StoreOf<InputAttributedOutputAttributedEditorsReducer>,
        inputEditorTitle: String,
        outputEditorTitle: String
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.inputEditorTitle = inputEditorTitle
        self.outputEditorTitle = outputEditorTitle
    }

    public var body: some View {
        Split(primary: { inputEditor }, secondary: { outputEditor })
            .fraction(fraction)
            .layout(layout)
            .hide(hide)
            .toolbar {
                ToolbarItemGroup {
                    InputOutputToolbarSplitItems(layout: layout, hide: hide)
                }
            }
    }

    var inputEditor: some View {
        InputAttributedEditorView(
            store: store.scope(
                state: \.input,
                action: InputAttributedOutputAttributedEditorsReducer.Action.input
            ),
            title: inputEditorTitle
        )
    }

    var outputEditor: some View {
        OutputAttributedEditorView(
            store: store.scope(
                state: \.output,
                action: InputAttributedOutputAttributedEditorsReducer.Action.output
            ),
            title: outputEditorTitle
        )
    }
}

struct InputAttributedOutputAttributedEditorsView_Previews: PreviewProvider {
    static var previews: some View {
        InputAttributedOutputAttributedEditorsView(
            store: Store(
                initialState: .init(),
                reducer: InputAttributedOutputAttributedEditorsReducer()
            ),
            inputEditorTitle: "Input",
            outputEditorTitle: "Output"
        )
    }
}
