import BlissTheme
import ComposableArchitecture
import SharedModels
import SwiftUI
import UrlEncodeClient

@Reducer
public struct UrlEncodeReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("urlEncode")) public var inputText = ""
        @Shared(.toolOutput("urlEncode")) public var outputText = ""
        var direction: UrlEncodeDirection = .encode
        var encodeMode: UrlEncodeMode = .rfc3986
        var autoDetect: Bool = true
        var decodePlusAsSpace: Bool = true
        var result: String = ""
        var errorMessage: String?

        // Input is derived from inputText for persistence
        public var input: String {
            get { inputText }
            set { $inputText.withLock { $0 = newValue } }
        }

        public init() {}

        public init(input: String, output: String = "") {
            self._inputText = Shared(wrappedValue: input, .toolInput("urlEncode"))
            self._outputText = Shared(wrappedValue: output, .toolOutput("urlEncode"))
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case useAsInputButtonTouched
        case copyResultButtonTouched
    }

    @Dependency(\.urlEncode) var urlEncode

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.inputText):
                // Auto-detect if input looks URL-encoded
                if state.autoDetect {
                    let input = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
                    if urlEncode.looksEncoded(input) {
                        state.direction = .decode
                    } else if !input.isEmpty {
                        state.direction = .encode
                    }
                }
                return .none

            case .binding:
                return .none

            case .convertButtonTouched:
                state.errorMessage = nil
                let input = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !input.isEmpty else {
                    state.errorMessage = "Please enter a value"
                    return .none
                }

                switch state.direction {
                case .encode:
                    state.result = urlEncode.encode(input, state.encodeMode)
                case .decode:
                    state.result = urlEncode.decode(input, state.decodePlusAsSpace)
                }

                // Persist output
                state.$outputText.withLock { $0 = state.result }
                return .none

            case .useAsInputButtonTouched:
                guard !state.result.isEmpty else { return .none }
                state.$inputText.withLock { $0 = state.result }
                state.result = ""
                // Swap direction when using output as input
                state.direction = state.direction == .encode ? .decode : .encode
                return .none

            case .copyResultButtonTouched:
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(state.result, forType: .string)
                #else
                UIPasteboard.general.string = state.result
                #endif
                return .none
            }
        }
    }
}

public struct UrlEncodeView: View {
    @Perception.Bindable var store: StoreOf<UrlEncodeReducer>

    public init(store: StoreOf<UrlEncodeReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Input section: TextField + Convert
            HStack(spacing: 12) {
                TextField("Enter text to encode/decode", text: $store.inputText)
                    .blissTextField()
                    .onSubmit {
                        store.send(.convertButtonTouched)
                    }

                LoadingButton("Convert", isLoading: false) {
                    store.send(.convertButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Convert (Command Return)")
                .disabled(store.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Error message
            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            // Options rows
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    Picker("Mode", selection: $store.direction) {
                        ForEach(UrlEncodeDirection.allCases) { direction in
                            Text(direction.rawValue)
                                .tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)

                    Toggle("Auto-detect", isOn: $store.autoDetect)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .gridCellColumns(2)
                        .help("Automatically detect if input looks URL-encoded and switch to Decode mode")
                }

                GridRow {
                    ConfigLabel("Encode")
                    Picker("Encode Mode", selection: $store.encodeMode) {
                        ForEach(UrlEncodeMode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 160)
                    .disabled(store.direction == .decode)

                    ConfigLabel("Decode")
                    Toggle("+ as space", isOn: $store.decodePlusAsSpace)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .help("Decode + characters as spaces (for form data)")
                        .disabled(store.direction == .encode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Result section
            VStack(alignment: .leading, spacing: 8) {
                Text("Result")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(store.result.isEmpty ? "Result will appear here" : store.result)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(store.result.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        #if os(macOS)
                        .background(ThemeColor.Background.textBackground)
                        #else
                        .background(Color(uiColor: .secondarySystemBackground))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                #if os(macOS)
                                .stroke(ThemeColor.Background.separator, lineWidth: 1)
                                #else
                                .stroke(Color(uiColor: .separator), lineWidth: 1)
                                #endif
                        )
                }

                HStack(spacing: 12) {
                    Button {
                        store.send(.copyResultButtonTouched)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.result.isEmpty)
                    .help("Copy result to clipboard")

                    Button {
                        store.send(.useAsInputButtonTouched)
                    } label: {
                        Label("Use as Input", systemImage: "arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.result.isEmpty)
                    .help("Use result as new input")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Spacer()
        }
    }
}

// MARK: - Preview

struct UrlEncodeReducer_Previews: PreviewProvider {
    static var previews: some View {
        UrlEncodeView(store: .init(initialState: .init()) { UrlEncodeReducer() })
    }
}
