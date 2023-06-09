import BlissTheme
import ClipboardClient
import ComposableArchitecture
import SplitView
import SwiftUI

public struct InputOutputAttributedEditorsReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var input: InputEditorReducer.State
        public var output: OutputAttributedEditorReducer.State

        public init(input: InputEditorReducer.State = .init(), output: OutputAttributedEditorReducer.State = .init()) {
            self.input = input
            self.output = output
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
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
            InputEditorReducer()
        }

        Scope(state: \.output, action: /Action.output) {
            OutputAttributedEditorReducer()
        }
    }
}

public struct InputOutputAttributedEditorsView: View {
    let store: StoreOf<InputOutputAttributedEditorsReducer>
    @ObservedObject var viewStore: ViewStoreOf<InputOutputAttributedEditorsReducer>

    let inputEditorTitle: String
    let outputEditorTitle: String

    let fraction = FractionHolder.usingUserDefaults(0.5, key: "inputOutputSplitFraction")
    @StateObject var layout = LayoutHolder.usingUserDefaults(.vertical, key: "inputOutputSplitLayout")
    //    @StateObject var layout = LayoutHolder(.vertical)
    //    @StateObject var hide = SideHolder.usingUserDefaults(key: "inputOutputSplitSide")
    @StateObject var hide = SideHolder()

    public init(
        store: StoreOf<InputOutputAttributedEditorsReducer>,
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
        InputEditorView(
            store: store.scope(
                state: \.input,
                action: InputOutputAttributedEditorsReducer.Action.input
            ),
            title: inputEditorTitle
        )
    }

    var outputEditor: some View {
        OutputAttributedEditorView(
            store: store.scope(
                state: \.output,
                action: InputOutputAttributedEditorsReducer.Action.output
            ),
            title: outputEditorTitle
        )
    }
}

struct InputOutputAttributedEditorsView_Previews: PreviewProvider {
    static var previews: some View {
        InputOutputAttributedEditorsView(
            store: Store(
                initialState: .init(),
                reducer: InputOutputAttributedEditorsReducer()
            ),
            inputEditorTitle: "Input",
            outputEditorTitle: "Output"
        )
    }
}

struct InputOutputToolbarSplitItems: View {
    @ObservedObject var layout: LayoutHolder
    @ObservedObject var hide: SideHolder

    var body: some View {
        Group {
            Button(
                action: {
                    withAnimation {
                        layout.toggle()
                    }
                },
                label: {
                    layout
                        .isHorizontal
                        ? Image(systemName: "rectangle.split.1x2") : Image(systemName: "rectangle.split.2x1")
                }
            )
            .disabled(hide.side != nil)
            .accessibilityLabel(
                layout
                    .isHorizontal ? "vertical split" : "horizontal split"
            )
            .accessibilityHint(
                layout
                    .isHorizontal
                    ? "the input and output editor will be located next to each other"
                    : "the input and output editor will be located underneath each other"
            )

            Button(
                action: {
                    withAnimation {
                        //                                hide.toggle()
                        if hide.side == nil {
                            hide.hide(.primary)
                        }
                        else {
                            hide.toggle()
                        }
                    }
                },
                label: {
                    if hide.side == nil {
                        layout
                            .isHorizontal
                            ? Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
                            : Image(systemName: "dock.arrow.up.rectangle")
                    }
                    else {
                        layout
                            .isHorizontal
                            ? Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
                            : Image(systemName: "dock.arrow.down.rectangle")
                    }
                }
            )
        }
    }
}

extension NSAttributedString: @unchecked Sendable {}
