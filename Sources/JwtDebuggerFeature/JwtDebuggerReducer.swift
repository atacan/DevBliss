import BlissTheme
import Dependencies
import Foundation
import SharedModels
import Sharing
import SwiftUI

@MainActor
@Observable
public final class JwtDebuggerModel {
    @ObservationIgnored
    @Shared(.toolInput("jwtDebugger")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("jwtDebugger")) public var outputText = ""

    @ObservationIgnored
    @Dependency(\.jwtDebugger) private var jwtDebugger

    public var autoDetect = true
    public var secretKey = ""
    public var isDecoding = false
    public var inspection: JwtDebugInspection?
    public var errorMessage: String?

    @ObservationIgnored
    private var decodeTask: Task<Void, Never>?

    public var isTokenEmpty: Bool {
        tokenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var algorithmDisplay: String {
        inspection?.algorithm ?? "Unknown"
    }

    private var tokenText: String {
        inputText
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("jwtDebugger"))
        let outputText = Shared(wrappedValue: "", .toolOutput("jwtDebugger"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("jwtDebugger"))
        let outputText = Shared(wrappedValue: output, .toolOutput("jwtDebugger"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setAutoDetect(_ enabled: Bool) {
        autoDetect = enabled
        guard enabled else {
            return
        }
        decodeIfNeeded(setLoading: false)
    }

    public func setSecretKey(_ newValue: String) {
        secretKey = newValue
        guard autoDetect else {
            return
        }
        decodeIfNeeded(setLoading: false)
    }

    public func onInputChanged() {
        guard autoDetect else {
            if isTokenEmpty {
                inspection = nil
                errorMessage = nil
            }
            return
        }
        decodeIfNeeded(setLoading: false)
    }

    public func decodeButtonTouched() {
        decode(setLoading: true)
    }

    public func cancel() {
        decodeTask?.cancel()
        decodeTask = nil
        isDecoding = false
    }

    private func decodeIfNeeded(setLoading: Bool) {
        guard looksLikeJwt(tokenText) else {
            inspection = nil
            return
        }
        decode(setLoading: setLoading)
    }

    private func decode(setLoading: Bool) {
        decodeTask?.cancel()
        if setLoading {
            isDecoding = true
        }

        let token = tokenText
        let secret = secretKey.isEmpty ? nil : secretKey
        let jwtDebugger = jwtDebugger

        decodeTask = Task { [weak self] in
            guard let self else { return }

            do {
                let inspection = try await jwtDebugger.inspect(token, secret)
                await MainActor.run {
                    self.isDecoding = false
                    self.inspection = inspection
                    self.errorMessage = nil
                    self.$outputText.withLock { $0 = inspection.payloadJSON }
                }
            } catch {
                if error is CancellationError {
                    return
                }

                await MainActor.run {
                    self.isDecoding = false
                    self.inspection = nil
                    self.errorMessage = error.localizedDescription
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

}

public struct JwtDebuggerModelView: View {
    @Bindable var model: JwtDebuggerModel

    public init(model: JwtDebuggerModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            optionsView

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("Token", comment: ""))
                    .font(.headline)
                    .padding(.horizontal, 8)

                TextEditor(text: Binding(
                    get: { model.inputText },
                    set: { newValue in model.$inputText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
            .onChange(of: model.inputText) { _, _ in
                model.onInputChanged()
            }
            .frame(minHeight: 140, idealHeight: 180, maxHeight: 240)

            Divider()

            outputView
        }
    }

    // MARK: - Reusable Controls

    private var autoDetectToggle: some View {
        Toggle("Auto-detect", isOn: $model.autoDetect)
            .onChange(of: model.autoDetect) { _, value in
                model.setAutoDetect(value)
            }
            .help("Automatically decode when input looks like a JWT")
    }

    private var algorithmDisplay: some View {
        HStack(spacing: 6) {
            Image(systemName: "cpu")
            Text("Algorithm")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(model.algorithmDisplay)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var secretKeyField: some View {
        TextField(
            "Secret or public key (for signature verification)",
            text: $model.secretKey
        )
        .font(.monospaced(.body)())
        .autocorrectionDisabled()
        #if os(iOS)
        .textInputAutocapitalization(.never)
        #endif
        .blissTextField()
        .onChange(of: model.secretKey) { _, value in
            model.setSecretKey(value)
        }
    }

    private var decodeButton: some View {
        LoadingButton(
            NSLocalizedString("Decode", comment: ""),
            isLoading: model.isDecoding
        ) {
            model.decodeButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help(NSLocalizedString("Decode token (Command+Return)", comment: ""))
        .disabled(model.isTokenEmpty)
    }

    private var optionsView: some View {
        VStack(spacing: 12) {
            #if os(iOS)
            HStack {
                autoDetectToggle
            }
            algorithmDisplay
            secretKeyField
            decodeButton
            #else
            HStack(spacing: 12) {
                autoDetectToggle
                    .toggleStyle(.checkbox)
                Spacer()
                algorithmDisplay
            }
            HStack(spacing: 12) {
                secretKeyField
                decodeButton
            }
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var outputView: some View {
        if let inspection = model.inspection {
            ScrollView {
                VStack(spacing: 16) {
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
