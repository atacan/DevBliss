import BlissTheme
import ComposableArchitecture
import InputOutput
import JSDiff
import JSDiffUI
import SharedModels
import SplitView
import StringDiffClient
import SwiftUI

@Reducer
public struct StringDiffReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("stringDiff")) public var oldText = ""
        @Shared(.toolOutput("stringDiff")) public var newText = ""
        public var oldInput: InputEditorReducer.State
        public var newInput: InputEditorReducer.State
        var diffType: DiffType = .lines
        var displayStyle: DiffDisplayStyle = .inline
        var changes: [Change] = []
        var isComputing = false

        public init() {
            let oldText = Shared(wrappedValue: "", .toolInput("stringDiff"))
            let newText = Shared(wrappedValue: "", .toolOutput("stringDiff"))
            self._oldText = oldText
            self._newText = newText
            self.oldInput = InputEditorReducer.State(text: oldText.projectedValue)
            self.newInput = InputEditorReducer.State(text: newText.projectedValue)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case oldInput(InputEditorReducer.Action)
        case newInput(InputEditorReducer.Action)
        case computeDiff
        case diffResponse(TaskResult<[Change]>)
    }

    @Dependency(\.stringDiff) var stringDiff
    private enum CancelID { case diff }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.oldInput, action: \.oldInput) {
            InputEditorReducer()
        }
        Scope(state: \.newInput, action: \.newInput) {
            InputEditorReducer()
        }
        Reduce { state, action in
            switch action {
            case .binding(\.diffType):
                return .send(.computeDiff)
            case .binding:
                return .none
            case .oldInput, .newInput:
                return .send(.computeDiff)
            case .computeDiff:
                state.isComputing = true
                let old = state.oldText
                let new = state.newText
                let type = state.diffType
                return .run { [stringDiff] send in
                    await send(.diffResponse(TaskResult {
                        await stringDiff.diff(type, old, new)
                    }))
                }
                .cancellable(id: CancelID.diff, cancelInFlight: true)
            case let .diffResponse(.success(changes)):
                state.isComputing = false
                state.changes = changes
                return .none
            case .diffResponse(.failure):
                state.isComputing = false
                return .none
            }
        }
    }
}

public struct StringDiffView: View {
    @Bindable var store: StoreOf<StringDiffReducer>

    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.StringDiff.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.vertical, key: SettingsKey.StringDiff.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<StringDiffReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            optionsView

            Divider()

            VSplit(top: { editorsPane }, bottom: { diffResultView })
                .fraction(fraction)
//                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var optionsView: some View {
        HStack(spacing: 12) {
            Picker(
                NSLocalizedString("Diff Type", comment: ""),
                selection: $store.diffType
            ) {
                ForEach(DiffType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .fixedSize()
            .help(NSLocalizedString("Select the granularity of the diff", comment: ""))

            Divider().frame(height: 20)

            DiffStylePicker(displayStyle: $store.displayStyle)
                .fixedSize()

            Spacer()

            if store.isComputing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var editorsPane: some View {
        HStack(spacing: 0) {
            InputEditorView(
                store: store.scope(state: \.oldInput, action: \.oldInput),
                title: NSLocalizedString("Original", comment: "")
            )
            Divider()
            InputEditorView(
                store: store.scope(state: \.newInput, action: \.newInput),
                title: NSLocalizedString("Modified", comment: "")
            )
        }
    }

    @ViewBuilder
    private var diffResultView: some View {
        if store.changes.isEmpty && !store.isComputing {
            VStack {
                Spacer()
                Text(NSLocalizedString("Enter text in both editors to see the diff", comment: ""))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            ScrollView(.vertical) {
                DiffView(
                    changes: store.changes,
                    displayStyle: store.displayStyle
                )
                .font(.system(.body, design: .monospaced))
                .padding()
            }
        }
    }
}

struct StringDiffReducer_Previews: PreviewProvider {
    static var previews: some View {
        StringDiffView(store: .init(initialState: .init()) { StringDiffReducer() })
    }
}
