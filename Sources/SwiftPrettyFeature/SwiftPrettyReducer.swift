import BlissTheme
import ComposableArchitecture
import Dependencies
import InputOutput
import SplitView
import SwiftPrettyClient
import SwiftUI

public struct SwiftPrettyReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var lockwoodConfig: InputEditorReducer.State
        @BindingState var useLockwood: Bool

        public init(
            inputOutput: InputOutputEditorsReducer.State = .init(),
            lockwoodConfig: InputEditorReducer.State = .init(text: blissConfigLockwood),
            useLockwood: Bool = true
        ) {
            self.inputOutput = inputOutput
            self.lockwoodConfig = lockwoodConfig
            self.useLockwood = useLockwood
        }

        public init(input: String, output: String = "") {
            self.inputOutput = .init(input: .init(text: input), output: .init(text: output))
            self.lockwoodConfig = .init(text: blissConfigLockwood)
            useLockwood = true
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
        case lockwoodConfig(InputEditorReducer.Action)
    }

    @Dependency(\.swiftPretty) var swiftPretty
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
                    .run { [config = state.lockwoodConfig.text, input = state.inputOutput.input] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await swiftPretty.convert(config, input.text)
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
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                let attributedString = errorAttributedString("\(error)")
                return state.inputOutput.output.updateText(attributedString)
                    .map { Action.inputOutput(.output($0)) }
            case .inputOutput:
                return .none
            case .lockwoodConfig:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputEditorsReducer()
        }

        Scope(state: \.lockwoodConfig, action: /Action.lockwoodConfig) {
            InputEditorReducer()
        }
    }
}

public struct SwiftPrettyView: View {
    let store: StoreOf<SwiftPrettyReducer>
    @ObservedObject var viewStore: ViewStoreOf<SwiftPrettyReducer>

    @State var configIsExpanded = true

    public init(store: StoreOf<SwiftPrettyReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VSplit {
            VStack {
                //            DisclosureGroup("Configuration", isExpanded: $configIsExpanded) {
//                Toggle("Use Lockwood", isOn: viewStore.binding(\.$useLockwood))
//                    .toggleStyle(.automatic)
//                    .frame(width: .nan)
                lockwoodEditor
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                //            }

                Button(action: { viewStore.send(.convertButtonTouched) }) {
                    Text("Format")
                        .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        } bottom: {

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: SwiftPrettyReducer.Action.inputOutput),
                inputEditorTitle: "Raw",
                outputEditorTitle: "Pretty"
            )
        }

    }

    var lockwoodEditor: some View {
        InputEditorView(
            store: store.scope(
                state: \.lockwoodConfig,
                action: SwiftPrettyReducer.Action.lockwoodConfig
            ),
            title: "nicklockwood/SwiftFormat Config"
        )
    }
}

// preview
struct SwiftPrettyReducer_Previews: PreviewProvider {
    static var previews: some View {
        SwiftPrettyView(store: .init(initialState: .init(), reducer: SwiftPrettyReducer()))
    }
}

public let blissConfigLockwood = """
    --acronyms ID,URL,UUID
    --allman false
    --assetliterals visual-width
    --asynccapturing
    --beforemarks
    --binarygrouping 4,8
    --categorymark "MARK: %c"
    --classthreshold 0
    --closingparen balanced
    --closurevoid remove
    --commas always
    --conflictmarkers reject
    --decimalgrouping 3,6
    --elseposition same-line
    --emptybraces no-space
    --enumnamespaces always
    --enumthreshold 0
    --exponentcase lowercase
    --exponentgrouping disabled
    --extensionacl on-declarations
    --extensionlength 0
    --extensionmark "MARK: - %t + %c"
    --fractiongrouping disabled
    --fragment false
    --funcattributes prev-line
    --generictypes
    --groupedextension "MARK: %c"
    --guardelse auto
    --header strip
    --hexgrouping 4,8
    --hexliteralcase uppercase
    --ifdef indent
    --importgrouping alpha
    --indent 4
    --indentcase false
    --indentstrings false
    --lifecycle
    --lineaftermarks true
    --linebreaks lf
    --markcategories false
    --markextensions always
    --marktypes always
    --maxwidth 120
    --modifierorder
    --nevertrailing
    --nospaceoperators
    --nowrapoperators
    --octalgrouping 4,8
    --operatorfunc spaced
    --organizetypes actor,class,enum,struct
    --patternlet hoist
    --ranges spaced
    --redundanttype infer-locals-only
    --self init-only
    --selfrequired
    --semicolons inline
    --shortoptionals always
    --smarttabs enabled
    --someAny true
    --stripunusedargs always
    --structthreshold 0
    --tabwidth unspecified
    --throwcapturing
    --trailingclosures
    --trimwhitespace always
    --typeattributes prev-line
    --typeblanklines remove
    --typemark "MARK: - %t"
    --varattributes preserve
    --voidtype void
    --wraparguments before-first
    --wrapcollections before-first
    --wrapconditions after-first
    --wrapeffects preserve
    --wrapenumcases always
    --wrapparameters default
    --wrapreturntype preserve
    --wrapternary default
    --wraptypealiases preserve
    --xcodeindentation disabled
    --yodaswap always
    --disable enumNamespaces,unusedArguments,wrapMultilineStatementBraces
    --enable blankLineAfterImports,isEmpty,sortedSwitchCases,wrapConditionalBodies,wrapEnumCases,wrapSwitchCases
    """
