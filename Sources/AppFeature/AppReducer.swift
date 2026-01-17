import ComposableArchitecture
import FileContentSearchFeature
import HtmlToSwiftFeature
import HtmlToMarkdownFeature
import JsonPrettyFeature
import NameGeneratorFeature
import PrefixSuffixFeature
import RegexMatchesFeature
import SharedModels
import SwiftPrettyFeature
import SwiftUI
import TextCaseConverterFeature

// MARK: - Destination Reducer Enum

@Reducer
public enum Destination {
    case htmlToSwift(HtmlToSwiftReducer)
    case htmlToMarkdown(HtmlToMarkdownReducer)
    case jsonPretty(JsonPrettyReducer)
    case textCaseConverter(TextCaseConverterReducer)
    case prefixSuffix(PrefixSuffixReducer)
    case regexMatches(RegexMatchesReducer)
    case swiftPrettyLockwood(SwiftPrettyReducer)
    case nameGenerator(NameGeneratorReducer)
    #if os(macOS)
    case fileContentSearch(FileContentSearchReducer)
    #endif
}

// MARK: - App Reducer

@Reducer
public struct AppReducer {
    public init() {}

    @ObservableState
    public struct State {
        @Presents public var destination: Destination.State?

        // Derive currentTool from destination instead of separate state
        public var currentTool: Tool? {
            switch destination {
            case .htmlToSwift: return .htmlToSwift
            case .htmlToMarkdown: return .htmlToMarkdown
            case .jsonPretty: return .jsonPretty
            case .textCaseConverter: return .textCaseConverter
            case .prefixSuffix: return .prefixSuffix
            case .regexMatches: return .regexMatches
            case .swiftPrettyLockwood: return .swiftPrettyLockwood
            case .nameGenerator: return .nameGenerator
            #if os(macOS)
            case .fileContentSearch: return .fileContentSearch
            #endif
            case .none: return nil
            }
        }

        public init(destination: Destination.State? = nil) {
            self.destination = destination
        }
    }

    public enum Action {
        case destination(PresentationAction<Destination.Action>)
        case navigationLinkTouched(Tool)
        case setCurrentTool(Tool?)
        case nextToolButtonTouched
        case previousToolButtonTouched
    }

    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .destination(.presented(destinationAction)):
                return handleDestinationAction(destinationAction, state: &state)

            case let .navigationLinkTouched(tool):
                handleNavigation(tool: tool, state: &state)
                return .none

            case let .setCurrentTool(tool):
                if let tool = tool {
                    handleNavigation(tool: tool, state: &state)
                }
                return .none

            case .nextToolButtonTouched:
                handleNextToolNavigation(state: &state)
                return .none

            case .previousToolButtonTouched:
                handlePreviousToolNavigation(state: &state)
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Destination Action Handling

