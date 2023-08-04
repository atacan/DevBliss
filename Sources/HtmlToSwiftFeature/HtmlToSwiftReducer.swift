import ComposableArchitecture
import Dependencies
import HtmlSwift
import HtmlToSwiftClient
import InputOutput
import SwiftUI

public struct HtmlToSwiftReducer: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        @BindingState var dsl: SwiftDSL = .binaryBirds
        @BindingState var component: HtmlOutputComponent = .fullHtml

        public init(inputOutput: InputOutputEditorsReducer.State = .init()) {
            self.inputOutput = inputOutput
        }

        public init(input: String, output: String = "") {
            self.inputOutput = .init(input: .init(text: input), output: .init(text: output))
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
    }

    @Dependency(\.htmlToSwift) var htmlToSwift
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
                    .run { [input = state.inputOutput.input, dsl = state.dsl, component = state.component] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await htmlToSwift.convert(input.text, for: dsl, output: component)
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
            case .conversionResponse(.failure):
                state.isConversionRequestInFlight = false
                return .none
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputEditorsReducer()
        }
    }
}

public struct HtmlToSwiftView: View {
    let store: StoreOf<HtmlToSwiftReducer>
    @ObservedObject var viewStore: ViewStoreOf<HtmlToSwiftReducer>

    public init(store: StoreOf<HtmlToSwiftReducer>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    #if os(iOS)
    private let pickerTitleSpace: CGFloat = 0
    #elseif os(macOS)
    private let pickerTitleSpace: CGFloat = 4
    #endif

    public var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center, spacing: pickerTitleSpace) {
                    Text(NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""))
                Picker(NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""), selection: viewStore.binding(\.$dsl)) {
                                    ForEach(SwiftDSL.allCases) { dsl in
                                        Text(dslLibraryName(for: dsl))
                                            .tag(dsl)
                                    }
                                }
                } // <-VStack
                VStack(alignment: .center, spacing: pickerTitleSpace) {
                    Text(NSLocalizedString("Component", bundle: Bundle.module, comment: ""))
                Picker(NSLocalizedString("Component", bundle: Bundle.module, comment: ""), selection: viewStore.binding(\.$component)) {
                    ForEach(HtmlOutputComponent.allCases) { component in
                        Text(outputComponentPickerName(for: component))
                            .tag(component)
                    }
                }
                }
                Spacer()
            }  // <-HStack
            .frame(maxWidth: 450)
            .labelsHidden()

            Button(action: { viewStore.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Convert", bundle: Bundle.module, comment: ""))
                    .overlay(viewStore.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .padding(.bottom, 2)

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: HtmlToSwiftReducer.Action.inputOutput),
                inputEditorTitle: "Html",
                outputEditorTitle: "Swift"
            )
        }
    }

    private func dslLibraryName(for dsl: SwiftDSL) -> String {
        switch dsl {
        case .binaryBirds:
            return NSLocalizedString("Binary Birds", bundle: Bundle.module, comment: "picker description for which dsl library to use. don't translate.")
        case .pointFree:
            return NSLocalizedString("Point﹒Free", bundle: Bundle.module, comment: "picker description for which dsl library to use. don't translate.")
        }
    }
    
    private func outputComponentPickerName(for component: HtmlOutputComponent) -> String{
        switch component {
        case .fullHtml:
            return NSLocalizedString("Full <html>", bundle: Bundle.module, comment: "picker description for which html component to output")
        case .onlyBody:
            return NSLocalizedString("Only <body>", bundle: Bundle.module, comment: "picker description for which html component to output")
        case .onlyHead:
            return NSLocalizedString("Only <head>", bundle: Bundle.module, comment: "picker description for which html component to output")
        }
    }
}

// preview
struct HtmlToSwiftReducer_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToSwiftView(store: .init(initialState: .init(), reducer: HtmlToSwiftReducer()))
    }
}
