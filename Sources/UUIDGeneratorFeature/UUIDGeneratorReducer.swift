import BlissTheme
import ComposableArchitecture
import InputOutput
import SwiftUI
import UUIDGeneratorClient

@Reducer
public struct UUIDGeneratorReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        var count: Int
        var textCase: TextCase
        var output: OutputEditorReducer.State
        var isGenerating: Bool = false

        public init(
            count: Int = 1,
            textCase: TextCase = .upper,
            output: OutputEditorReducer.State = .init()
        ) {
            self.count = count
            self.textCase = textCase
            self.output = output
        }

        public var outputText: String {
            output.text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case generateButtonTouched
        case generationResponse(TaskResult<String>)
        case output(OutputEditorReducer.Action)
    }

    @Dependency(\.uuidGenerator) var uuidGenerator
    private enum CancelID { case generationRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .generateButtonTouched:
                state.isGenerating = true
                return
                    .run {
                        [count = state.count, textCase = state.textCase] send in
                        await send(
                            .generationResponse(
                                TaskResult {
                                    try await uuidGenerator.generating(count, textCase)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.generationRequest, cancelInFlight: true)
            case let .generationResponse(.success(uuids)):

                state.isGenerating = false
                return state.output.updateText(uuids)
                    .map { Action.output($0) }
            case .generationResponse(.failure):
                state.isGenerating = false
                return .none
            case .output:
                return .none
            }
        }
        Scope(state: \.output, action: \.output) {
            OutputEditorReducer()
        }
    }
}

public struct UUIDGeneratorView: View {
    @Bindable var store: Store<UUIDGeneratorReducer.State, UUIDGeneratorReducer.Action>

    public init(store: StoreOf<UUIDGeneratorReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                    IntegerTextField(value: $store.count, range: 1 ... 1_000_000)
                        .frame(width: 140)

                    ConfigLabel(NSLocalizedString("Case", bundle: Bundle.module, comment: ""))
                    Picker("", selection: $store.textCase) {
                        Text(NSLocalizedString("lowercase", bundle: Bundle.module, comment: "")).tag(TextCase.lower)
                        Text(NSLocalizedString("UPPERCASE", bundle: Bundle.module, comment: "")).tag(TextCase.upper)
                    }
                    .blissMenuPicker(width: 140)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton(NSLocalizedString("Generate", bundle: Bundle.module, comment: "")) {
                store.send(.generateButtonTouched)
            }
            .padding(.vertical, 8)

            Divider()

            OutputEditorView(
                store: store.scope(
                    state: \.output,
                    action: UUIDGeneratorReducer.Action.output
                )
            )
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        UUIDGeneratorView(
            store: Store(
                initialState: UUIDGeneratorReducer.State()
            ) {
                UUIDGeneratorReducer()
            }
        )
    }
}

// BUG: on macOS although the value stays 1+, the text field shows zero
struct IntegerTextField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Stepper(
                value: Binding(
                    get: { value },
                    set: { value = $0.clamped(to: range) }
                )
            ) {
                TextField(
                    "",
                    text: Binding(
                        get: { "\(value)" },
                        set: {
                            if let newValue = Int($0) {
                                value = newValue.clamped(to: range)
                            }
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 250)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
