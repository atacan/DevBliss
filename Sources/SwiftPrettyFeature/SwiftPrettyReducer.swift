import BlissTheme
import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import InputOutput
import SharedModels
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
            // @Dependency(\.userDefaults) var userDefaults
            // let config: InputEditorReducer.State = with(lockwoodConfig) {
            // .init(
            //         text: userDefaults.string(forKey: SettingsKey.SwiftPretty.lockwoodConfig) ?? $0.text
            //         text: String(data: userDefaults.data(forKey: SettingsKey.SwiftPretty.lockwoodConfig), encoding: .utf8) ?? $0.text
            // text: UserDefaults.standard.string(forKey: SettingsKey.SwiftPretty.lockwoodConfig) ?? $0.text
            // )
            // }
            // let config: InputEditorReducer.State = {
            //     if let data = userDefaults.data(forKey: SettingsKey.SwiftPretty.lockwoodConfig),
            //        let text = String(data: data, encoding: .utf8) {
            //         return .init(text: text)
            //     } else{return lockwoodConfig}
            // }()
            self.lockwoodConfig = lockwoodConfig
            self.inputOutput = inputOutput
            self.useLockwood = useLockwood
        }

        public init(input: String, output: String = "") {
            let inputOutput = InputOutputEditorsReducer.State(input: .init(text: input), output: .init(text: output))
            self.init(inputOutput: inputOutput)
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
            // case let .lockwoodConfig(.binding(action)):
            //     return setPreferences(for: action, from: state)
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

    //    @Dependency(\.userDefaults) var userDefaults

    // private func setPreferences(
    //     for action: BindingAction<InputEditorReducer.State>,
    //     from state: State
    // ) -> EffectTask<Action> {
    //     switch action {
    //     case \.$text:
    //         // userDefaults.set(state.lockwoodConfig.text, forKey: SettingsKey.SwiftPretty.lockwoodConfig)
    //         UserDefaults.standard.set(state.lockwoodConfig.text, forKey: SettingsKey.SwiftPretty.lockwoodConfig)
    //         // userDefaults.set(state.lockwoodConfig.text.data(using: .utf8), forKey:
    //         /SettingsKey.SwiftPretty.lockwoodConfig)
    //         return .none
    //     default:
    //         return .none
    //     }
    // }
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
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                //            }

                Button(action: { viewStore.send(.convertButtonTouched) }) {
                    Text(NSLocalizedString("Format", bundle: Bundle.module, comment: ""))
                        .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
                }
                .padding(.bottom)
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Format code (Cmd+Return)", bundle: Bundle.module, comment: ""))
            }
        } bottom: {
            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: SwiftPrettyReducer.Action.inputOutput),
                inputEditorTitle: NSLocalizedString("Raw", bundle: Bundle.module, comment: ""),
                outputEditorTitle: NSLocalizedString("Pretty", bundle: Bundle.module, comment: "")
            )
        }
        .styling(visibleThickness: 2)
    }

    var lockwoodEditor: some View {
        InputEditorView(
            store: store.scope(
                state: \.lockwoodConfig,
                action: SwiftPrettyReducer.Action.lockwoodConfig
            ),
            title: NSLocalizedString("nicklockwood/SwiftFormat Config", bundle: Bundle.module, comment: "")
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

#if DEBUG
    public struct SwiftPrettyApp: App {
        public init() {}

        public var body: some Scene {
            WindowGroup {
                SwiftPrettyView(
                    store: Store(
                        initialState: .init(),
                        reducer: SwiftPrettyReducer()
                            ._printChanges()
                    )
                )
            }
            #if os(macOS)
            .windowStyle(.titleBar)
            .windowToolbarStyle(.unified(showsTitle: true))
            #endif
        }
    }

#endif
