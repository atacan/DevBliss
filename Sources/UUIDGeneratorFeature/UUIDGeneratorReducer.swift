import ComposableArchitecture
import InputOutput
import SwiftUI
import UUIDGeneratorClient

public struct UUIDGeneratorReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @BindingState var count: Int
        @BindingState var textCase: TextCase
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

    public var body: some ReducerProtocol<State, Action> {
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
                        await send(.generationResponse(TaskResult {
                            try await uuidGenerator.generating(count, textCase)
                        }))
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
        Scope(state: \.output, action: /Action.output) {
            OutputEditorReducer()
        }
    }
}

public struct UUIDGeneratorView: View {
    let store: Store<UUIDGeneratorReducer.State, UUIDGeneratorReducer.Action>
    @ObservedObject var viewStore: ViewStore<UUIDGeneratorReducer.State, UUIDGeneratorReducer.Action>

    public init(store: StoreOf<UUIDGeneratorReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack(alignment: .center) {
//            HStack {
//                //            TextField("How many?", value: viewStore.binding(\.$count), formatter: NumberFormatter())
//                //                .textFieldStyle(RoundedBorderTextFieldStyle())
//                //                .frame(maxWidth: 100)
//                //            Stepper("", value: viewStore.binding(\.$count), in: 1...1_000_000)
//                Stepper(value: viewStore.binding(\.$count), in: 1 ... 1000) {
//                    //                Text("sdfkjds")
//                    TextField("How many?", value: viewStore.binding(\.$count), formatter: NumberFormatter())
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                }
//                .frame(maxWidth: 250)
//            }
            HStack { IntegerTextField(value: viewStore.binding(\.$count), range: 1 ... 1_000_000)
                Picker("", selection: viewStore.binding(\.$textCase)) {
                    Text("lowercase").tag(TextCase.lower)
                    Text("UPPERCASE").tag(TextCase.upper)
                }
            }
            Button {
                viewStore.send(.generateButtonTouched)
            } label: {
                Text("Generate")
            } // <-Button

            OutputEditorView(store: store.scope(
                state: \.output,
                action: UUIDGeneratorReducer.Action.output
            ))
        } // <-VStack
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        UUIDGeneratorView(
            store: Store(
                initialState: UUIDGeneratorReducer.State(),
                reducer: UUIDGeneratorReducer()
            )
        )
    }
}

// BUG: on macOS although the value stays 1+, the text field shows zero
struct IntegerTextField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Stepper(value: Binding(
                get: { value },
                set: { value = $0.clamped(to: range) }
            )) {
                TextField("", text: Binding(
                    get: { "\(value)" },
                    set: {
                        if let newValue = Int($0) {
                            value = newValue.clamped(to: range)
                        }
                    }
                ))
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
