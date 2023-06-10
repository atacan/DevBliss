import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SplitView
import SwiftUI

public struct InputOutputEditorsReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var input: InputEditorReducer.State
        public var output: OutputEditorReducer.State

        public init(input: InputEditorReducer.State = .init(), output: OutputEditorReducer.State = .init()) {
            self.input = input
            self.output = output
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
        case output(OutputEditorReducer.Action)
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
            InputEditorReducer()
        }

        Scope(state: \.output, action: /Action.output) {
            OutputEditorReducer()
        }
    }
}

public struct InputOutputEditorsView: View {
    let store: StoreOf<InputOutputEditorsReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputOutputEditorsReducer>

    let inputEditorTitle: String
    let outputEditorTitle: String

    let fraction = FractionHolder.usingUserDefaults(0.5, key: "inputOutputSplitFraction")
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: "inputOutputSplitLayout")
    //    @StateObject var hide = SideHolder.usingUserDefaults(key: "inputOutputSplitSide")
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<InputOutputEditorsReducer>, inputEditorTitle: String, outputEditorTitle: String) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.inputEditorTitle = inputEditorTitle
        self.outputEditorTitle = outputEditorTitle
    }

    public var body: some View {
        //        #if os(iOS)
        //            VSplit {
        //                inputEditor
        //            } bottom: {
        //                outputEditor
        //            }
        //        #elseif os(macOS)
        //            HSplitView {
        //                inputEditor
        //                outputEditor
        //            }
        //        #endif
        Split(primary: { inputEditor }, secondary: { outputEditor })
            .fraction(fraction)
            .layout(layout)
            .hide(hide)
            .toolbar {
                InputOutputToolbarSplitItems(layout: layout, hide: hide)
            }
    }

    var inputEditor: some View {
        InputEditorView(
            store: store.scope(
                state: \.input,
                action: InputOutputEditorsReducer.Action.input
            ),
            title: inputEditorTitle
        )
    }

    var outputEditor: some View {
        OutputEditorView(
            store: store.scope(
                state: \.output,
                action: InputOutputEditorsReducer.Action.output
            ),
            title: outputEditorTitle
        )
    }
}

struct InputOutputView_Previews: PreviewProvider {
    static var previews: some View {
        InputOutputEditorsView(
            store: Store(
                initialState: .init(),
                reducer: InputOutputEditorsReducer()
            ),
            inputEditorTitle: "Input",
            outputEditorTitle: "Output"
        )
    }
}
