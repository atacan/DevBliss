import BlissTheme
import ComposableArchitecture
import InputOutput
import RegExpTesterClient
import SharedModels
import SplitView
import SwiftUI

@Reducer
public struct RegExpTesterReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("regExpTester")) public var inputText = ""
        @Shared(.toolOutput("regExpTester")) public var outputText = ""
        var input: InputEditorReducer.State
        var output: OutputEditorReducer.State
        var pattern: String = ""
        var replacement: String = ""
        var options: RegExpOptions = .init()
        var matches: [RegExpMatch] = []
        var selectedMatchIndex: Int = 0
        var errorMessage: String?

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("regExpTester"))
            let outputText = Shared(wrappedValue: "", .toolOutput("regExpTester"))
            self._inputText = inputText
            self._outputText = outputText
            self.input = InputEditorReducer.State(text: inputText.projectedValue)
            self.output = OutputEditorReducer.State(text: outputText.projectedValue)
        }

        public init(inputText: String, outputText: String = "") {
            let input = Shared(wrappedValue: inputText, .toolInput("regExpTester"))
            let output = Shared(wrappedValue: outputText, .toolOutput("regExpTester"))
            self._inputText = input
            self._outputText = output
            self.input = InputEditorReducer.State(text: input.projectedValue)
            self.output = OutputEditorReducer.State(text: output.projectedValue)
        }

        var selectedMatch: RegExpMatch? {
            guard !matches.isEmpty else { return nil }
            let index = min(max(selectedMatchIndex, 0), matches.count - 1)
            return matches[index]
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
        case output(OutputEditorReducer.Action)
        case testButtonTouched
        case testResponse(TaskResult<RegExpTestResult>)
        case nextMatchButtonTouched
        case previousMatchButtonTouched
    }

    @Dependency(\.regExpTester) var regExpTester
    private enum CancelID { case testRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .input:
                return .none
            case .output:
                return .none

            case .testButtonTouched:
                state.errorMessage = nil
                let request = RegExpTestRequest(
                    pattern: state.pattern,
                    text: state.input.text,
                    replacement: state.replacement,
                    options: state.options
                )
                return .run { [regExpTester] send in
                    await send(
                        .testResponse(
                            TaskResult {
                                try regExpTester.test(request)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.testRequest, cancelInFlight: true)

            case let .testResponse(.success(result)):
                state.matches = result.matches
                state.selectedMatchIndex = result.matches.isEmpty ? 0 : min(state.selectedMatchIndex, result.matches.count - 1)
                return state.output.updateText(result.replacedText)
                    .map { Action.output($0) }

            case let .testResponse(.failure(error)):
                state.matches = []
                state.errorMessage = error.localizedDescription
                return state.output.updateText(error.localizedDescription)
                    .map { Action.output($0) }

            case .nextMatchButtonTouched:
                guard !state.matches.isEmpty else { return .none }
                state.selectedMatchIndex = (state.selectedMatchIndex + 1) % state.matches.count
                return .none

            case .previousMatchButtonTouched:
                guard !state.matches.isEmpty else { return .none }
                state.selectedMatchIndex = (state.selectedMatchIndex - 1 + state.matches.count) % state.matches.count
                return .none
            }
        }

        Scope(state: \.input, action: \.input) {
            InputEditorReducer()
        }

        Scope(state: \.output, action: \.output) {
            OutputEditorReducer()
        }
    }
}

public struct RegExpTesterView: View {
    @Bindable var store: StoreOf<RegExpTesterReducer>

    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.RegExpTester.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.RegExpTester.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<RegExpTesterReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Pattern")
                    TextField("Enter regex pattern", text: $store.pattern)
                        .blissTextField()
                        .gridCellColumns(2)

                    LoadingButton("Test", isLoading: false) {
                        store.send(.testButtonTouched)
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .help("Test (⌘ Return)")
                }

                GridRow {
                    ConfigLabel("Replace")
                    TextField("Replacement pattern", text: $store.replacement)
                        .blissTextField()
                        .gridCellColumns(2)

                    HStack(spacing: 8) {
                        Button {
                            store.send(.previousMatchButtonTouched)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.borderless)

                        Text(matchCounterText)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            store.send(.nextMatchButtonTouched)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                GridRow {
                    ConfigLabel("Options")
                    HStack(spacing: 16) {
                        Toggle("Case insensitive", isOn: $store.options.caseInsensitive)
                        Toggle("Allow comments", isOn: $store.options.allowCommentsAndWhitespace)
                        Toggle("Dot matches newlines", isOn: $store.options.dotMatchesLineSeparators)
                        Toggle("Multiline", isOn: $store.options.anchorsMatchLines)
                        Toggle("Unicode boundaries", isOn: $store.options.useUnicodeWordBoundaries)
                    }
                    .toggleStyle(.checkbox)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            Split(primary: { inputEditor }, secondary: { outputPane })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        InputEditorView(store: store.scope(state: \.input, action: \.input), title: "Test Text")
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Matches")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if store.matches.isEmpty {
                        Text("No matches")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(store.matches) { match in
                            Text(matchLine(for: match))
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(match.id == store.selectedMatchIndex ? Color.accentColor.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            OutputEditorView(
                store: store.scope(state: \.output, action: \.output),
                title: "Replaced Text"
            )
        }
    }

    private var matchCounterText: String {
        guard !store.matches.isEmpty else { return "0 matches" }
        return "\(store.selectedMatchIndex + 1) of \(store.matches.count)"
    }

    private func matchLine(for match: RegExpMatch) -> String {
        "[\(match.id)] \(match.value)"
    }
}

struct RegExpTesterView_Previews: PreviewProvider {
    static var previews: some View {
        RegExpTesterView(store: .init(initialState: .init()) { RegExpTesterReducer() })
    }
}
