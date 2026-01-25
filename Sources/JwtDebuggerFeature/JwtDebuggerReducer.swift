import BlissTheme
import ComposableArchitecture
import Dependencies
import InputOutput
import JwtDebuggerClient
import SharedModels
import SwiftUI

@Reducer
public struct JwtDebuggerReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("jwtDebugger")) public var inputText = ""
        @Shared(.toolOutput("jwtDebugger")) public var outputText = ""
        public var input: InputAttributedEditorReducer.State
        var autoDetect = true
        var secretKey = ""
        var isDecoding = false
        var inspection: JwtDebugInspection?
        var errorMessage: String?

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("jwtDebugger"))
            self._inputText = inputText
            self.input = InputAttributedEditorReducer.State(rawText: inputText.projectedValue)
        }

        public init(input: String, output: String = "") {
            let inputText = Shared(wrappedValue: input, .toolInput("jwtDebugger"))
            let outputText = Shared(wrappedValue: output, .toolOutput("jwtDebugger"))
            self._inputText = inputText
            self._outputText = outputText
            self.input = InputAttributedEditorReducer.State(rawText: inputText.projectedValue)
        }

        var tokenText: String {
            input.text.string
        }

        var isTokenEmpty: Bool {
            tokenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var algorithmDisplay: String {
            inspection?.algorithm ?? "Unknown"
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputAttributedEditorReducer.Action)
        case decodeButtonTouched
        case decodeResponse(TaskResult<JwtDebugInspection>)
    }

    @Dependency(\.jwtDebugger) var jwtDebugger
    private enum CancelID { case decodeRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.input, action: \.input) {
            InputAttributedEditorReducer()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.autoDetect):
                guard state.autoDetect else {
                    return .none
                }
                return decodeIfNeeded(state: &state, setLoading: false)

            case .binding(\.secretKey):
                guard state.autoDetect else {
                    return .none
                }
                return decodeIfNeeded(state: &state, setLoading: false)

            case .binding:
                return .none

            case .input:
                state.errorMessage = nil
                applyHighlight(to: &state)
                guard state.autoDetect else {
                    if state.isTokenEmpty {
                        state.inspection = nil
                    }
                    return .none
                }
                return decodeIfNeeded(state: &state, setLoading: false)

            case .decodeButtonTouched:
                applyHighlight(to: &state)
                return decode(state: &state, setLoading: true)

            case let .decodeResponse(.success(inspection)):
                state.isDecoding = false
                state.inspection = inspection
                state.errorMessage = nil
                return .none

            case let .decodeResponse(.failure(error)):
                state.isDecoding = false
                state.inspection = nil
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }

    private func decodeIfNeeded(state: inout State, setLoading: Bool) -> Effect<Action> {
        guard looksLikeJwt(state.tokenText) else {
            state.inspection = nil
            return .none
        }
        return decode(state: &state, setLoading: setLoading)
    }

    private func decode(state: inout State, setLoading: Bool) -> Effect<Action> {
        if setLoading {
            state.isDecoding = true
        }

        let token = state.tokenText
        let secret = state.secretKey.isEmpty ? nil : state.secretKey

        return .run { [jwtDebugger] send in
            await send(
                .decodeResponse(
                    TaskResult {
                        try await jwtDebugger.inspect(token, secret)
                    }
                )
            )
        }
        .cancellable(id: CancelID.decodeRequest, cancelInFlight: true)
    }

    private func applyHighlight(to state: inout State) {
        let highlighted = jwtHighlightedString(state.tokenText)
        _ = state.input.updateText(highlighted)
    }
}

public struct JwtDebuggerView: View {
    @Bindable var store: StoreOf<JwtDebuggerReducer>

