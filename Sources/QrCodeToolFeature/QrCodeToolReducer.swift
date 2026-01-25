import BlissTheme
import ComposableArchitecture
import InputOutput
import QRCode
import QrCodeToolClient
import SharedModels
import SplitView
import SwiftUI

@Reducer
public struct QrCodeToolReducer {
    public init() {}

    public enum Mode: String, CaseIterable, Identifiable {
        case generate = "Generate"
        case decode = "Decode"

        public var id: Self { self }
    }

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("qrCodeTool")) public var inputText = ""
        @Shared(.toolOutput("qrCodeTool")) public var outputText = ""
        var input: InputEditorReducer.State
        var output: OutputEditorReducer.State
        var mode: Mode = .generate
        var errorCorrection: QrCodeErrorCorrection = .high
        var dimension: Int = 256
        var decodedMessages: [String] = []
        var errorMessage: String?
        var isConversionRequestInFlight = false

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("qrCodeTool"))
            let outputText = Shared(wrappedValue: "", .toolOutput("qrCodeTool"))
            self._inputText = inputText
            self._outputText = outputText
            self.input = InputEditorReducer.State(text: inputText.projectedValue)
            self.output = OutputEditorReducer.State(text: outputText.projectedValue)
        }

        public init(inputText: String, outputText: String = "") {
            let input = Shared(wrappedValue: inputText, .toolInput("qrCodeTool"))
            let output = Shared(wrappedValue: outputText, .toolOutput("qrCodeTool"))
            self._inputText = input
            self._outputText = output
            self.input = InputEditorReducer.State(text: input.projectedValue)
            self.output = OutputEditorReducer.State(text: output.projectedValue)
        }

        var config: QrCodeGenerationConfig {
            QrCodeGenerationConfig(dimension: dimension, errorCorrection: errorCorrection)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
        case output(OutputEditorReducer.Action)
        case convertButtonTouched
        case conversionResponse(TaskResult<QrCodeGenerationResult>)
        case decodeResponse(TaskResult<[String]>)
    }

    @Dependency(\.qrCodeTool) var qrCodeTool
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .input:
                return .none

            case .output:
                return .none

            case .convertButtonTouched:
                state.errorMessage = nil
                state.isConversionRequestInFlight = true
                let input = state.input.text
                if state.mode == .generate {
                    let config = state.config
                    return .run { [qrCodeTool] send in
                        await send(
                            .conversionResponse(
                                TaskResult {
                                    try await qrCodeTool.generate(input, config)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)
                } else {
                    return .run { [qrCodeTool] send in
                        await send(
                            .decodeResponse(
                                TaskResult {
                                    try await qrCodeTool.decode(input)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)
                }

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                state.decodedMessages = []
                return state.output.updateText(result.base64PNG)
                    .map { Action.output($0) }

            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.errorMessage = error.localizedDescription
                return state.output.updateText(error.localizedDescription)
                    .map { Action.output($0) }

            case let .decodeResponse(.success(messages)):
                state.isConversionRequestInFlight = false
                state.decodedMessages = messages
                let output = messages.joined(separator: "\n")
                return state.output.updateText(output)
                    .map { Action.output($0) }

            case let .decodeResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.decodedMessages = []
                state.errorMessage = error.localizedDescription
                return state.output.updateText(error.localizedDescription)
                    .map { Action.output($0) }
            }
        }

        Scope(state: \.input, action: \.input) {
            InputEditorReducer()
        }

        Scope(state: \.output, action: \.output) {
            OutputEditorReducer()
        }
    }
}

public struct QrCodeToolView: View {
    @Perception.Bindable var store: StoreOf<QrCodeToolReducer>
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.QrCodeTool.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.QrCodeTool.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<QrCodeToolReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    Picker("Mode", selection: $store.mode) {
                        ForEach(QrCodeToolReducer.Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    if store.mode == .generate {
                        ConfigLabel("Correction")
                        Picker("Correction", selection: $store.errorCorrection) {
                            ForEach(QrCodeErrorCorrection.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .blissMenuPicker(width: 140)
                        
                        ConfigLabel("Size")
                        Stepper("Size \(store.dimension)", value: $store.dimension, in: 128...1024, step: 64)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton(store.mode == .generate ? "Generate" : "Decode", isLoading: store.isConversionRequestInFlight) {
                store.send(.convertButtonTouched)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Convert (⌘ Return)")
            .padding(.vertical, 8)

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Split(primary: { inputEditor }, secondary: { outputPane })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        InputEditorView(
            store: store.scope(state: \.input, action: \.input),
            title: store.mode == .generate ? "Content" : "Image Path or Base64"
        )
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            if store.mode == .generate {
                if store.input.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Spacer()
                    Text("Enter content to generate a QR code")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    QRCodeViewUI(content: store.input.text, errorCorrection: store.errorCorrection.qrCodeValue)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding()
                }
            } else {
                if store.decodedMessages.isEmpty {
                    Spacer()
                    Text("Provide an image path or base64 data to decode")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(store.decodedMessages, id: \.self) { message in
                        Text(message)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            Divider()

            OutputEditorView(store: store.scope(state: \.output, action: \.output))
        }
    }
}

private extension QrCodeErrorCorrection {
    var qrCodeValue: QRCode.ErrorCorrection {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .quantize: return .quantize
        case .high: return .high
        }
    }
}

struct QrCodeToolView_Previews: PreviewProvider {
    static var previews: some View {
        QrCodeToolView(store: .init(initialState: .init()) { QrCodeToolReducer() })
    }
}