    private func handleDestinationAction(_ action: Destination.Action, state: inout State) -> Effect<Action> {
        switch action {
        // Standard tools with single output
        case let .htmlToSwift(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .htmlToSwift(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case let .htmlToMarkdown(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .htmlToMarkdown(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case let .jsonPretty(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .jsonPretty(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case let .textCaseConverter(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .textCaseConverter(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case let .prefixSuffix(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .prefixSuffix(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case let .swiftPrettyLockwood(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .swiftPrettyLockwood(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        // RegexMatches has TWO outputs
        case let .regexMatches(.inputOutput(.output(.outputControls(.otherToolSelected(tool))))):
            if case .regexMatches(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        case let .regexMatches(.inputOutput(.outputSecond(.outputControls(.otherToolSelected(tool))))):
            if case .regexMatches(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputSecondText, otherTool: tool, state: &state)
            }

        // Generators (output-only tools)
        case let .nameGenerator(.output(.outputControls(.otherToolSelected(tool)))):
            if case .nameGenerator(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }

        #if os(macOS)
        case let .fileContentSearch(.output(.outputControls(.otherToolSelected(tool)))):
            if case .fileContentSearch(let s) = state.destination {
                handleOtherTool(thisToolOutput: s.outputText, otherTool: tool, state: &state)
            }
        #endif

        default:
            break
        }
        return .none
    }

    // MARK: - Other Tool Navigation (Output -> Input Transfer)

    private func handleOtherTool(thisToolOutput: String?, otherTool: Tool, state: inout State) {
        let outputText = thisToolOutput ?? ""

        switch otherTool {
        case .htmlToSwift:
            state.destination = .htmlToSwift(HtmlToSwiftReducer.State())
            if case .htmlToSwift(let s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
            }
        case .htmlToMarkdown:
            state.destination = .htmlToMarkdown(HtmlToMarkdownReducer.State())
            if case .htmlToMarkdown(let s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
            }
        case .jsonPretty:
            state.destination = .jsonPretty(JsonPrettyReducer.State())
            if case .jsonPretty(let s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
            }
        case .textCaseConverter:
            state.destination = .textCaseConverter(TextCaseConverterReducer.State())
            if case .textCaseConverter(let s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
            }
        case .prefixSuffix:
            state.destination = .prefixSuffix(PrefixSuffixReducer.State())
            if case .prefixSuffix(let s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
            }
        case .regexMatches:
            state.destination = .regexMatches(RegexMatchesReducer.State())
            if case .regexMatches(var s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
                // Must also update the display text since it's a separate NSMutableAttributedString copy
                _ = s.inputOutput.input.updateText(outputText)
                state.destination = .regexMatches(s)
            }
        case .swiftPrettyLockwood:
            state.destination = .swiftPrettyLockwood(SwiftPrettyReducer.State())
            if case .swiftPrettyLockwood(let s) = state.destination {
                s.$storage.withLock { $0.input = outputText }
            }
        case .uuidGenerator:
            break // Inactive tool
        case .fileContentSearch:
            #if os(macOS)
            state.destination = .fileContentSearch(FileContentSearchReducer.State())
            #endif
        case .nameGenerator:
            state.destination = .nameGenerator(NameGeneratorReducer.State())
        }
    }

    // MARK: - Navigation Helpers

    private func handleNavigation(tool: Tool, state: inout State) {
        switch tool {
        case .htmlToSwift:
            state.destination = .htmlToSwift(HtmlToSwiftReducer.State())
        case .htmlToMarkdown:
            state.destination = .htmlToMarkdown(HtmlToMarkdownReducer.State())
        case .jsonPretty:
            state.destination = .jsonPretty(JsonPrettyReducer.State())
        case .textCaseConverter:
            state.destination = .textCaseConverter(TextCaseConverterReducer.State())
        case .prefixSuffix:
            state.destination = .prefixSuffix(PrefixSuffixReducer.State())
        case .regexMatches:
            state.destination = .regexMatches(RegexMatchesReducer.State())
        case .swiftPrettyLockwood:
            state.destination = .swiftPrettyLockwood(SwiftPrettyReducer.State())
        case .nameGenerator:
            state.destination = .nameGenerator(NameGeneratorReducer.State())
        #if os(macOS)
        case .fileContentSearch:
            state.destination = .fileContentSearch(FileContentSearchReducer.State())
        #endif
        case .uuidGenerator:
            break // Inactive tool
        }
    }

    private func handleNextToolNavigation(state: inout State) {
        guard let currentTool = state.currentTool else { return }
        let nextTool = currentTool.next()
        handleNavigation(tool: nextTool, state: &state)
    }

    private func handlePreviousToolNavigation(state: inout State) {
        guard let currentTool = state.currentTool else { return }
        let previousTool = currentTool.previous()
        handleNavigation(tool: previousTool, state: &state)
    }
}

// MARK: - App View

public struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>

    public init(store: StoreOf<AppReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem {
                Button {
                    NSApp.keyWindow?.firstResponder?
                        .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                } label: {
                    Label("Toggle sidebar", systemImage: "sidebar.left")
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .help(NSLocalizedString("Toggle sidebar (Command+Shift+L)", bundle: Bundle.module, comment: ""))
            }
        }
        #endif
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        List(selection: $store.currentTool.sending(\.setCurrentTool)) {
            Section(
                NSLocalizedString(
                    "Converters",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.htmlToSwift, label: "Html to Swift", shortcut: "1") {
                    ZStack(alignment: .leading) {
                        Image(systemName: "swift")
                            .offset(CGSize(width: 5, height: 0))
                        Text("<>")
                            .font(.monospaced(Font.system(size: 14))())
                            .fontWeight(.thin)
                            .offset(CGSize(width: 0, height: -7))
                    }
                }

                toolRow(.htmlToMarkdown, label: "HTML to Markdown", shortcut: "2") {
                    ZStack(alignment: .leading) {
                        Text("M↓")
                            .font(.monospaced(Font.system(size: 14))())
                            .fontWeight(.medium)
                            .offset(CGSize(width: 5, height: 0))
                        Text("<>")
                            .font(.monospaced(Font.system(size: 14))())
                            .fontWeight(.thin)
                            .offset(CGSize(width: 0, height: -7))
                    }
                }

                toolRow(.textCaseConverter, label: "Text Case", shortcut: "3") {
                    Text("Aa")
                }

                toolRow(.prefixSuffix, label: "Prefix Suffix", shortcut: "4") {
                    Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")
                }

                toolRow(.regexMatches, label: "Regex Matches", shortcut: "5") {
                    Text("(.*)")
                        .font(.monospaced(Font.system(size: 8))())
                }
            }

            Section(
                NSLocalizedString(
                    "Formatters",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.jsonPretty, label: "Json", shortcut: "6") {
                    Text("{.,}")
                        .font(.monospaced(Font.system(size: 8))())
                }

                toolRow(.swiftPrettyLockwood, label: "Swift", shortcut: "7") {
                    Image(systemName: "swift")
                }
            }

            #if os(macOS)
            Section(
                NSLocalizedString(
                    "File",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.fileContentSearch, label: "File Search", shortcut: "8") {
                    Image(systemName: "doc.text.magnifyingglass")
                }
            }
            #endif

            Section(
                NSLocalizedString(
                    "Generators",
                    bundle: Bundle.module,
                    comment: "sidebar section name for a group of tools"
                )
            ) {
                toolRow(.nameGenerator, label: "Name", shortcut: "9") {
                    Image(systemName: "person")
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150)
        .accessibilityLabel(NSLocalizedString("Sidebar with the list of tools", bundle: Bundle.module, comment: ""))
        .overlay {
            // Hidden buttons for keyboard navigation
            Button {
                store.send(.nextToolButtonTouched)
            } label: {
                EmptyView()
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.tab, modifiers: .control)

            Button {
                store.send(.previousToolButtonTouched)
            } label: {
                EmptyView()
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.tab, modifiers: [.control, .option])
        }
    }

    // MARK: - Tool Row Helper

    @ViewBuilder
    private func toolRow<Icon: View>(
        _ tool: Tool,
        label: String,
        shortcut: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Label {
            Text(NSLocalizedString(label, bundle: Bundle.module, comment: "tool name on the sidebar"))
        } icon: {
            icon()
        }
        .tag(tool)
        .keyboardShortcut(KeyEquivalent(Character(shortcut)))
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if let store = store.scope(state: \.destination, action: \.destination.presented) {
            switch store.case {
            case .htmlToSwift(let childStore):
                HtmlToSwiftView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert Html code to a DSL in Swift",
                            bundle: Bundle.module,
                            comment: "a navigationTitle"
                        )
                    )
                    .padding(.top)

            case .htmlToMarkdown(let childStore):
                HtmlToMarkdownView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert HTML to Markdown",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .jsonPretty(let childStore):
                JsonPrettyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Format and Highlight Json",
                            bundle: Bundle.module,
                            comment: "navigation title"
                        )
                    )
                    .padding(.top)

            case .textCaseConverter(let childStore):
                TextCaseConverterView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Convert case of list of words",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .prefixSuffix(let childStore):
                PrefixSuffixView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Change prefix or suffix of each line",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .regexMatches(let childStore):
                RegexMatchesView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Regex Matches",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .swiftPrettyLockwood(let childStore):
                SwiftPrettyView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Format Swift code",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            case .nameGenerator(let childStore):
                NameGeneratorView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Generate names or words",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)

            #if os(macOS)
            case .fileContentSearch(let childStore):
                FileContentSearchView(store: childStore)
                    .navigationTitle(
                        NSLocalizedString(
                            "Search inside files",
                            bundle: Bundle.module,
                            comment: "navigation title on top of the window"
                        )
                    )
                    .padding(.top)
            #endif
            }
        } else {
            HomeStartView()
        }
    }
}

// MARK: - Preview

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: Store(initialState: AppReducer.State()) {
                AppReducer()
            }
        )
    }
}
