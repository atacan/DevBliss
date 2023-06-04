import ComposableArchitecture
import Dependencies
import HtmlToSwiftClient
import InputOutput
import SwiftUI

public struct HtmlToSwiftReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputReducer.State
        var isConversionRequestInFlight = false

        public init(inputOutput: InputOutputReducer.State = .init()) {
            self.inputOutput = inputOutput
        }
    }

    public enum Action: Equatable {
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputReducer.Action)
    }

    @Dependency(\.htmlToSwift) var htmlToSwift
    private enum CancelID { case conversionRequest }

    public var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                return
                    .run { [input = state.inputOutput.input] send in
                        await send(.conversionResponse(TaskResult { try await htmlToSwift.binaryBirds(input) }))
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(swiftCode)):
                state.isConversionRequestInFlight = false
                state.inputOutput.output = swiftCode
                return .none
            case .conversionResponse(.failure):
                state.isConversionRequestInFlight = false
                return .none
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputReducer()
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
            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text("Convert")
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            InputOutputView(
                store: store.scope(state: \.inputOutput, action: HtmlToSwiftReducer.Action.inputOutput),
                inputEditorTitle: "Html",
                outputEditorTitle: "Swift"
            )
        }
    }
}
