import BlissTheme
import ComposableArchitecture
import Dependencies
import InputOutput
import RegexMatchesClient
import SwiftUI

public struct RegexMatchesReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputAttributedTwoOutputAttributedEditorsReducer.State
        @BindingState var regexPattern: String
        var isConversionRequestInFlight = false

        public init(
            inputOutput: InputAttributedTwoOutputAttributedEditorsReducer.State = .init(),
            regexPattern: String = ""
        ) {
            self.inputOutput = inputOutput
            self.regexPattern = regexPattern
        }

        public init(input: String, output: String = "") {
            self.inputOutput = .init(
                input: .init(text: .init(string: input)),
                output: .init(text: .init(string: output))
            )
            self.regexPattern = .init()
        }

        public var outputText: String {
            inputOutput.output.text.string
        }

        public var outputSecondText: String {
            inputOutput.outputSecond.text.string
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<RegexMatchesHighlightOutput>)
        case inputOutput(InputAttributedTwoOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.regexMatches) var regexMatches
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
                    .run { [input = state.inputOutput.input.text, regexPattern = state.regexPattern] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    let config = RegexMatchesConfig(
                                        wholeMatchColor: ThemeColor.Text.highlightedTextSecondary,
                                        capturedGroupColor: ThemeColor.Text.highlightedTextPrimary
                                    )
                                    return try await regexMatches.matches(input, regexPattern, config)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(output)):
                state.isConversionRequestInFlight = false
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/1952#discussioncomment-5167956
                _ = state.inputOutput.input.updateText(output.highlighted)
                _ = state.inputOutput.outputSecond
                    .updateText(output.output.flatMap(\.capturedGroups).joined(separator: "\n"))
                return state.inputOutput.output.updateText(output.output.map(\.wholeMatch).joined(separator: "\n"))
                    .map { Action.inputOutput(.output($0)) }
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                let attributedString = errorAttributedString("\(error)")
                return state.inputOutput.output.updateText(attributedString)
                    .map { Action.inputOutput(.output($0)) }
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputAttributedTwoOutputAttributedEditorsReducer()
        }
    }
}

public struct RegexMatchesView: View {
    let store: StoreOf<RegexMatchesReducer>
    @ObservedObject var viewStore: ViewStoreOf<RegexMatchesReducer>

    public init(store: StoreOf<RegexMatchesReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            TextField("Regex pattern", text: viewStore.binding(\.$regexPattern))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.monospaced(.body)())
            .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
            #endif
            .padding()
            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text("Extract")
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            InputAttributedTwoOutputAttributedEditorsView(
                store: store.scope(state: \.inputOutput, action: RegexMatchesReducer.Action.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Matches",
                outputSecondEditorTitle: "Capturing Groups"
            )
        }
    }
}

// preview
struct RegexMatchesReducer_Previews: PreviewProvider {
    static var previews: some View {
        RegexMatchesView(store: .init(initialState: .init(), reducer: RegexMatchesReducer()))
    }
}
