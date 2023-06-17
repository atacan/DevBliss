import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SplitView
import SwiftUI

public struct InputAttributedTwoOutputAttributedEditorsReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var input: InputAttributedEditorReducer.State
        public var output: OutputAttributedEditorReducer.State
        public var outputSecond: OutputAttributedEditorReducer.State

        public init(input: InputAttributedEditorReducer.State = .init(),
                    output: OutputAttributedEditorReducer.State = .init(),
                    outputSecond: OutputAttributedEditorReducer.State = .init()) {
            self.input = input
            self.output = output
            self.outputSecond = outputSecond
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputAttributedEditorReducer.Action)
        case output(OutputAttributedEditorReducer.Action)
        case outputSecond(OutputAttributedEditorReducer.Action)
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
            case .outputSecond:
                return .none
            }
        }

        Scope(state: \.input, action: /Action.input) {
            InputAttributedEditorReducer()
        }

        Scope(state: \.output, action: /Action.output) {
            OutputAttributedEditorReducer()
        }

        Scope(state: \.outputSecond, action: /Action.outputSecond) {
            OutputAttributedEditorReducer()
        }
    }
}

public struct InputAttributedTwoOutputAttributedEditorsView: View {
    let store: StoreOf<InputAttributedTwoOutputAttributedEditorsReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputAttributedTwoOutputAttributedEditorsReducer>

    let inputEditorTitle: String
    let outputEditorTitle: String
    let outputSecondEditorTitle: String

    let fraction = FractionHolder.usingUserDefaults(0.5, key: "inputOutputSplitFraction")
    @StateObject var layout = LayoutHolder.usingUserDefaults(.vertical, key: "inputOutputSplitLayout")
    //    @StateObject var layout = LayoutHolder(.vertical)
    //    @StateObject var hide = SideHolder.usingUserDefaults(key: "inputOutputSplitSide")
    @StateObject var hide = SideHolder()

    public init(
        store: StoreOf<InputAttributedTwoOutputAttributedEditorsReducer>,
        inputEditorTitle: String,
        outputEditorTitle: String,
        outputSecondEditorTitle: String
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.inputEditorTitle = inputEditorTitle
        self.outputEditorTitle = outputEditorTitle
        self.outputSecondEditorTitle = outputSecondEditorTitle
    }

    public var body: some View {
        Split(primary: { inputEditor }, 
        secondary: { 
            Split(primary: { outputEditor },
                secondary: { outputSecondEditor })
            .layout(layout.value == .horizontal ? LayoutHolder(.vertical) : LayoutHolder(.horizontal))

        })
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
                action: InputAttributedTwoOutputAttributedEditorsReducer.Action.input
            ),
            title: inputEditorTitle
        )
    }

    var outputEditor: some View {
        OutputAttributedEditorView(
            store: store.scope(
                state: \.output,
                action: InputAttributedTwoOutputAttributedEditorsReducer.Action.output
            ),
            title: outputEditorTitle
        )
    }

    var outputSecondEditor: some View {
        OutputAttributedEditorView(
            store: store.scope(
                state: \.outputSecond,
                action: InputAttributedTwoOutputAttributedEditorsReducer.Action.outputSecond
            ),
            title: outputSecondEditorTitle
        )
    }
}

struct InputAttributedTwoOutputAttributedEditorsView_Previews: PreviewProvider {
    static var previews: some View {
        InputAttributedTwoOutputAttributedEditorsView(
            store: Store(
                initialState: .init(),
                reducer: InputAttributedTwoOutputAttributedEditorsReducer()
            ),
            inputEditorTitle: "Input",
            outputEditorTitle: "Output",
            outputSecondEditorTitle: "Output Secondary"
        )
    }
}
