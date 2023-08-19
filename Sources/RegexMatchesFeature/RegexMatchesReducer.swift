import BlissTheme
import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import InputOutput
import RegexMatchesClient
import SwiftUI

public struct RegexMatchesReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputAttributedTwoOutputAttributedEditorsReducer.State
        @BindingState public var regexPattern: String
        var isConversionRequestInFlight = false

        public init(
            inputOutput: InputAttributedTwoOutputAttributedEditorsReducer.State = .init(),
            regexPattern: String = ""
        ) {
            self.inputOutput = inputOutput
            self.regexPattern = regexPattern
        }

        public init(input: String, output: String = "") {
            let attributedInput = NSMutableAttributedString(
                string: input,
                attributes: [
                    .foregroundColor: ThemeColor.Text.systemText,
                    .font: ThemeFont.monospaceSytem,
                ]
            )
            self.inputOutput = .init(
                input: .init(text: attributedInput),
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
        case observeSettings
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<RegexMatchesHighlightOutput>)
        case inputOutput(InputAttributedTwoOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.regexMatches) var regexMatches
    private enum CancelID { case conversionRequest }
    @Dependency(\.userDefaults) var userDefaults

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .observeSettings:
                return observeSettings()
            case let .binding(action):
                return setPreferences(for: action, from: state)
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

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputAttributedTwoOutputAttributedEditorsReducer()
        }
    }

    private func observeSettings() -> EffectTask<Action> {
        .run { send in
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    if let newRegexPattern = userDefaults.string(forKey: SettingsKey.regexPattern.rawValue) {
                        await send(.binding(.set(\.$regexPattern, newRegexPattern)))
                    }
                }
            }
        }
    }

    private func setPreferences(for action: BindingAction<State>, from state: State) -> EffectTask<Action> {
        switch action {
        case \.$regexPattern:
            userDefaults.set(state.regexPattern, forKey: SettingsKey.regexPattern.rawValue)
            return .none
        default:
            return .none
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
            TextField(
                NSLocalizedString("Regex pattern", bundle: Bundle.module, comment: ""),
                text: viewStore.binding(\.$regexPattern)
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.monospaced(.body)())
            .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
            #endif
                .padding()
            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Extract", bundle: Bundle.module, comment: ""))
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
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
            viewStore.send(.observeSettings)
        }
    }
}

// preview
struct RegexMatchesReducer_Previews: PreviewProvider {
    static var previews: some View {
        RegexMatchesView(store: .init(initialState: .init(), reducer: RegexMatchesReducer()))
    }
}

enum SettingsKey: String {
    case regexPattern = "RegexMatches_regexPattern"
}
