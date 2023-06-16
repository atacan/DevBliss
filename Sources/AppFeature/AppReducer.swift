import ComposableArchitecture
import HtmlToSwiftFeature
import JsonPrettyFeature
import SharedModels
import SwiftUI
import TextCaseConverterFeature
import UUIDGeneratorFeature
import PrefixSuffixFeature

public struct AppReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        @PresentationState var htmlToSwift: HtmlToSwiftReducer.State?
        @PresentationState var jsonPretty: JsonPrettyReducer.State?
        @PresentationState var textCaseConverter: TextCaseConverterReducer.State?
        @PresentationState var uuidGenerator: UUIDGeneratorReducer.State?
        @PresentationState var prefixSuffix: PrefixSuffixReducer.State?

        public init(
            htmlToSwift: HtmlToSwiftReducer.State? = nil,
            jsonPretty: JsonPrettyReducer.State? = nil,
            textCaseConverter: TextCaseConverterReducer.State? = nil,
            uuidGenerator: UUIDGeneratorReducer.State? = nil,
            prefixSuffix: PrefixSuffixReducer.State? = nil
        ) {
            self.htmlToSwift = htmlToSwift
            self.jsonPretty = jsonPretty
            self.textCaseConverter = textCaseConverter
            self.uuidGenerator = uuidGenerator
            self.prefixSuffix = prefixSuffix
        }
    }

    public enum Action: Equatable {
        case htmlToSwift(PresentationAction<HtmlToSwiftReducer.Action>)
        case jsonPretty(PresentationAction<JsonPrettyReducer.Action>)
        case textCaseConverter(PresentationAction<TextCaseConverterReducer.Action>)
        case uuidGenerator(PresentationAction<UUIDGeneratorReducer.Action>)
        case prefixSuffix(PresentationAction<PrefixSuffixReducer.Action>)
        case navigationLinkTouched(Tool)
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .htmlToSwift(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisTool: .htmlToSwift, otherTool: otherTool, state: &state)
                return .none
            case let .jsonPretty(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisTool: .jsonPretty, otherTool: otherTool, state: &state)
                return .none
            case let .textCaseConverter(
                .presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))
            ):
                handleOtherTool(thisTool: .textCaseConverter, otherTool: otherTool, state: &state)
                return .none
            case let .uuidGenerator(
                .presented(.output(.outputControls(.inputOtherToolButtonTouched(otherTool))))
            ):
                handleOtherTool(thisTool: .uuidGenerator, otherTool: otherTool, state: &state)
                return .none
            case let .prefixSuffix(.presented(.inputOutput(.output(.outputControls(.inputOtherToolButtonTouched(otherTool)))))):
                handleOtherTool(thisTool: .prefixSuffix, otherTool: otherTool, state: &state)
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
    }

    private func handleOtherTool(thisTool: Tool, otherTool: Tool, state: inout State) {
        switch (thisTool, otherTool) {
        //
        case (.htmlToSwift, .jsonPretty):
            state.jsonPretty = JsonPrettyReducer.State(input: state.htmlToSwift?.outputText ?? "")
        case (.htmlToSwift, .textCaseConverter):
            state.textCaseConverter = TextCaseConverterReducer.State(input: state.htmlToSwift?.outputText ?? "")
        case (.htmlToSwift, .prefixSuffix):
            state.prefixSuffix = PrefixSuffixReducer.State(input: state.htmlToSwift?.outputText ?? "")
        //
        case (.jsonPretty, .htmlToSwift):
            state.htmlToSwift = HtmlToSwiftReducer.State(input: state.jsonPretty?.outputText ?? "")
        case (.jsonPretty, .textCaseConverter):
            state.textCaseConverter = TextCaseConverterReducer.State(input: state.jsonPretty?.outputText ?? "")
        case (.jsonPretty, .prefixSuffix):
            state.prefixSuffix = PrefixSuffixReducer.State(input: state.jsonPretty?.outputText ?? "")
        //
        case (.textCaseConverter, .htmlToSwift):
            state.htmlToSwift = HtmlToSwiftReducer.State(input: state.textCaseConverter?.outputText ?? "")
        case (.textCaseConverter, .jsonPretty):
            state.jsonPretty = JsonPrettyReducer.State(input: state.textCaseConverter?.outputText ?? "")
        case (.textCaseConverter, .prefixSuffix):
            state.prefixSuffix = PrefixSuffixReducer.State(input: state.textCaseConverter?.outputText ?? "")
        //
        case (.uuidGenerator, .htmlToSwift):
            state.htmlToSwift = HtmlToSwiftReducer.State(input: state.uuidGenerator?.outputText ?? "")
        case (.uuidGenerator, .jsonPretty):
            state.jsonPretty = JsonPrettyReducer.State(input: state.uuidGenerator?.outputText ?? "")
        case (.uuidGenerator, .textCaseConverter):
            state.textCaseConverter = TextCaseConverterReducer.State(input: state.uuidGenerator?.outputText ?? "")
        case (.uuidGenerator, .prefixSuffix):
            state.prefixSuffix = PrefixSuffixReducer.State(input: state.uuidGenerator?.outputText ?? "")
        //
        case (.prefixSuffix, .htmlToSwift):
            state.htmlToSwift = HtmlToSwiftReducer.State(input: state.prefixSuffix?.outputText ?? "")
        case (.prefixSuffix, .jsonPretty):
            state.jsonPretty = JsonPrettyReducer.State(input: state.prefixSuffix?.outputText ?? "")
        case (.prefixSuffix, .textCaseConverter):
            state.textCaseConverter = TextCaseConverterReducer.State(input: state.prefixSuffix?.outputText ?? "")
        
        default:
            return
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
            .frame(minWidth: 150) // to keep the toggle-sidebar button above the sidebar
            #if os(macOS)
                // it falls behind window toolbar and becomes unclickable
                // .padding(.top)
                .toolbar {
                    ToolbarItem {
                        Button {
                            NSApp.keyWindow?.firstResponder?.tryToPerform(
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
