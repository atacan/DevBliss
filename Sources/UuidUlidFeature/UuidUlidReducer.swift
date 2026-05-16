import BlissTheme
import Dependencies
import Observation
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
public final class UuidUlidModel {
    public enum Mode: String, CaseIterable, Identifiable {
        case generate = "Generate"
        case decode = "Decode"

        public var id: Self { self }
    }

    @ObservationIgnored
    @Shared(.toolInput("uuidUlid"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("uuidUlid"))
    public var outputText = ""

    public var mode: Mode = .generate
    public var type: UuidUlidType = .uuid
    public var count: Int = 5
    public var lowercase: Bool = false
    public var result: UuidUlidDecodeResult?
    public var errorMessage: String?
    public var isConversionRequestInFlight = false

    @ObservationIgnored
    @Dependency(\.uuidUlid) private var uuidUlid

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("uuidUlid"))
        let outputText = Shared(wrappedValue: "", .toolOutput("uuidUlid"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(inputText: String, outputText: String = "") {
        let inputText = Shared(wrappedValue: inputText, .toolInput("uuidUlid"))
        let outputText = Shared(wrappedValue: outputText, .toolOutput("uuidUlid"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func setMode(_ mode: Mode) {
        self.mode = mode
        if mode == .generate {
            result = nil
            errorMessage = nil
        }
    }

    public func setType(_ type: UuidUlidType) {
        self.type = type
    }

    public func setCount(_ count: Int) {
        self.count = count
    }

    public func setLowercase(_ lowercase: Bool) {
        self.lowercase = lowercase
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        errorMessage = nil

        if mode == .generate {
            let type = self.type
            let count = self.count
            let lowercase = self.lowercase

            conversionTask = Task { [weak self, uuidUlid = uuidUlid, type = type, count = count, lowercase = lowercase] in
                guard let self else { return }
                do {
                    let result = try await uuidUlid.generate(type, count, lowercase)
                    await MainActor.run {
                        isConversionRequestInFlight = false
                        self.result = nil
                        self.outputText = result
                    }
                }
                catch {
                    if error is CancellationError { return }
                    await MainActor.run {
                        isConversionRequestInFlight = false
                        errorMessage = error.localizedDescription
                        self.outputText = error.localizedDescription
                    }
                }
            }
        } else {
            let input = inputText
            conversionTask = Task { [weak self, uuidUlid = uuidUlid, input = input] in
                guard let self else { return }
                do {
                    let decoded = try await uuidUlid.decode(input)
                    await MainActor.run {
                        isConversionRequestInFlight = false
                        result = decoded
                        self.outputText = decoded.summary
                    }
                }
                catch {
                    if error is CancellationError { return }
                    await MainActor.run {
                        isConversionRequestInFlight = false
                        self.result = nil
                        errorMessage = error.localizedDescription
                        self.outputText = error.localizedDescription
                    }
                }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

public struct UuidUlidModelView: View {
    @Bindable var model: UuidUlidModel
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.UuidUlid.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.UuidUlid.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: UuidUlidModel) {
        self.model = model
    }

    // MARK: - Reusable Controls

    private var modePicker: some View {
        Picker("Mode", selection: $model.mode) {
            ForEach(UuidUlidModel.Mode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var typePicker: some View {
        Picker("Type", selection: $model.type) {
            ForEach(UuidUlidType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .labelsHidden()
    }

    private var countStepper: some View {
        Stepper("Count \(model.count)", value: $model.count, in: 1...100)
    }

    private var lowercaseToggle: some View {
        Toggle("Lowercase", isOn: $model.lowercase)
    }

    private var actionButton: some View {
        LoadingButton(model.mode == .generate ? "Generate" : "Decode", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                modePicker
                if model.mode == .generate {
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

                    if model.mode == .generate {
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
            Text(model.mode == .generate ? "Input (optional)" : "UUID or ULID")
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
            if model.mode == .decode, let result = model.result {
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
            } else if model.mode == .decode {
                Spacer()
                Text("Enter a UUID or ULID to decode")
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Output")
                    .font(.headline)
                    .padding(.horizontal, 8)
                TextEditor(text: $model.outputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
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

struct UuidUlidView_Previews: PreviewProvider {
    static var previews: some View {
        UuidUlidModelView(model: .init())
    }
}
