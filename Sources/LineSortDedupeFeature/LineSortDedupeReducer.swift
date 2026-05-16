import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
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

extension LineSortDedupeModel: Equatable {
    public static func == (lhs: LineSortDedupeModel, rhs: LineSortDedupeModel) -> Bool {
        lhs === rhs
    }
}

struct LineSortDedupeView_Previews: PreviewProvider {
    static var previews: some View {
        LineSortDedupeModelView(model: .init())
    }
}

public struct LineSortDedupeModelView: View {
    @Bindable var model: LineSortDedupeModel

    public init(model: LineSortDedupeModel) {
        self.model = model
    }

    private var sortOrderPicker: some View {
        Picker("Order", selection: $model.sortOrder) {
            ForEach(LineSortOrder.allCases) { order in
                Text(order.rawValue)
                    .tag(order)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var caseInsensitiveToggle: some View {
        Toggle("Case-insensitive", isOn: $model.caseInsensitive)
    }

    private var trimWhitespaceToggle: some View {
        Toggle("Trim whitespace", isOn: $model.trimWhitespace)
    }

    private var removeDuplicatesToggle: some View {
        Toggle("Remove duplicates", isOn: $model.removeDuplicates)
    }

    private var removeEmptyLinesToggle: some View {
        Toggle("Remove empty lines", isOn: $model.removeEmptyLines)
    }

    private var processButton: some View {
        LoadingButton("Process", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Process (⌘ Return)")
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 10) {
                sortOrderPicker
                caseInsensitiveToggle
                trimWhitespaceToggle
                removeDuplicatesToggle
                removeEmptyLinesToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            processButton
                .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Sort by")
                    sortOrderPicker
                        .frame(width: 200)
                    caseInsensitiveToggle
                        .toggleStyle(.checkbox)
                    trimWhitespaceToggle
                        .toggleStyle(.checkbox)
                }

                GridRow {
                    ConfigLabel("Options")
                    removeDuplicatesToggle
                        .toggleStyle(.checkbox)
                    removeEmptyLinesToggle
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            processButton
                .padding(.vertical, 8)
            #endif

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.LineSortDedupe.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.LineSortDedupe.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Output")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.outputText },
                set: { newValue in model.$outputText.withLock { $0 = newValue } }
            ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }
}
