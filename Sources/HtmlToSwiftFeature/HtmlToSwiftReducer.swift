import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import HtmlSwift
import HtmlToSwiftClient
import InputOutput
import SharedModels
import SwiftUI

@Reducer
public struct HtmlToSwiftReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var dsl: SwiftDSL = .binaryBirds
        var component: HtmlOutputComponent = .fullHtml

        public init(
            inputOutput: InputOutputEditorsReducer.State = .init(),
            dsl: SwiftDSL = .binaryBirds,
            component: HtmlOutputComponent = .fullHtml
        ) {
            self.inputOutput = inputOutput
            self.dsl = dsl
            self.component = component
        }

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
        case observeSettings
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.htmlToSwift) var htmlToSwift
    private enum CancelID { case conversionRequest }
    @Dependency(\.userDefaults) var userDefaults

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .observeSettings:
                return observeSettings(&state)
            case let .binding(action):
                return setPreferences(for: action, from: state)
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
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(error.localizedDescription)
                    .map { Action.inputOutput(.output($0)) }
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: /Action.inputOutput) {
            InputOutputEditorsReducer()
        }
    }

    private func observeSettings(_ state: inout State) -> Effect<Action> {
        if let newDsl: SwiftDSL = userDefaults.rawRepresentable(forKey: SettingsKey.HtmlToSwift.dsl) {
            state.dsl = newDsl
        }
        if let newComponent: HtmlOutputComponent =
            userDefaults
            .rawRepresentable(forKey: SettingsKey.HtmlToSwift.component)
        {
            state.component = newComponent
        }
        return .none
    }

    private func setPreferences(for action: BindingAction<State>, from state: State) -> Effect<Action> {
        // Store preferences whenever bindings change
        userDefaults.set(state.dsl, forKey: SettingsKey.HtmlToSwift.dsl)
        userDefaults.set(state.component, forKey: SettingsKey.HtmlToSwift.component)
        return .none
    }
}

public struct HtmlToSwiftView: View {
    @Perception.Bindable var store: StoreOf<HtmlToSwiftReducer>

    public init(store: StoreOf<HtmlToSwiftReducer>) {
        self.store = store
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
                     Picker(
                         NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""),
                         selection: $store.dsl
                     ) {
                         ForEach(SwiftDSL.allCases) { dsl in
                             Text(dslLibraryName(for: dsl))
                                 .tag(dsl)
                         }
                     }
                 }  // <-VStack
                 VStack(alignment: .center, spacing: pickerTitleSpace) {
                     Text(NSLocalizedString("Component", bundle: Bundle.module, comment: ""))
                     Picker(
                         NSLocalizedString("Component", bundle: Bundle.module, comment: ""),
                         selection: $store.component
                     ) {
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

            Button(action: { store.send(.convertButtonTouched) }) {
                Text(NSLocalizedString("Convert", bundle: Bundle.module, comment: ""))
                    .overlay(store.isConversionRequestInFlight ? ProgressView() : nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Convert code (Cmd+Return)", bundle: Bundle.module, comment: ""))
            .padding(.bottom, 2)

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: HtmlToSwiftReducer.Action.inputOutput),
                inputEditorTitle: "Html",
                outputEditorTitle: "Swift",
                keyForFraction: SettingsKey.HtmlToSwift.splitViewFraction,
                keyForLayout: SettingsKey.HtmlToSwift.splitViewLayout
            )
        }
        .onAppear {
            store.send(.observeSettings)
        }
    }

    private func dslLibraryName(for dsl: SwiftDSL) -> String {
        switch dsl {
        case .binaryBirds:
            return NSLocalizedString(
                "Binary Birds",
                bundle: Bundle.module,
                comment: "picker description for which dsl library to use. don't translate."
            )
        case .pointFree:
            return NSLocalizedString(
                "Point﹒Free",
                bundle: Bundle.module,
                comment: "picker description for which dsl library to use. don't translate."
            )
        }
    }

    private func outputComponentPickerName(for component: HtmlOutputComponent) -> String {
        switch component {
        case .fullHtml:
            return NSLocalizedString(
                "Full <html>",
                bundle: Bundle.module,
                comment: "picker description for which html component to output"
            )
        case .onlyBody:
            return NSLocalizedString(
                "Only <body>",
                bundle: Bundle.module,
                comment: "picker description for which html component to output"
            )
        case .onlyHead:
            return NSLocalizedString(
                "Only <head>",
                bundle: Bundle.module,
                comment: "picker description for which html component to output"
            )
        }
    }
}

// preview
struct HtmlToSwiftReducer_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToSwiftView(store: .init(initialState: .init()) { HtmlToSwiftReducer() })
    }
}

#if DEBUG
    public struct HtmlToSwiftApp: App {
        public init() {}

        public var body: some Scene {
            WindowGroup {
                HtmlToSwiftView(
                    store: Store(
                        initialState: .init()
                    ) {
                        HtmlToSwiftReducer()
                            ._printChanges()
                    }
                )
            }
            #if os(macOS)
                .windowStyle(.titleBar)
                .windowToolbarStyle(.unified(showsTitle: true))
            #endif
        }
    }

#endif
