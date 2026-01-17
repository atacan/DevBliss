import BlissTheme
import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import InputOutput
import RegexMatchesClient
import SharedModels
import SwiftUI

@Reducer
public struct RegexMatchesReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared(.regexMatchesIO) public var storage = ToolIOStorageDoubleOutput()
        public var inputOutput: InputAttributedTwoOutputAttributedEditorsReducer.State
        public var regexPattern: String
        var isConversionRequestInFlight = false

        public init() {
            let storage = Shared(wrappedValue: ToolIOStorageDoubleOutput(), .regexMatchesIO)
            self._storage = storage
            self.inputOutput = InputAttributedTwoOutputAttributedEditorsReducer.State(
                inputRawText: storage.input,
                outputRawText: storage.output,
                outputSecondRawText: storage.outputSecond
            )
            self.regexPattern = ""
        }

        public init(input: String, output: String = "") {
            let storage = Shared(
                wrappedValue: ToolIOStorageDoubleOutput(input: input, output: output, outputSecond: ""),
                .regexMatchesIO
            )
            self._storage = storage
            self.inputOutput = InputAttributedTwoOutputAttributedEditorsReducer.State(
                inputRawText: storage.input,
                outputRawText: storage.output,
                outputSecondRawText: storage.outputSecond
            )
            self.regexPattern = ""
        }

        public var outputText: String {
            inputOutput.output.text.string
        }

        public var outputSecondText: String {
            inputOutput.outputSecond.text.string
        }
    }

    public enum Action: BindableAction, Equatable {
        case observeSettings
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<RegexMatchesHighlightOutput>)
        case inputOutput(InputAttributedTwoOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.regexMatches) var regexMatches
    private enum CancelID { case conversionRequest }
    @Dependency(\.userDefaults) var userDefaults

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .observeSettings:
                        return observeSettings(&state)
            case let .binding(action):
                return setPreferences(for: action, from: state)
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                state.inputOutput.input.removeColorFromAttributedString()
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
                _ = state.inputOutput.output
                    .updateText(output.output.flatMap(\.capturedGroups).joined(separator: "\n"))
                return state.inputOutput.outputSecond
                    .updateText(output.output.map(\.wholeMatch).joined(separator: "\n"))
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

        Scope(state: \.inputOutput, action: \.inputOutput) {
            InputAttributedTwoOutputAttributedEditorsReducer()
        }
    }

    private func observeSettings(_ state: inout State) -> Effect<Action> {
        if let newRegexPattern = userDefaults.string(forKey: SettingsKey.regexPattern.rawValue) {
            state.regexPattern = newRegexPattern
        }
        return .none
    }

    private func setPreferences(for action: BindingAction<State>, from state: State) -> Effect<Action> {
        userDefaults.set(state.regexPattern, forKey: SettingsKey.regexPattern.rawValue)
        return .none
    }
}

public struct RegexMatchesView: View {
    @Bindable var store: StoreOf<RegexMatchesReducer>

    public init(store: StoreOf<RegexMatchesReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            TextField(
                NSLocalizedString("Regex pattern", bundle: Bundle.module, comment: ""),
                text: $store.regexPattern
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.monospaced(.body)())
            .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
            #endif
            .padding()
            Button(action: { store.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Extract", bundle: Bundle.module, comment: ""))
                    .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Extract matches (Cmd+Return)", bundle: Bundle.module, comment: ""))

            InputAttributedTwoOutputAttributedEditorsView(
                store: store.scope(state: \.inputOutput, action: RegexMatchesReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Input", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Capturing Groups", bundle: Bundle.module, comment: ""),
                outputSecondEditorTitle: NSLocalizedString("Matches", bundle: Bundle.module, comment: "")
            )
        }
        .onAppear {
            store.send(.observeSettings)
        }
    }
}

// preview
struct RegexMatchesReducer_Previews: PreviewProvider {
    static var previews: some View {
        RegexMatchesView(store: .init(initialState: .init()) { RegexMatchesReducer() })
    }
}

enum SettingsKey: String {
    case regexPattern = "RegexMatches_regexPattern"
}

#if DEBUG
    public struct RegexMatchesApp: App {
        public init() {}

        public var body: some Scene {
            WindowGroup {
                RegexMatchesView(
                    store: Store(
                        initialState: .init()
                    ) {
                        RegexMatchesReducer()
                            ._printChanges()
                    }
                )
            }
            #if os(macOS)
                .windowStyle(.titleBar)
                .windowToolbarStyle(.unified(showsTitle: true))
            #endif
        }
    }

#endif
