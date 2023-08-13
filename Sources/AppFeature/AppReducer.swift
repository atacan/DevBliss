import ComposableArchitecture
import FileContentSearchFeature
import HtmlToSwiftFeature
import JsonPrettyFeature
import NameGeneratorFeature
import PrefixSuffixFeature
import RegexMatchesFeature
import SharedModels
import SwiftPrettyFeature
import SwiftUI
import TextCaseConverterFeature
import UUIDGeneratorFeature

public struct AppReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @PresentationState var htmlToSwift: HtmlToSwiftReducer.State?
        @PresentationState var jsonPretty: JsonPrettyReducer.State?
        @PresentationState var textCaseConverter: TextCaseConverterReducer.State?
        @PresentationState var uuidGenerator: UUIDGeneratorReducer.State?
        @PresentationState var prefixSuffix: PrefixSuffixReducer.State?
        @PresentationState var regexMatches: RegexMatchesReducer.State?
        @PresentationState var swiftPrettyLockwood: SwiftPrettyReducer.State?
        @PresentationState var fileContentSearch: FileContentSearchReducer.State?
        @PresentationState var nameGenerator: NameGeneratorReducer.State?
        var currentTool: Tool? = nil

        public init(
            htmlToSwift: HtmlToSwiftReducer.State? = nil,
            jsonPretty: JsonPrettyReducer.State? = nil,
            textCaseConverter: TextCaseConverterReducer.State? = nil,
            uuidGenerator: UUIDGeneratorReducer.State? = nil,
            prefixSuffix: PrefixSuffixReducer.State? = nil,
            regexMatches: RegexMatchesReducer.State? = nil,
            swiftPrettyLockwood: SwiftPrettyReducer.State? = nil,
            fileContentSearch: FileContentSearchReducer.State? = nil,
            nameGenerator: NameGeneratorReducer.State? = nil
        ) {
            self.htmlToSwift = htmlToSwift
            self.jsonPretty = jsonPretty
            self.textCaseConverter = textCaseConverter
            self.uuidGenerator = uuidGenerator
            self.prefixSuffix = prefixSuffix
            self.regexMatches = regexMatches
            self.swiftPrettyLockwood = swiftPrettyLockwood
            self.fileContentSearch = fileContentSearch
            self.nameGenerator = nameGenerator
        }
    }

    public enum Action: Equatable {
        case htmlToSwift(PresentationAction<HtmlToSwiftReducer.Action>)
        case jsonPretty(PresentationAction<JsonPrettyReducer.Action>)
        case textCaseConverter(PresentationAction<TextCaseConverterReducer.Action>)
        case uuidGenerator(PresentationAction<UUIDGeneratorReducer.Action>)
        case prefixSuffix(PresentationAction<PrefixSuffixReducer.Action>)
        case regexMatches(PresentationAction<RegexMatchesReducer.Action>)
        case swiftPrettyLockwood(PresentationAction<SwiftPrettyReducer.Action>)
        case fileContentSearch(PresentationAction<FileContentSearchReducer.Action>)
        case nameGenerator(PresentationAction<NameGeneratorReducer.Action>)
        case navigationLinkTouched(Tool)
        case nextToolButtonTouched
        case previousToolButtonTouched
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .htmlToSwift(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisToolOutput: state.htmlToSwift?.outputText, otherTool: otherTool, state: &state)
                return .none
            case let .jsonPretty(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisToolOutput: state.jsonPretty?.outputText, otherTool: otherTool, state: &state)
                return .none
            case let .textCaseConverter(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(
                    thisToolOutput: state.textCaseConverter?.outputText,
                    otherTool: otherTool,
                    state: &state
                )
                return .none
            case let .uuidGenerator(
                .presented(.output(.outputControls(.inputOtherToolButtonTouched(otherTool))))
            ):
                handleOtherTool(thisToolOutput: state.uuidGenerator?.outputText, otherTool: otherTool, state: &state)
                return .none
            case let .prefixSuffix(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisToolOutput: state.prefixSuffix?.outputText, otherTool: otherTool, state: &state)
                return .none
            case let .regexMatches(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisToolOutput: state.regexMatches?.outputText, otherTool: otherTool, state: &state)
                return .none
            case let .regexMatches(
                .presented(.inputOutput(.outputSecond(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(
                    thisToolOutput: state.regexMatches?.outputSecondText,
                    otherTool: otherTool,
                    state: &state
                )
                return .none
            case let .swiftPrettyLockwood(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(
                    thisToolOutput: state.swiftPrettyLockwood?.outputText,
                    otherTool: otherTool,
                    state: &state
                )
                return .none
            case let .nameGenerator(
                .presented(.output(.outputControls(.inputOtherToolButtonTouched(otherTool))))
            ):
                handleOtherTool(thisToolOutput: state.nameGenerator?.outputText, otherTool: otherTool, state: &state)
                return .none

            #if os(macOS)
                case let .fileContentSearch(
                    .presented(.output(.outputControls(.inputOtherToolButtonTouched(otherTool))))
                ):
                    handleOtherTool(
                        thisToolOutput: state.fileContentSearch?.outputText,
                        otherTool: otherTool,
                        state: &state
                    )
                    return .none
            #endif

            case .nextToolButtonTouched:
                handleNextToolNavigation(state: &state)
                return .none
            case .previousToolButtonTouched:
                handlePreviousToolNavigation(state: &state)
                return .none

            case let .navigationLinkTouched(tool):
                handleNavigation(tool: tool, state: &state)
                return .none

            case .htmlToSwift:
                return .none
            case .jsonPretty:
                return .none
            case .textCaseConverter:
                return .none
            case .uuidGenerator:
                return .none
            case .prefixSuffix:
                return .none
            case .regexMatches:
                return .none
            case .swiftPrettyLockwood:
                return .none
            case .fileContentSearch:
                return .none
            case .nameGenerator:
                return .none
            }
        }
        .ifLet(\.$htmlToSwift, action: /Action.htmlToSwift) {
            HtmlToSwiftReducer()
        }
        .ifLet(\.$jsonPretty, action: /Action.jsonPretty) {
            JsonPrettyReducer()
        }
        .ifLet(\.$textCaseConverter, action: /Action.textCaseConverter) {
            TextCaseConverterReducer()
        }
        .ifLet(\.$uuidGenerator, action: /Action.uuidGenerator) {
            UUIDGeneratorReducer()
        }
        .ifLet(\.$prefixSuffix, action: /Action.prefixSuffix) {
            PrefixSuffixReducer()
        }
        .ifLet(\.$regexMatches, action: /Action.regexMatches) {
            RegexMatchesReducer()
        }
        .ifLet(\.$swiftPrettyLockwood, action: /Action.swiftPrettyLockwood) {
            SwiftPrettyReducer()
        }
        .ifLet(\.$fileContentSearch, action: /Action.fileContentSearch) {
            FileContentSearchReducer()
        }
        .ifLet(\.$nameGenerator, action: /Action.nameGenerator) {
            NameGeneratorReducer()
        }
    }

    private func handleOtherTool(thisToolOutput: String?, otherTool: Tool, state: inout State) {
        state.currentTool = otherTool
        switch otherTool {
        case .htmlToSwift:
            state.htmlToSwift = HtmlToSwiftReducer.State(input: thisToolOutput ?? "")
        case .jsonPretty:
            state.jsonPretty = JsonPrettyReducer.State(input: thisToolOutput ?? "")
        case .textCaseConverter:
            state.textCaseConverter = TextCaseConverterReducer.State(input: thisToolOutput ?? "")
        case .prefixSuffix:
            state.prefixSuffix = PrefixSuffixReducer.State(input: thisToolOutput ?? "")
        case .regexMatches:
            state.regexMatches = RegexMatchesReducer.State(input: thisToolOutput ?? "")
        case .uuidGenerator:
            break
        case .swiftPrettyLockwood:
            state.swiftPrettyLockwood = SwiftPrettyReducer.State(input: thisToolOutput ?? "")
        case .fileContentSearch:
            break
        case .nameGenerator:
            break
        }
    }

    private func handleNavigation(tool: Tool, state: inout State) {
        state.currentTool = tool
        switch tool {
        case .htmlToSwift:
            state.htmlToSwift = .init()
        case .jsonPretty:
            state.jsonPretty = .init()
        case .textCaseConverter:
            state.textCaseConverter = .init()
        case .uuidGenerator:
            state.uuidGenerator = .init()
        case .prefixSuffix:
            state.prefixSuffix = .init()
        case .regexMatches:
            state.regexMatches = .init()
        case .swiftPrettyLockwood:
            state.swiftPrettyLockwood = .init()
        case .fileContentSearch:
            state.fileContentSearch = .init()
        case .nameGenerator:
            state.nameGenerator = .init()
        }
    }

    private func handleNextToolNavigation(state: inout State) {
        // find the current tool
        guard let currentTool = state.currentTool else {
            return
        }
        // find the next tool
        let nextTool = currentTool.next()
        handleNavigation(tool: nextTool, state: &state)
    }

    private func handlePreviousToolNavigation(state: inout State) {
        // find the current tool
        guard let currentTool = state.currentTool else {
            return
        }
        // find the next tool
        let previousTool = currentTool.previous()
        handleNavigation(tool: previousTool, state: &state)
    }
}

public struct AppView: View {
    let store: StoreOf<AppReducer>
    @ObservedObject var viewStore: ViewStoreOf<AppReducer>
    public init(store: StoreOf<AppReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        NavigationView {
            List {
                Section(
                    NSLocalizedString(
                        "Converters",
                        bundle: Bundle.module,
                        comment: "sidebar section name for a group of tools"
                    )
                ) {
                    NavigationLinkStore(
                        store.scope(state: \.$htmlToSwift, action: { .htmlToSwift($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.htmlToSwift))
                    } destination: { store in
                        HtmlToSwiftView(store: store)
                            .navigationTitle(
                                NSLocalizedString(
                                    "Convert Html code to a DSL in Swift",
                                    bundle: Bundle.module,
                                    comment: "a navigationTitle"
                                )
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: {
                                Text(
                                    NSLocalizedString(
                                        "Html to Swift",
                                        bundle: Bundle.module,
                                        comment: "tool name on the sidebar"
                                    )
                                )
                            },
                            icon: {
                                ZStack(alignment: .leading) {
                                    Image(systemName: "swift")
                                        .offset(CGSize(width: 5, height: 0))
                                    Text(
                                        NSLocalizedString(
                                            "<>",
                                            bundle: Bundle.module,
                                            comment: "icon next to the tool name on the sidebar"
                                        )
                                    )
                                    .font(.monospaced(Font.system(size: 14))())
                                    .fontWeight(.thin)
                                    .offset(CGSize(width: 0, height: -7))
                                } // <-ZStack
                            }
                        )
                    }
                    .keyboardShortcut(KeyEquivalent("1"))

                    NavigationLinkStore(
                        store.scope(state: \.$textCaseConverter, action: { .textCaseConverter($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.textCaseConverter))
                    } destination: { store in
                        TextCaseConverterView(store: store)
                            .navigationTitle(
                                NSLocalizedString(
                                    "Convert case of list of words",
                                    bundle: Bundle.module,
                                    comment: "navigation title on top of the window"
                                )
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: {
                                Text(
                                    NSLocalizedString(
                                        "Text Case",
                                        bundle: Bundle.module,
                                        comment: "tool name on the sidebar"
                                    )
                                )
                            },
                            icon: {
                                Text(
                                    NSLocalizedString(
                                        "Aa",
                                        bundle: Bundle.module,
                                        comment: "icon next to the tool name on the sidebar"
                                    )
                                )
                            }
                        )
                    }
                    .keyboardShortcut(KeyEquivalent("2"))

                    NavigationLinkStore(
                        store.scope(state: \.$prefixSuffix, action: { .prefixSuffix($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.prefixSuffix))
                    } destination: { store in
                        PrefixSuffixView(store: store)
                            .navigationTitle(
                                NSLocalizedString(
                                    "Change prefix or suffix of each line",
                                    bundle: Bundle.module,
                                    comment: "navigation title on top of the window"
                                )
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: {
                                Text(
                                    NSLocalizedString(
                                        "Prefix Suffix",
                                        bundle: Bundle.module,
                                        comment: "tool name on the sidebar"
                                    )
                                )
                            },
                            icon: { Image(systemName: "arrow.right.and.line.vertical.and.arrow.left") }
                        )
                    }
                    .keyboardShortcut(KeyEquivalent("3"))

                    NavigationLinkStore(
                        store.scope(state: \.$regexMatches, action: { .regexMatches($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.regexMatches))
                    } destination: { store in
                        RegexMatchesView(store: store)
                            .navigationTitle(
                                NSLocalizedString(
                                    "Regex Matches",
                                    bundle: Bundle.module,
                                    comment: "navigation title on top of the window"
                                )
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: {
                                Text(
                                    NSLocalizedString(
                                        "Regex Matches",
                                        bundle: Bundle.module,
                                        comment: "tool name on the sidebar"
                                    )
                                )
                            },
                            icon: {
                                Text(
                                    NSLocalizedString(
                                        "(.*)",
                                        bundle: Bundle.module,
                                        comment: "icon next to the tool name on the sidebar"
                                    )
                                )
                                .font(.monospaced(Font.system(size: 8))())
                            }
                        )
                    }
                }
                .keyboardShortcut(KeyEquivalent("4"))

                Section(
                    NSLocalizedString(
                        "Formatters",
                        bundle: Bundle.module,
                        comment: "sidebar section name for a group of tools"
                    )
                ) {
                    NavigationLinkStore(
                        store.scope(state: \.$jsonPretty, action: { .jsonPretty($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.jsonPretty))
                    } destination: { store in
                        JsonPrettyView(store: store)
                            .navigationTitle(
                                NSLocalizedString("Format and Highlight Json", bundle: Bundle.module, comment: "")
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: {
                                Text(
                                    NSLocalizedString(
                                        "Json",
                                        bundle: Bundle.module,
                                        comment: "sidebar name for the tool"
                                    )
                                )
                            },
                            icon: {
                                Text(
                                    NSLocalizedString(
                                        "{.,}",
                                        bundle: Bundle.module,
                                        comment: "icon next to the tool name on the sidebar"
                                    )
                                )
                                .font(.monospaced(Font.system(size: 8))())
                            }
                        )
                    }
                    .keyboardShortcut(KeyEquivalent("5"))

                    NavigationLinkStore(
                        store.scope(state: \.$swiftPrettyLockwood, action: { .swiftPrettyLockwood($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.swiftPrettyLockwood))
                    } destination: { store in
                        SwiftPrettyView(store: store)
                            .navigationTitle(
                                NSLocalizedString(
                                    "Format Swift code",
                                    bundle: Bundle.module,
                                    comment: "navigation title on top of the window"
                                )
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: {
                                Text(
                                    NSLocalizedString(
                                        "Swift",
                                        bundle: Bundle.module,
                                        comment: "sidebar name for the tool"
                                    )
                                )
                            },
                            icon: { Image(systemName: "swift") }
                        )
                    }
                    .keyboardShortcut(KeyEquivalent("6"))
                }

                #if os(macOS)

                    Section(
                        NSLocalizedString(
                            "File",
                            bundle: Bundle.module,
                            comment: "sidebar section name for a group of tools"
                        )
                    ) {
                        NavigationLinkStore(
                            store.scope(state: \.$fileContentSearch, action: { .fileContentSearch($0) })
                        ) {
                            viewStore.send(.navigationLinkTouched(.fileContentSearch))
                        } destination: { store in
                            FileContentSearchView(store: store)
                                .navigationTitle(
                                    NSLocalizedString(
                                        "Search inside files",
                                        bundle: Bundle.module,
                                        comment: "navigation title on top of the window"
                                    )
                                )
                                .padding(.top)
                        } label: {
                            Label(
                                title: {
                                    Text(
                                        NSLocalizedString(
                                            "File Search",
                                            bundle: Bundle.module,
                                            comment: "tool name on the sidebar"
                                        )
                                    )
                                },
                                icon: { Image(systemName: "doc.text.magnifyingglass") }
                            )
                        }
                        .keyboardShortcut(KeyEquivalent("7"))
                    }
                #endif

                Section(
                    NSLocalizedString(
                        "Generators",
                        bundle: Bundle.module,
                        comment: "sidebar section name for a group of tools"
                    )
                ) {
                    // NavigationLinkStore(
                    //     store.scope(state: \.$uuidGenerator, action: { .uuidGenerator($0) })
                    // ) {
                    //     viewStore.send(.navigationLinkTouched(.uuidGenerator))
                    // } destination: { store in
                    //     UUIDGeneratorView(store: store)
                    //     .navigationTitle(NSLocalizedString("Generate UUIDs", bundle: Bundle.module, comment:
                    //     "navigation title on top of the window"))
                    //     .padding(.top)
                    // } label: {
                    //                             Label(
                    //         title: { Text(NSLocalizedString("UUID", bundle: Bundle.module, comment: "icon next to the tool name on the sidebar")) },
                    //         icon: { Image(systemName: "staroflife.circle") }
                    //     )
                    // }

                    NavigationLinkStore(
                        store.scope(state: \.$nameGenerator, action: { .nameGenerator($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.nameGenerator))
                    } destination: { store in
                        NameGeneratorView(store: store)
                            .navigationTitle(
                                NSLocalizedString(
                                    "Generate names or words",
                                    bundle: Bundle.module,
                                    comment: "navigation title on top of the window"
                                )
                            )
                            .padding(.top)
                    } label: {
                        Label(
                            title: { Text(NSLocalizedString("Name", bundle: Bundle.module, comment: "")) },
                            icon: { Image(systemName: "person") }
                        )
                    }
                    .keyboardShortcut(KeyEquivalent("8"))
                }

                Button {
                    viewStore.send(.nextToolButtonTouched)
                } label: {
                    EmptyView()
                } // <-Button
                .buttonStyle(.plain)
                .keyboardShortcut(.tab, modifiers: .control)

                Button {
                    viewStore.send(.previousToolButtonTouched)
                } label: {
                    EmptyView()
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.tab, modifiers: [.control, .option])
//                .keyboardShortcut(.tab, modifiers: [.control, .shift]) // doesn't work! 😠
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150) // to keep the toggle-sidebar button above the sidebar
            .accessibilityLabel(NSLocalizedString("Sidebar with the list of tools", bundle: Bundle.module, comment: ""))
            #if os(macOS)
                // it falls behind window toolbar and becomes unclickable
                // .padding(.top)
                .toolbar {
                    ToolbarItem {
                        Button {
                            NSApp.keyWindow?.firstResponder?
                                .tryToPerform(
                                    #selector(NSSplitViewController.toggleSidebar(_:)),
                                    with: nil
                                )
                        } label: {
                            Label("Toggle sidebar", systemImage: "sidebar.left")
                        }
                        .keyboardShortcut("l", modifiers: [.command, .shift])
                        .help(NSLocalizedString("Toggle sidebar (Command+Shift+L)", bundle: Bundle.module, comment: ""))
                    }
                }
            #endif

            HStack(alignment: .center) {
                Image(systemName: "rectangle.leadinghalf.inset.filled.arrow.leading")
                Text(NSLocalizedString("Choose a tool from the Sidebar", bundle: Bundle.module, comment: ""))
            } // <-HStack

            .font(.title)
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: AppReducer.State(),
                reducer: AppReducer()
            )
        )
    }
}
