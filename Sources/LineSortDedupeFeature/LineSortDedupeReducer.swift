import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import InputOutput
import SwiftUI

@MainActor
@Observable
public final class LineSortDedupeModel {
    @ObservationIgnored
    @Shared(.toolInput("lineSortDedupe"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("lineSortDedupe"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var sortOrder: LineSortOrder = .ascending
    public var removeDuplicates: Bool = true
    public var caseInsensitive: Bool = true
    public var trimWhitespace: Bool = true
    public var removeEmptyLines: Bool = true

    @ObservationIgnored
    @Dependency(\.lineSortDedupe) private var lineSortDedupe

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var config: LineSortDedupeConfig {
        LineSortDedupeConfig(
            sortOrder: sortOrder,
            removeDuplicates: removeDuplicates,
            caseInsensitive: caseInsensitive,
            trimWhitespace: trimWhitespace,
            removeEmptyLines: removeEmptyLines
        )
    }

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("lineSortDedupe"))
        let outputText = Shared(wrappedValue: "", .toolOutput("lineSortDedupe"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("lineSortDedupe"))
        let outputText = Shared(wrappedValue: output, .toolOutput("lineSortDedupe"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = self.config

        conversionTask = Task { [weak self, input = input, config = config, lineSortDedupe = lineSortDedupe] in
            guard let self else { return }
            do {
                let result = try await lineSortDedupe.convert(input, config)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = result }
                }
            }
            catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func setSortOrder(_ value: LineSortOrder) {
        sortOrder = value
    }

    public func setCaseInsensitive(_ value: Bool) {
        caseInsensitive = value
    }

    public func setTrimWhitespace(_ value: Bool) {
        trimWhitespace = value
    }

    public func setRemoveDuplicates(_ value: Bool) {
        removeDuplicates = value
    }

    public func setRemoveEmptyLines(_ value: Bool) {
        removeEmptyLines = value
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

struct LineSortDedupeView_Previews: PreviewProvider {
    static var previews: some View {
        LineSortDedupeModelView(model: .init())
    }
}

public struct LineSortDedupeModelView: View {
    @Bindable var model: LineSortDedupeModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: LineSortDedupeModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    private var configurationView: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                ConfigLabel("Sort by")
                Picker("Order", selection: $model.sortOrder) {
                    ForEach(LineSortOrder.allCases) { order in Text(order.rawValue).tag(order) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
                Toggle("Case-insensitive", isOn: $model.caseInsensitive).toggleStyle(.automatic)
                Toggle("Trim whitespace", isOn: $model.trimWhitespace).toggleStyle(.automatic)
            }
            GridRow {
                ConfigLabel("Options")
                Toggle("Remove duplicates", isOn: $model.removeDuplicates).toggleStyle(.automatic)
                Toggle("Remove empty lines", isOn: $model.removeEmptyLines).toggleStyle(.automatic)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    public var body: some View {
        TwoPaneToolView(
            actionTitle: "Process",
            actionHelp: "Process (⌘ Return)",
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.LineSortDedupe.splitViewFraction,
                layoutKey: SettingsKey.LineSortDedupe.splitViewLayout,
                primaryLabel: "Input",
                secondaryLabel: "Output"
            )
        ) {
            configurationView
        } primary: {
            PlainInputTextPane(title: "Input", text: inputTextBinding)
        } secondary: {
            PlainOutputTextPane(
                title: "Output",
                text: outputTextBinding,
                onSendToTool: sendOutputToTool
            )
        }
    }
    private var sendOutputToTool: ((Tool) -> Void)? {
        guard let onSendOutputToTool else { return nil }
        return { tool in onSendOutputToTool(model.outputText, tool) }
    }

    private var inputTextBinding: Binding<String> {
        Binding(
            get: { model.inputText },
            set: { newValue in model.$inputText.withLock { $0 = newValue } }
        )
    }

    private var outputTextBinding: Binding<String> {
        Binding(
            get: { model.outputText },
            set: { newValue in model.$outputText.withLock { $0 = newValue } }
        )
    }
}
