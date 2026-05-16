import BlissTheme
import Dependencies
import SharedModels
import Sharing
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
public final class ColorConverterModel {
    @ObservationIgnored
    @Shared(.toolInput("colorConverter"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("colorConverter"))
    public var outputText = ""

    public var uppercaseHex: Bool = true
    public var includeAlpha: Bool = false
    public var isConversionRequestInFlight = false
    public var result: ColorConversionResult?
    public var errorMessage: String?
    public var input: String {
        get { inputText }
        set { $inputText.withLock { $0 = newValue } }
    }

    private var config: ColorConverterConfig {
        ColorConverterConfig(uppercaseHex: uppercaseHex, includeAlpha: includeAlpha)
    }

    @ObservationIgnored
    @Dependency(\.colorConverter) private var colorConverter

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("colorConverter"))
        let outputText = Shared(wrappedValue: "", .toolOutput("colorConverter"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(inputText: String, outputText: String = "") {
        let inputText = Shared(wrappedValue: inputText, .toolInput("colorConverter"))
        let outputText = Shared(wrappedValue: outputText, .toolOutput("colorConverter"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = true
        errorMessage = nil

        let input = inputText
        let config = config
        let colorConverter = colorConverter

        conversionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await colorConverter.convert(input, config)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.result = result
                    self.$outputText.withLock { $0 = result.summary }
                }
            } catch {
                if error is CancellationError {
                    return
                }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.result = nil
                    self.errorMessage = error.localizedDescription
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }

    deinit {
        conversionTask?.cancel()
    }
}

public struct ColorConverterView: View {
    @Bindable var model: ColorConverterModel

    public init(model: ColorConverterModel) {
        self.model = model
    }

    private var inputField: some View {
        TextField(
            "Enter a color value (hex or rgb)",
            text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            )
        )
            .blissTextField()
            .onSubmit {
                model.convertButtonTouched()
            }
    }

    private var convertButton: some View {
        LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
    }

    private var uppercaseHexToggle: some View {
        Toggle("Uppercase hex", isOn: $model.uppercaseHex)
    }

    private var includeAlphaToggle: some View {
        Toggle("Include alpha", isOn: $model.includeAlpha)
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                inputField
                convertButton
                uppercaseHexToggle
                includeAlphaToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #else
            HStack(spacing: 12) {
                inputField
                convertButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Options")
                    uppercaseHexToggle
                        .toggleStyle(.checkbox)
                    includeAlphaToggle
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #endif

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            ScrollView {
                if let result = model.result {
                    VStack(spacing: 16) {
                        ColorPreviewCard(result: result)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 16)], spacing: 16) {
                            ResultCard(title: "HEX", value: result.hex, icon: "number")
                            ResultCard(title: "RGB", value: result.rgb, icon: "circle.grid.3x3")
                            ResultCard(title: "RGBA", value: result.rgba, icon: "circle.grid.3x3.fill")
                            ResultCard(title: "HSL", value: result.hsl, icon: "circle.lefthalf.filled")
                            ResultCard(title: "HSLA", value: result.hsla, icon: "circle.lefthalf.filled.righthalf.striped.horizontal")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                } else {
                    Text("Enter a color to convert")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                    .padding(.horizontal, 8)
                TextEditor(text: Binding(
                    get: { model.outputText },
                    set: { newValue in model.$outputText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .lineSpacing(3)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 180)
            }
            .frame(minHeight: 180)
        }
    }
}

private struct ColorPreviewCard: View {
    let result: ColorConversionResult

    var body: some View {
        let color = Color(.sRGB, red: result.red, green: result.green, blue: result.blue, opacity: result.alpha)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal)
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

struct ColorConverterView_Previews: PreviewProvider {
    static var previews: some View {
        ColorConverterView(model: .init())
    }
}
