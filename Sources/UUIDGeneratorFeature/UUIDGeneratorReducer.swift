import BlissTheme
import Dependencies
import Foundation
import SwiftUI
import Sharing

@MainActor
@Observable
public final class UUIDGeneratorModel {
    @ObservationIgnored
    private var task: Task<Void, Never>?

    @ObservationIgnored
    @Dependency(\.uuidGenerator) private var uuidGenerator

    public var count: Int = 1
    public var textCase: TextCase = .upper
    public var outputText: String = ""
    public var isGenerating: Bool = false

    public init() {}

    public init(count: Int, textCase: TextCase = .upper, outputText: String = "") {
        self.count = count
        self.textCase = textCase
        self.outputText = outputText
    }

    public func generateButtonTouched() {
        task?.cancel()
        isGenerating = true

        let count = max(1, min(count, 1_000_000))
        let textCase = self.textCase
        task = Task { [weak self, count, textCase, uuidGenerator = uuidGenerator] in
            do {
                let result = try await uuidGenerator.generating(count, textCase)
                await MainActor.run {
                    guard let self else { return }
                    isGenerating = false
                    outputText = result
                }
            } catch {
                if error is CancellationError {
                    return
                }
                await MainActor.run {
                    guard let self else { return }
                    isGenerating = false
                }
            }
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
        isGenerating = false
    }

    public func clampCount(_ newValue: Int) {
        count = min(max(newValue, 1), 1_000_000)
    }

    public func copyOutput() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        #else
        UIPasteboard.general.string = outputText
        #endif
    }
}

extension UUIDGeneratorModel: Equatable {
    public static func == (lhs: UUIDGeneratorModel, rhs: UUIDGeneratorModel) -> Bool {
        lhs === rhs
    }
}

public struct UUIDGeneratorModelView: View {
    @Bindable var model: UUIDGeneratorModel

    public init(model: UUIDGeneratorModel) {
        self.model = model
    }

    private var countField: some View {
        IntegerTextField(value: Binding(
            get: { model.count },
            set: { model.clampCount($0) }
        ), range: 1 ... 1_000_000)
    }

    private var casePicker: some View {
        Picker("", selection: $model.textCase) {
            Text(NSLocalizedString("lowercase", bundle: Bundle.module, comment: "")).tag(TextCase.lower)
            Text(NSLocalizedString("UPPERCASE", bundle: Bundle.module, comment: "")).tag(TextCase.upper)
        }
    }

    private var generateButton: some View {
        LoadingButton(NSLocalizedString("Generate", bundle: Bundle.module, comment: "")) {
            model.generateButtonTouched()
        }
        .disabled(model.isGenerating)
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                HStack {
                    Text(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    countField
                }
                HStack {
                    Text(NSLocalizedString("Case", bundle: Bundle.module, comment: ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    casePicker
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            generateButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("Count", bundle: Bundle.module, comment: ""))
                    countField
                        .frame(width: 140)

                    ConfigLabel(NSLocalizedString("Case", bundle: Bundle.module, comment: ""))
                    casePicker
                        .blissMenuPicker(width: 140)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                generateButton
                Button {
                    model.copyOutput()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            #endif

            Divider()

            ScrollView {
                Text(model.outputText.isEmpty ? NSLocalizedString("Output will appear here", bundle: Bundle.module, comment: "") : model.outputText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(model.outputText.isEmpty ? .secondary : .primary)
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
                    .padding(16)
            }

            Spacer()
        }
    }
}

public typealias UUIDGeneratorView = UUIDGeneratorModelView

private struct IntegerTextField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Stepper(value: Binding(
                get: { value },
                set: {
                    value = $0.clamped(to: range)
                }
            )) {
                TextField(
                    "",
                    text: Binding(
                        get: { "\(value)" },
                        set: {
                            if let newValue = Int($0) {
                                value = newValue.clamped(to: range)
                            }
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 250)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct UUIDGeneratorModelView_Previews: PreviewProvider {
    static var previews: some View {
        UUIDGeneratorModelView(model: .init())
    }
}
