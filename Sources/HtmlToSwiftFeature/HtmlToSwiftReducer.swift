import ComposableArchitecture
import Dependencies
import HtmlSwift
import HtmlToSwiftClient
import InputOutput
import SwiftUI

public struct HtmlToSwiftReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        @BindingState var dsl: SwiftDSL = .binaryBirds
        @BindingState var component: HtmlOutputComponent = .fullHtml

        public init(inputOutput: InputOutputEditorsReducer.State = .init()) {
            self.inputOutput = inputOutput
        }

        public init(input: String, output: String = "") {
            self.inputOutput = .init(input: .init(text: input), output: .init(text: output))
        }

        public var outputText: String {
            inputOutput.output.text
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.htmlToSwift) var htmlToSwift
    private enum CancelID { case conversionRequest }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                return
                    .run { [input = state.inputOutput.input, dsl = state.dsl, component = state.component] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await htmlToSwift.convert(input.text, for: dsl, output: component)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(swiftCode)):
                state.isConversionRequestInFlight = false
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/1952#discussioncomment-5167956
                return state.inputOutput.output.updateText(swiftCode)
                    .map { Action.inputOutput(.output($0)) }
            case .conversionResponse(.failure):
                state.isConversionRequestInFlight = false
                return .none
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputEditorsReducer()
        }
    }
}

public struct HtmlToSwiftView: View {
    let store: StoreOf<HtmlToSwiftReducer>
    @ObservedObject var viewStore: ViewStoreOf<HtmlToSwiftReducer>

    public init(store: StoreOf<HtmlToSwiftReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                Picker("DSL Library", selection: viewStore.binding(\.$dsl)) {
                    ForEach(SwiftDSL.allCases) { dsl in
                        Text(dsl.rawValue)
                            .tag(dsl)
                    }
                }
                Picker("Component", selection: viewStore.binding(\.$component)) {
                    ForEach(HtmlOutputComponent.allCases) { component in
                        Text(component.rawValue)
                            .tag(component)
                    }
                }
                Spacer()
            } // <-HStack
            .frame(maxWidth: 450)

            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text("Convert")
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: HtmlToSwiftReducer.Action.inputOutput),
                inputEditorTitle: "Html",
                outputEditorTitle: "Swift"
            )
        }
    }
}

// preview
struct HtmlToSwiftReducer_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToSwiftView(store: .init(initialState: .init(), reducer: HtmlToSwiftReducer()))
    }
}
