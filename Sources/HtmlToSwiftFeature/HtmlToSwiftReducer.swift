import BlissTheme
import ComposableArchitecture
import Dependencies
import DependenciesAdditions
import Foundation
import HtmlSwift
import HtmlToSwiftClient
import InputOutput
import SharedModels
import SwiftUI
import SyntaxHighlightClient

@Reducer
public struct HtmlToSwiftReducer {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        @Shared(.htmlToSwiftIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputAttributedEditorsReducer.State
        var isConversionRequestInFlight = false
        var dsl: SwiftDSL = .binaryBirds
        var component: HtmlOutputComponent = .fullHtml

        public init(
            inputOutput: InputOutputAttributedEditorsReducer.State = .init(),
            dsl: SwiftDSL = .binaryBirds,
            component: HtmlOutputComponent = .fullHtml
        ) {
            self.inputOutput = inputOutput
            self.dsl = dsl
            self.component = component
        }

        public init(inputOutput: InputOutputAttributedEditorsReducer.State = .init()) {
            self.inputOutput = inputOutput
        }

        public init() {
            // Explicitly initialize storage first
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(), .htmlToSwiftIO)
            self._storage = sharedStorage
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: sharedStorage.input,
                outputRawText: sharedStorage.output
            )
            // Config (dsl, component) loaded via observeSettings action
        }

        public init(input: String, output: String = "") {
            // Explicitly initialize storage with provided values
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .htmlToSwiftIO)
            self._storage = sharedStorage
            self.inputOutput = InputOutputAttributedEditorsReducer.State(
                inputText: sharedStorage.input,
                outputRawText: sharedStorage.output
            )
        }

        public var outputText: String {
            inputOutput.output.text.string
        }
    }

    public enum Action: BindableAction, Equatable {
        case observeSettings
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<NSAttributedString>)
        case inputOutput(InputOutputAttributedEditorsReducer.Action)
    }

    @Dependency(\.htmlToSwift) var htmlToSwift
    @Dependency(\.syntaxHighlight) var syntaxHighlight
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
                                    // First convert HTML to Swift
                                    let swiftCode = try await htmlToSwift.convert(input.text, for: dsl, output: component)
                                    // Then highlight the Swift code
                                    let highlighted = await syntaxHighlight.highlightSwift(swiftCode)
                                    return highlighted
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(highlightedCode)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(highlightedCode)
                    .map { Action.inputOutput(.output($0)) }
            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(errorAttributedString(error.localizedDescription))
                    .map { Action.inputOutput(.output($0)) }
            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: \.inputOutput) {
            InputOutputAttributedEditorsReducer()
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
    @Bindable var store: StoreOf<HtmlToSwiftReducer>

    public init(store: StoreOf<HtmlToSwiftReducer>) {
        self.store = store
    }

    #if os(iOS)
        private let pickerTitleSpace: CGFloat = 0
    #elseif os(macOS)
        private let pickerTitleSpace: CGFloat = 4
    #endif

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""),
                        selection: $store.dsl
                    ) {
                        ForEach(SwiftDSL.allCases) { dsl in
                            Text(dslLibraryName(for: dsl))
                                .tag(dsl)
                        }
                    }
                    .blissMenuPicker(width: 180)

                    ConfigLabel(NSLocalizedString("Component", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("Component", bundle: Bundle.module, comment: ""),
                        selection: $store.component
                    ) {
                        ForEach(HtmlOutputComponent.allCases) { component in
                            Text(outputComponentPickerName(for: component))
                                .tag(component)
                        }
                    }
                    .blissMenuPicker(width: 160)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton(
                NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
                isLoading: store.isConversionRequestInFlight
            ) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Convert code (⌘ Return)", bundle: Bundle.module, comment: ""))
            .padding(.vertical, 8)

            Divider()

            InputOutputAttributedEditorsView(
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
