import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SvgToCssClient
import SwiftUI

@Reducer
public struct SvgToCssReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.svgToCssIO) public var storage = ToolIOStorage()
        var inputOutput: InputOutputEditorsReducer.State
        var isConversionRequestInFlight = false
        var includeDataPrefix: Bool = true
        var wrapWithCss: Bool = true

        public init() {
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .svgToCssIO)
            self.inputOutput = InputOutputEditorsReducer.State(
                inputText: _storage.projectedValue.input,
                outputText: _storage.projectedValue.output
            )
        }

        var config: SvgToCssConfig {
            SvgToCssConfig(includeDataPrefix: includeDataPrefix, wrapWithCss: wrapWithCss)
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

    @Dependency(\.svgToCss) var svgToCss
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
                return .run { [svgToCss] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await svgToCss.convert(input, config)
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

public struct SvgToCssView: View {
    @Bindable var store: StoreOf<SvgToCssReducer>

    public init(store: StoreOf<SvgToCssReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Options")
                    Toggle("Include data: prefix", isOn: $store.includeDataPrefix)
                        .toggleStyle(.checkbox)

                    Toggle("Wrap in CSS", isOn: $store.wrapWithCss)
                        .toggleStyle(.checkbox)

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton("Convert", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            Divider()

            InputOutputEditorsView(
                store: store.scope(state: \.inputOutput, action: \.inputOutput),
                inputEditorTitle: "SVG",
                outputEditorTitle: "CSS",
                keyForFraction: SettingsKey.SvgToCss.splitViewFraction,
                keyForLayout: SettingsKey.SvgToCss.splitViewLayout
            )
        }
    }
}

struct SvgToCssView_Previews: PreviewProvider {
    static var previews: some View {
        SvgToCssView(store: .init(initialState: .init()) { SvgToCssReducer() })
    }
}
