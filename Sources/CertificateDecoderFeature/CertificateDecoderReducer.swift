import BlissTheme
import Dependencies
import SharedModels
import Sharing
import SplitView
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
public final class CertificateDecoderModel {
    @ObservationIgnored
    @Shared(.toolInput("certificateDecoder"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("certificateDecoder"))
    public var outputText = ""

    @ObservationIgnored
    @Dependency(\.certificateDecoder) private var certificateDecoder

    @ObservationIgnored
    private var decodeTask: Task<Void, Never>?

    public var result: CertificateDecodeResult?
    public var errorMessage: String?
    public var isConversionRequestInFlight = false

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("certificateDecoder"))
        let outputText = Shared(wrappedValue: "", .toolOutput("certificateDecoder"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(outputText: String) {
        let inputText = Shared(wrappedValue: "", .toolInput("certificateDecoder"))
        let outputText = Shared(wrappedValue: outputText, .toolOutput("certificateDecoder"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func decodeButtonTouched() {
        decodeTask?.cancel()
        decodeTask = nil
        isConversionRequestInFlight = true
        errorMessage = nil
        let input = inputText
        let decoder = certificateDecoder
        decodeTask = Task { [weak self, input = input, decoder = decoder] in
            guard let self else { return }
            do {
                let result = try decoder.decode(input)
                await MainActor.run {
                    self.result = result
                    self.isConversionRequestInFlight = false
                    self.outputText = result.summary
                }
            }
            catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.result = nil
                    self.isConversionRequestInFlight = false
                    self.errorMessage = error.localizedDescription
                    self.outputText = error.localizedDescription
                }
            }
        }
    }

    public func cancel() {
        decodeTask?.cancel()
        decodeTask = nil
        isConversionRequestInFlight = false
    }

    public init(inputText: String, outputText: String = "") {
        let input = Shared(wrappedValue: inputText, .toolInput("certificateDecoder"))
        let output = Shared(wrappedValue: outputText, .toolOutput("certificateDecoder"))
        self._inputText = input
        self._outputText = output
    }
}

public struct CertificateDecoderView: View {
    @Bindable var model: CertificateDecoderModel
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.CertificateDecoder.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.CertificateDecoder.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: CertificateDecoderModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                LoadingButton("Decode", isLoading: model.isConversionRequestInFlight) {
                    model.decodeButtonTouched()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Decode (⌘ Return)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let errorMessage = model.errorMessage {
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Certificate Input")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: $model.inputText)
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            if let result = model.result {
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Summary")
                    .font(.headline)
                    .padding(.horizontal, 8)
                TextEditor(text: $model.outputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
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
        CertificateDecoderView(model: .init())
    }
}
