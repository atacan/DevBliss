import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import SplitView
import SwiftUI
import UuidUlidClient

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Reducer
public struct UuidUlidReducer {
    public init() {}

    public enum Mode: String, CaseIterable, Identifiable {
        case generate = "Generate"
        case decode = "Decode"

        public var id: Self { self }
    }

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("uuidUlid")) public var inputText = ""
        @Shared(.toolOutput("uuidUlid")) public var outputText = ""
        var input: InputEditorReducer.State
        var output: OutputEditorReducer.State
        var mode: Mode = .generate
        var type: UuidUlidType = .uuid
        var count: Int = 5
        var lowercase: Bool = false
        var result: UuidUlidDecodeResult?
        var errorMessage: String?
        var isConversionRequestInFlight = false

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("uuidUlid"))
            let outputText = Shared(wrappedValue: "", .toolOutput("uuidUlid"))
            self._inputText = inputText
            self._outputText = outputText
            self.input = InputEditorReducer.State(text: inputText.projectedValue)
            self.output = OutputEditorReducer.State(text: outputText.projectedValue)
        }

        public init(inputText: String, outputText: String = "") {
            let input = Shared(wrappedValue: inputText, .toolInput("uuidUlid"))
            let output = Shared(wrappedValue: outputText, .toolOutput("uuidUlid"))
            self._inputText = input
            self._outputText = output
            self.input = InputEditorReducer.State(text: input.projectedValue)
            self.output = OutputEditorReducer.State(text: output.projectedValue)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
        case output(OutputEditorReducer.Action)
        case convertButtonTouched
        case generateResponse(TaskResult<String>)
        case decodeResponse(TaskResult<UuidUlidDecodeResult>)
    }

    @Dependency(\.uuidUlid) var uuidUlid
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
                if state.mode == .generate {
                    let type = state.type
                    let count = state.count
                    let lowercase = state.lowercase
                    return .run { [uuidUlid] send in
                        await send(
                            .generateResponse(
                                TaskResult {
                                    try await uuidUlid.generate(type, count, lowercase)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)
                } else {
                    let input = state.input.text
                    return .run { [uuidUlid] send in
                        await send(
                            .decodeResponse(
                                TaskResult {
                                    try await uuidUlid.decode(input)
                                }
                            )
                        )
                    }
                    .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)
                }

            case let .generateResponse(.success(result)):
                state.isConversionRequestInFlight = false
                state.result = nil
                return state.output.updateText(result)
                    .map { Action.output($0) }

            case let .generateResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.errorMessage = error.localizedDescription
                return state.output.updateText(error.localizedDescription)
                    .map { Action.output($0) }

            case let .decodeResponse(.success(result)):
                state.isConversionRequestInFlight = false
                state.result = result
                return state.output.updateText(result.summary)
                    .map { Action.output($0) }

            case let .decodeResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.result = nil
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

public struct UuidUlidView: View {
    @Bindable var store: StoreOf<UuidUlidReducer>
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.UuidUlid.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.UuidUlid.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<UuidUlidReducer>) {
        self.store = store
    }

    // MARK: - Reusable Controls

    private var modePicker: some View {
        Picker("Mode", selection: $store.mode) {
            ForEach(UuidUlidReducer.Mode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var typePicker: some View {
        Picker("Type", selection: $store.type) {
            ForEach(UuidUlidType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .labelsHidden()
    }

    private var countStepper: some View {
        Stepper("Count \(store.count)", value: $store.count, in: 1...100)
    }

    private var lowercaseToggle: some View {
        Toggle("Lowercase", isOn: $store.lowercase)
    }

    private var actionButton: some View {
        LoadingButton(store.mode == .generate ? "Generate" : "Decode", isLoading: store.isConversionRequestInFlight) {
            store.send(.convertButtonTouched)
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                modePicker
                if store.mode == .generate {
                    HStack {
                        Text("Type")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        typePicker
                    }
                    countStepper
                    lowercaseToggle
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            actionButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    modePicker
                        .frame(width: 200)

                    if store.mode == .generate {
                        ConfigLabel("Type")
                        typePicker
                            .blissMenuPicker(width: 120)

                        countStepper
                        lowercaseToggle
                            .toggleStyle(.checkbox)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            actionButton
                .padding(.vertical, 8)
            #endif

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
            title: store.mode == .generate ? "Input (optional)" : "UUID or ULID"
        )
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            if store.mode == .decode, let result = store.result {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 16)], spacing: 16) {
                        ResultCard(title: "Type", value: result.type.rawValue, icon: "tag")
                        ResultCard(title: "Standard", value: result.standard, icon: "textformat")
                        ResultCard(title: "Raw", value: result.raw, icon: "number")
                        ResultCard(title: "Version", value: result.version, icon: "v.circle")
                        ResultCard(title: "Variant", value: result.variant, icon: "square.dashed")
                        ResultCard(title: "Timestamp", value: result.timestamp, icon: "calendar")
                        ResultCard(title: "Random", value: result.random, icon: "shuffle")
                    }
                    .padding()
                }
            } else if store.mode == .decode {
                Spacer()
                Text("Enter a UUID or ULID to decode")
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider()

            OutputEditorView(store: store.scope(state: \.output, action: \.output))
        }
    }
}

private struct ResultCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    #else
                    UIPasteboard.general.string = value
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
            }

            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct UuidUlidView_Previews: PreviewProvider {
    static var previews: some View {
        UuidUlidView(store: .init(initialState: .init()) { UuidUlidReducer() })
    }
}
