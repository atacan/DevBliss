import ComposableArchitecture
import HtmlToSwiftFeature
import JsonPrettyFeature
import PrefixSuffixFeature
import RegexMatchesFeature
import SharedModels
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

        public init(
            htmlToSwift: HtmlToSwiftReducer.State? = nil,
            jsonPretty: JsonPrettyReducer.State? = nil,
            textCaseConverter: TextCaseConverterReducer.State? = nil,
            uuidGenerator: UUIDGeneratorReducer.State? = nil,
            prefixSuffix: PrefixSuffixReducer.State? = nil,
            regexMatches: RegexMatchesReducer.State? = nil
        ) {
            self.htmlToSwift = htmlToSwift
            self.jsonPretty = jsonPretty
            self.textCaseConverter = textCaseConverter
            self.uuidGenerator = uuidGenerator
            self.prefixSuffix = prefixSuffix
            self.regexMatches = regexMatches
        }
    }

    public enum Action: Equatable {
        case htmlToSwift(PresentationAction<HtmlToSwiftReducer.Action>)
        case jsonPretty(PresentationAction<JsonPrettyReducer.Action>)
        case textCaseConverter(PresentationAction<TextCaseConverterReducer.Action>)
        case uuidGenerator(PresentationAction<UUIDGeneratorReducer.Action>)
        case prefixSuffix(PresentationAction<PrefixSuffixReducer.Action>)
        case regexMatches(PresentationAction<RegexMatchesReducer.Action>)
        case navigationLinkTouched(Tool)
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
                handleOtherTool(thisToolOutput: state.textCaseConverter?.outputText, otherTool: otherTool, state: &state)
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
                handleOtherTool(thisToolOutput: state.regexMatches?.outputSecondText, otherTool: otherTool, state: &state)
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

            case let .navigationLinkTouched(tool):
                switch tool {
                case .htmlToSwift:
                    state.htmlToSwift = .init()
                    return .none
                case .jsonPretty:
                    state.jsonPretty = .init()
                    return .none
                case .textCaseConverter:
                    state.textCaseConverter = .init()
                    return .none
                case .uuidGenerator:
                    state.uuidGenerator = .init()
                    return .none
                case .prefixSuffix:
                    state.prefixSuffix = .init()
                    return .none
                case .regexMatches:
                    state.regexMatches = .init()
                    return .none
                }
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
    }

    private func handleOtherTool(thisToolOutput: String?, otherTool: Tool, state: inout State) {
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
        }

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
                Section("Converters") {
                    NavigationLinkStore(
                        store.scope(state: \.$htmlToSwift, action: { .htmlToSwift($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.htmlToSwift))
                    } destination: { store in
                        HtmlToSwiftView(store: store)
                        .navigationTitle("Convert Html code to a DSL in Swift")
                        .padding(.top)
                    } label: {
                        Text("Html to Swift")
                    }

                    NavigationLinkStore(
                        store.scope(state: \.$textCaseConverter, action: { .textCaseConverter($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.textCaseConverter))
                    } destination: { store in
                        TextCaseConverterView(store: store)
                        .navigationTitle("Convert case of list of words")
                        .padding(.top)
                    } label: {
                        Text("Text Case")
                    }

                    NavigationLinkStore(
                        store.scope(state: \.$prefixSuffix, action: { .prefixSuffix($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.prefixSuffix))
                    } destination: { store in
                        PrefixSuffixView(store: store)
                        .navigationTitle("Replace and add prefix or suffix to each line")
                        .padding(.top)
                    } label: {
                        Text("Prefix Suffix")
                    }

                    NavigationLinkStore(
                        store.scope(state: \.$regexMatches, action: { .regexMatches($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.regexMatches))
                    } destination: { store in
                        RegexMatchesView(store: store)
                        .navigationTitle("Regex Matches")
                        .padding(.top)
                    } label: {
                        Text("Regex Matches")
                    }
                }

                Section("Formatters") {
                    NavigationLinkStore(
                        store.scope(state: \.$jsonPretty, action: { .jsonPretty($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.jsonPretty))
                    } destination: { store in
                        JsonPrettyView(store: store)
                        .navigationTitle("Pretty print and Highlight Json")
                        .padding(.top)
                    } label: {
                        Text("Json")
                    }
                }

                Section("Generators") {
                    NavigationLinkStore(
                        store.scope(state: \.$uuidGenerator, action: { .uuidGenerator($0) })
                    ) {
                        viewStore.send(.navigationLinkTouched(.uuidGenerator))
                    } destination: { store in
                        UUIDGeneratorView(store: store)
                        .navigationTitle("Generate UUIDs")
                        .padding(.top)
                    } label: {
                        Text("UUID")
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)  // to keep the toggle-sidebar button above the sidebar
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
                        .help("Toggle sidebar (Command+Shift+L)")
                    }
                }
            #endif

            Text(
                "\(Image(systemName: "rectangle.leadinghalf.inset.filled.arrow.leading"))  Choose a tool from the Sidebar"
            )
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