    public init(store: StoreOf<JwtDebuggerReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            optionsView

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            InputAttributedEditorView(
                store: store.scope(state: \.input, action: JwtDebuggerReducer.Action.input),
                title: NSLocalizedString("Token", comment: "")
            )
            .frame(minHeight: 140, idealHeight: 180, maxHeight: 240)

            Divider()

            outputView
        }
    }

    private var optionsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Toggle("Auto-detect", isOn: $store.autoDetect)
                    #if os(macOS)
                    .toggleStyle(.checkbox)
                    #endif
                    .help("Automatically decode when input looks like a JWT")

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                    Text("Algorithm")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(store.algorithmDisplay)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                TextField(
                    "Secret or public key (for signature verification)",
                    text: $store.secretKey
                )
                .font(.monospaced(.body)())
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .blissTextField()

                LoadingButton(
                    NSLocalizedString("Decode", comment: ""),
                    isLoading: store.isDecoding
                ) {
                    store.send(.decodeButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Decode token (Command+Return)", comment: ""))
                .disabled(store.isTokenEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var outputView: some View {
        if let inspection = store.inspection {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 260, maximum: 520), spacing: 16)],
                    spacing: 16
                ) {
                    JwtJsonCard(title: "Header", json: inspection.headerJSON, icon: "doc.text")
                    JwtJsonCard(title: "Payload", json: inspection.payloadJSON, icon: "doc.plaintext")
                    JwtSignatureCard(inspection: inspection)
                    JwtClaimsCard(claims: inspection.claims)
                }
                .padding()
            }
        } else {
            Spacer()
            Text("Enter a JWT to decode")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private struct JwtJsonCard: View {
    let title: String
    let json: String
    let icon: String

    var body: some View {
        JwtCardContainer {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                copyButton(json)
            }

            Text(json)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func copyButton(_ value: String) -> some View {
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
}

private struct JwtSignatureCard: View {
    let inspection: JwtDebugInspection

    var body: some View {
        JwtCardContainer {
            HStack {
                Image(systemName: "signature")
                    .foregroundColor(.accentColor)
                Text("Signature")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                copyButton(inspection.signature)
            }

            HStack(spacing: 8) {
                Text(inspection.verification.label)
                    .font(.headline)
                    .foregroundStyle(inspection.verification.color)

                if let detail = inspection.verification.detail {
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Text(inspection.signature)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private func copyButton(_ value: String) -> some View {
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
}

private struct JwtClaimsCard: View {
    let claims: [JwtClaimItem]

    var body: some View {
        JwtCardContainer {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.accentColor)
                Text("Claims")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if claims.isEmpty {
                Text("No registered claims found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(claims) { claim in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(claim.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(claim.value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    if claim.id != claims.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct JwtCardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .background(ThemeColor.Background.controlBackground)
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

private func looksLikeJwt(_ token: String) -> Bool {
    let parts = token.trimmingCharacters(in: .whitespacesAndNewlines)
        .split(separator: ".", omittingEmptySubsequences: false)
    return parts.count == 3
}

private func jwtHighlightedString(_ text: String) -> NSMutableAttributedString {
    #if os(macOS)
    let baseColor = NSColor(ThemeColor.Text.editedText)
    let headerColor = NSColor.systemBlue
    let payloadColor = NSColor.systemGreen
    let signatureColor = NSColor.systemOrange
    let font = ThemeFont.monospaceSytem
    #else
    let baseColor = UIColor(ThemeColor.Text.editedText)
    let headerColor = UIColor.systemBlue
    let payloadColor = UIColor.systemGreen
    let signatureColor = UIColor.systemOrange
    let font = ThemeFont.monospaceSytem
    #endif

    let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: baseColor,
        .font: font,
    ]

    let attributed = NSMutableAttributedString(string: text, attributes: attributes)
    let parts = text.split(separator: ".", omittingEmptySubsequences: false)

    guard parts.count >= 2 else {
        return attributed
    }

    let colors = [headerColor, payloadColor, signatureColor]
    var location = 0
    for (index, part) in parts.enumerated() {
        let length = part.utf16.count
        let color = colors[min(index, colors.count - 1)]
        attributed.addAttribute(.foregroundColor, value: color, range: NSRange(location: location, length: length))
        location += length
        if index < parts.count - 1 {
            location += 1
        }
    }

    return attributed
}

private extension JwtSignatureVerification {
    var label: String {
        switch self {
        case .verified:
            return "Verified"
        case .invalid:
            return "Invalid"
        case .noSecret:
            return "No Secret"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported (\(algorithm))"
        case .invalidToken:
            return "Invalid Token"
        case .missingAlgorithm:
            return "Missing Algorithm"
        case .invalidKey:
            return "Invalid Key"
        }
    }

    var detail: String? {
        switch self {
        case .unsupportedAlgorithm:
            return "Supported: HS256/384/512, RS256/384/512, ES256/384/512"
        case .noSecret:
            return "Enter a verification key"
        case .invalidKey:
            return "Unsupported key format"
        default:
            return nil
        }
    }

    var color: Color {
        switch self {
        case .verified:
            return .green
        case .invalid, .invalidToken, .missingAlgorithm:
            return .red
        case .noSecret:
            return .secondary
        case .unsupportedAlgorithm:
            return .orange
        case .invalidKey:
            return .orange
        }
    }
}

// MARK: - Preview

struct JwtDebuggerReducer_Previews: PreviewProvider {
    static var previews: some View {
        JwtDebuggerView(store: .init(initialState: .init()) { JwtDebuggerReducer() })
    }
}
