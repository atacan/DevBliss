import ComposableArchitecture
import HtmlToSwiftFeature
import JsonPrettyFeature
import SharedModels
import SwiftUI
import TextCaseConverterFeature

public struct AppReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        // var normal_htmlToSwift: HtmlToSwiftReducer.State
        // var normal_jsonPretty: JsonPrettyReducer.State
        @PresentationState var htmlToSwift: HtmlToSwiftReducer.State?
        @PresentationState var jsonPretty: JsonPrettyReducer.State?
        @PresentationState var textCaseConverter: TextCaseConverterReducer.State?

        public init(
            // normal_htmlToSwift: HtmlToSwiftReducer.State = .init(),
            // normal_jsonPretty: JsonPrettyReducer.State = .init(),
            htmlToSwift: HtmlToSwiftReducer.State? = nil,
            jsonPretty: JsonPrettyReducer.State? = nil,
            textCaseConverter: TextCaseConverterReducer.State? = nil
        ) {
            // // self.normal_htmlToSwift = normal_htmlToSwift
            // // self.normal_jsonPretty = normal_jsonPretty
            self.htmlToSwift = htmlToSwift
            self.jsonPretty = jsonPretty
            self.textCaseConverter = textCaseConverter
        }
    }

    public enum Action: Equatable {
        // case normal_htmlToSwift(HtmlToSwiftReducer.Action)
        // case normal_jsonPretty(JsonPrettyReducer.Action)
        case htmlToSwift(PresentationAction<HtmlToSwiftReducer.Action>)
        case jsonPretty(PresentationAction<JsonPrettyReducer.Action>)
        case textCaseConverter(PresentationAction<TextCaseConverterReducer.Action>)
        case navigationLinkTouched(Tool)
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            //            case .normal_htmlToSwift(.inputOutput(.output(.outputControls(.saveAsButtonTouched)))):
            //                state.jsonPretty = .init()
            //                return .none
            //            case .normal_jsonPretty(.inputOutput(.output(.outputControls(.saveAsButtonTouched)))):
            //                state.normal_htmlToSwift = .init()
            //                return .none

            // case .normal_htmlToSwift:
            //     return .none
            // case .normal_jsonPretty:
            //     return .none
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
            case .htmlToSwift:
                return .none
            case .jsonPretty:
                return .none
            case .textCaseConverter:
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

//        Scope(state: \.normal_htmlToSwift, action: /Action.normal_htmlToSwift) {
//            HtmlToSwiftReducer()
//        }
//        Scope(state: \.normal_jsonPretty, action: /Action.normal_jsonPretty) {
//            JsonPrettyReducer()
//        }
    }

    private func handleOtherTool(thisTool: Tool, otherTool: Tool, state: inout State) {
        switch (thisTool, otherTool) {
        case (.htmlToSwift, .jsonPretty):
            state.jsonPretty = JsonPrettyReducer.State(input: state.htmlToSwift?.outputText ?? "")
        case (.htmlToSwift, .textCaseConverter):
            state.textCaseConverter = TextCaseConverterReducer.State(input: state.htmlToSwift?.outputText ?? "")
        case (.jsonPretty, .htmlToSwift):
            state.htmlToSwift = HtmlToSwiftReducer.State(input: state.jsonPretty?.outputText ?? "")
        case (.jsonPretty, .textCaseConverter):
            state.textCaseConverter = TextCaseConverterReducer.State(input: state.jsonPretty?.outputText ?? "")
        case (.textCaseConverter, .htmlToSwift):
            state.htmlToSwift = HtmlToSwiftReducer.State(input: state.textCaseConverter?.outputText ?? "")
        case (.textCaseConverter, .jsonPretty):
            state.jsonPretty = JsonPrettyReducer.State(input: state.textCaseConverter?.outputText ?? "")
        default:
            return
        }
//        case .htmlToSwift:
//            state.htmlToSwift = HtmlToSwiftReducer.State.init(input: state.htmlToSwift?.outputText ?? "")
//        case .jsonPretty:
//            state.jsonPretty = JsonPrettyReducer.State.init(input: state.htmlToSwift?.outputText ?? "")
//        case .textCaseConverter:
//            state.textCaseConverter = TextCaseConverterReducer.State.init(input: state.jsonPretty?.outputText ?? "")
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
                NavigationLinkStore(
                    store.scope(state: \.$htmlToSwift, action: { .htmlToSwift($0) })
                ) {
                    viewStore.send(.navigationLinkTouched(.htmlToSwift))
                } destination: { store in
                    HtmlToSwiftView(store: store)
                } label: {
                    Text("Html to Swift")
                }

                NavigationLinkStore(
                    store.scope(state: \.$jsonPretty, action: { .jsonPretty($0) })
                ) {
                    viewStore.send(.navigationLinkTouched(.jsonPretty))
                } destination: { store in
                    JsonPrettyView(store: store)
                } label: {
                    Text("Json Format")
                }

                NavigationLinkStore(
                    store.scope(state: \.$textCaseConverter, action: { .textCaseConverter($0) })
                ) {
                    viewStore.send(.navigationLinkTouched(.textCaseConverter))
                } destination: { store in
                    TextCaseConverterView(store: store)
                } label: {
                    Text("Text Case Converter")
                }

                // NavigationLink(
                //     "Basics",
                //     destination: HtmlToSwiftView(

                //         store: self.store.scope(
                //             state: \.normal_htmlToSwift,
                //             action: AppReducer.Action.normal_htmlToSwift
                //         )
                //     )
                // )

                // NavigationLink(
                //     "normal json pretty",
                //     destination: JsonPrettyView(
                //         store: self.store.scope(
                //             state: \.normal_jsonPretty,
                //             action: AppReducer.Action.normal_jsonPretty
                //         )
                //     )
                // )
            }
            .listStyle(.sidebar)

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