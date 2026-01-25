import BlissTheme
import CertificateDecoderClient
import ComposableArchitecture
import InputOutput
import SharedModels
import SplitView
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Reducer
public struct CertificateDecoderReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("certificateDecoder")) public var inputText = ""
        @Shared(.toolOutput("certificateDecoder")) public var outputText = ""
        var input: InputEditorReducer.State
        var output: OutputEditorReducer.State
        var result: CertificateDecodeResult?
        var errorMessage: String?

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("certificateDecoder"))
            let outputText = Shared(wrappedValue: "", .toolOutput("certificateDecoder"))
            self._inputText = inputText
            self._outputText = outputText
            self.input = InputEditorReducer.State(text: inputText.projectedValue)
            self.output = OutputEditorReducer.State(text: outputText.projectedValue)
        }

        public init(inputText: String, outputText: String = "") {
            let input = Shared(wrappedValue: inputText, .toolInput("certificateDecoder"))
            let output = Shared(wrappedValue: outputText, .toolOutput("certificateDecoder"))
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
        case decodeButtonTouched
        case decodeResponse(TaskResult<CertificateDecodeResult>)
    }

    @Dependency(\.certificateDecoder) var certificateDecoder
    private enum CancelID { case decodeRequest }

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
            case .decodeButtonTouched:
                state.errorMessage = nil
                let input = state.input.text
                return .run { [certificateDecoder] send in
                    await send(
                        .decodeResponse(
                            TaskResult {
                                try certificateDecoder.decode(input)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.decodeRequest, cancelInFlight: true)

            case let .decodeResponse(.success(result)):
                state.result = result
                return state.output.updateText(result.summary)
                    .map { Action.output($0) }

            case let .decodeResponse(.failure(error)):
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

public struct CertificateDecoderView: View {
    @Perception.Bindable var store: StoreOf<CertificateDecoderReducer>
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.CertificateDecoder.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.CertificateDecoder.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<CertificateDecoderReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                
                LoadingButton("Decode", isLoading: false) {
                    store.send(.decodeButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Decode (⌘ Return)")
            }
            .padding(.horizontal, 16)
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
        InputEditorView(store: store.scope(state: \.input, action: \.input), title: "Certificate Input")
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            if let result = store.result {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 16)], spacing: 16) {
                        ResultCard(title: "Subject", value: result.subject, icon: "person")
                        ResultCard(title: "Issuer", value: result.issuer, icon: "person.badge.key")
                        ResultCard(title: "Serial", value: result.serialNumber, icon: "number")
                        ResultCard(title: "Not Before", value: result.notValidBefore, icon: "calendar")
                        ResultCard(title: "Not After", value: result.notValidAfter, icon: "calendar.badge.exclamationmark")
                        ResultCard(title: "Signature", value: result.signatureAlgorithm, icon: "signature")
                        ResultCard(title: "Public Key", value: result.publicKey, icon: "key")
                        ResultCard(title: "Extensions", value: "\(result.extensionsCount)", icon: "square.stack")
                    }
                    .padding()
                }
            } else {
                Spacer()
                Text("Paste a PEM or base64 DER certificate to the input editor")
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider()

            OutputEditorView(store: store.scope(state: \.output, action: \.output), title: "Summary")
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

struct CertificateDecoderView_Previews: PreviewProvider {
    static var previews: some View {
        CertificateDecoderView(store: .init(initialState: .init()) { CertificateDecoderReducer() })
    }
}
