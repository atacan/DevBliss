import BlissTheme
import ComposableArchitecture
import InputOutput
import LineSortDedupeClient
import SharedModels
import SwiftUI

@Reducer
public struct LineSortDedupeReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("lineSortDedupe")) public var inputText = ""
        @Shared(.toolOutput("lineSortDedupe")) public var outputText = ""
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var sortOrder: LineSortOrder = .ascending
        var removeDuplicates: Bool = true
        var caseInsensitive: Bool = true
        var trimWhitespace: Bool = true
        var removeEmptyLines: Bool = true

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("lineSortDedupe"))
            let outputText = Shared(wrappedValue: "", .toolOutput("lineSortDedupe"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("lineSortDedupe"))
            let outputText = Shared(wrappedValue: output, .toolOutput("lineSortDedupe"))
            self._inputText = inputText
            self._outputText = outputText
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: inputText.projectedValue,
                outputText: outputText.projectedValue
            )
        }

        var config: LineSortDedupeConfig {
            LineSortDedupeConfig(
                sortOrder: sortOrder,
                removeDuplicates: removeDuplicates,
                caseInsensitive: caseInsensitive,
                trimWhitespace: trimWhitespace,
                removeEmptyLines: removeEmptyLines
            )
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<String>)
        case inputOutput(InputOutputEditorsReducer.Action)
    }

    @Dependency(\.lineSortDedupe) var lineSortDedupe
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .convertButtonTouched:
                state.isConversionRequestInFlight = true
                let input = state.inputOutput.input.text
                let config = state.config
                return .run { [lineSortDedupe] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await lineSortDedupe.convert(input, config)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(result)
                    .map { Action.inputOutput(.output($0)) }

            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                return state.inputOutput.output.updateText(error.localizedDescription)
                    .map { Action.inputOutput(.output($0)) }

            case .inputOutput:
                return .none
            }
        }

        Scope(state: \.inputOutput, action: \.inputOutput) {
            InputOutputEditorsReducer()
        }
    }
}

public struct LineSortDedupeView: View {
    @Bindable var store: StoreOf<LineSortDedupeReducer>

    public init(store: StoreOf<LineSortDedupeReducer>) {
        self.store = store
    }

    // MARK: - Reusable Controls

    private var sortOrderPicker: some View {
        Picker("Order", selection: $store.sortOrder) {
            ForEach(LineSortOrder.allCases) { order in
                Text(order.rawValue)
                    .tag(order)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var caseInsensitiveToggle: some View {
        Toggle("Case-insensitive", isOn: $store.caseInsensitive)
    }

    private var trimWhitespaceToggle: some View {
        Toggle("Trim whitespace", isOn: $store.trimWhitespace)
    }

    private var removeDuplicatesToggle: some View {
        Toggle("Remove duplicates", isOn: $store.removeDuplicates)
    }

    private var removeEmptyLinesToggle: some View {
        Toggle("Remove empty lines", isOn: $store.removeEmptyLines)
    }

    private var processButton: some View {
        LoadingButton("Process", isLoading: store.isConversionRequestInFlight) {
            store.send(.convertButtonTouched)
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Process (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                sortOrderPicker
                caseInsensitiveToggle
                trimWhitespaceToggle
                removeDuplicatesToggle
                removeEmptyLinesToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            processButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Sort by")
                    sortOrderPicker
                        .frame(width: 200)
                    caseInsensitiveToggle
                        .toggleStyle(.checkbox)
                    trimWhitespaceToggle
                        .toggleStyle(.checkbox)
                }

                GridRow {
                    ConfigLabel("Options")
                    removeDuplicatesToggle
                        .toggleStyle(.checkbox)
                    removeEmptyLinesToggle
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            processButton
                .padding(.vertical, 8)
            #endif

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "Input",
                outputEditorTitle: "Output",
                keyForFraction: SettingsKey.LineSortDedupe.splitViewFraction,
                keyForLayout: SettingsKey.LineSortDedupe.splitViewLayout
            )
        }
    }
}

struct LineSortDedupeView_Previews: PreviewProvider {
    static var previews: some View {
        LineSortDedupeView(store: .init(initialState: .init()) { LineSortDedupeReducer() })
    }
}
