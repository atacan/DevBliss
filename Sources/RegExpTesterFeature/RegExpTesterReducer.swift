import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class RegExpTesterModel {
    @ObservationIgnored
    @Shared(.toolInput("regExpTester")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("regExpTester")) public var outputText = ""

    public var pattern: String = ""
    public var replacement: String = ""
    public var options: RegExpOptions = .init()
    public var matches: [RegExpMatch] = []
    public var selectedMatchIndex: Int = 0
    public var errorMessage: String?
    public var isConversionRequestInFlight = false

    @ObservationIgnored
    @Dependency(\.regExpTester) private var regExpTester

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("regExpTester"))
        let outputText = Shared(wrappedValue: "", .toolOutput("regExpTester"))
        self._inputText = inputText
        self._outputText = outputText
    }

    public init(inputText: String, outputText: String = "") {
        let input = Shared(wrappedValue: inputText, .toolInput("regExpTester"))
        let output = Shared(wrappedValue: outputText, .toolOutput("regExpTester"))
        self._inputText = input
        self._outputText = output
    }

    var selectedMatch: RegExpMatch? {
        guard !matches.isEmpty else { return nil }
        let index = min(max(selectedMatchIndex, 0), matches.count - 1)
        return matches[index]
    }

    public func testButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        errorMessage = nil
        let request = RegExpTestRequest(
            pattern: pattern,
            text: inputText,
            replacement: replacement,
            options: options
        )

        conversionTask = Task { [weak self, request = request, regExpTester = regExpTester] in
            guard let self else { return }
            do {
                let result = try regExpTester.test(request)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.matches = result.matches
                    self.selectedMatchIndex = result.matches.isEmpty ? 0 : min(self.selectedMatchIndex, result.matches.count - 1)
                    self.$outputText.withLock { $0 = result.replacedText }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.matches = []
                    self.errorMessage = error.localizedDescription
                    self.$outputText.withLock { $0 = error.localizedDescription }
                }
            }
        }
    }

    public func nextMatchButtonTouched() {
        guard !matches.isEmpty else { return }
        selectedMatchIndex = (selectedMatchIndex + 1) % matches.count
    }

    public func previousMatchButtonTouched() {
        guard !matches.isEmpty else { return }
        selectedMatchIndex = (selectedMatchIndex - 1 + matches.count) % matches.count
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

extension RegExpTesterModel: Equatable {
    public static func == (lhs: RegExpTesterModel, rhs: RegExpTesterModel) -> Bool {
        lhs === rhs
    }
}

public struct RegExpTesterModelView: View {
    @Bindable var model: RegExpTesterModel

    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.RegExpTester.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.RegExpTester.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: RegExpTesterModel) {
        self.model = model
    }

    // MARK: - Reusable Controls

    private var patternField: some View {
        TextField("Enter regex pattern", text: $model.pattern)
            .blissTextField()
    }

    private var testButton: some View {
        LoadingButton("Test", isLoading: model.isConversionRequestInFlight) {
            model.testButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Test (⌘ Return)")
    }

    private var replacementField: some View {
        TextField("Replacement pattern", text: $model.replacement)
            .blissTextField()
    }

    private var matchNavigation: some View {
        HStack(spacing: 8) {
            Button {
                model.previousMatchButtonTouched()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            Text(matchCounterText)
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                model.nextMatchButtonTouched()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
    }

    private var caseInsensitiveToggle: some View {
        Toggle("Case insensitive", isOn: $model.options.caseInsensitive)
    }

    private var allowCommentsToggle: some View {
        Toggle("Allow comments", isOn: $model.options.allowCommentsAndWhitespace)
    }

    private var dotMatchesToggle: some View {
        Toggle("Dot matches newlines", isOn: $model.options.dotMatchesLineSeparators)
    }

    private var multilineToggle: some View {
        Toggle("Multiline", isOn: $model.options.anchorsMatchLines)
    }

    private var unicodeBoundariesToggle: some View {
        Toggle("Unicode boundaries", isOn: $model.options.useUnicodeWordBoundaries)
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    patternField
                    testButton
                }
                HStack(spacing: 8) {
                    replacementField
                    matchNavigation
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Options")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    caseInsensitiveToggle
                    allowCommentsToggle
                    dotMatchesToggle
                    multilineToggle
                    unicodeBoundariesToggle
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Pattern")
                    patternField
                        .gridCellColumns(2)
                    testButton
                }

                GridRow {
                    ConfigLabel("Replace")
                    replacementField
                        .gridCellColumns(2)
                    matchNavigation
                }

                GridRow {
                    ConfigLabel("Options")
                    HStack(spacing: 16) {
                        caseInsensitiveToggle
                        allowCommentsToggle
                        dotMatchesToggle
                        multilineToggle
                        unicodeBoundariesToggle
                    }
                    .toggleStyle(.checkbox)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #endif

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            Split(primary: { inputEditor }, secondary: { outputPane })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Test Text")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var outputPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Matches")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if model.matches.isEmpty {
                        Text("No matches")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(model.matches) { match in
                            Text(matchLine(for: match))
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(match.id == model.selectedMatchIndex ? Color.accentColor.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Replaced Text")
                    .font(.headline)
                    .padding(.horizontal, 8)

                TextEditor(text: Binding(
                    get: { model.outputText },
                    set: { newValue in model.$outputText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
        }
    }

    private var matchCounterText: String {
        guard !model.matches.isEmpty else { return "0 matches" }
        return "\(model.selectedMatchIndex + 1) of \(model.matches.count)"
    }

    private func matchLine(for match: RegExpMatch) -> String {
        "[\(match.id)] \(match.value)"
    }
}

// preview
struct RegExpTesterModel_Previews: PreviewProvider {
    static var previews: some View {
        RegExpTesterModelView(model: .init())
    }
}

public typealias RegExpTesterView = RegExpTesterModelView
