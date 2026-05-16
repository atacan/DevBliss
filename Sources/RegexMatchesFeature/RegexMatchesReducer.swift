import BlissTheme
import CoreGraphics
import Dependencies
import DependenciesAdditions
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class RegexMatchesModel {
    @ObservationIgnored
    @Shared(.toolInput("regexMatches")) public var inputText = ""
    @ObservationIgnored
    @Shared(.toolOutput("regexMatches")) public var outputText = ""
    @ObservationIgnored
    @Shared(.toolOutputSecond("regexMatches")) public var outputSecondText = ""

    public var regexPattern: String = ""
    public var isConversionRequestInFlight = false

    @ObservationIgnored
    @Dependency(\.regexMatches) private var regexMatches
    @ObservationIgnored
    @Dependency(\.userDefaults) private var userDefaults
    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init() {
        self._inputText = Shared(wrappedValue: "", .toolInput("regexMatches"))
        self._outputText = Shared(wrappedValue: "", .toolOutput("regexMatches"))
        self._outputSecondText = Shared(wrappedValue: "", .toolOutputSecond("regexMatches"))
    }

    public init(input: String, output: String = "") {
        self._inputText = Shared(wrappedValue: input, .toolInput("regexMatches"))
        self._outputText = Shared(wrappedValue: output, .toolOutput("regexMatches"))
        self._outputSecondText = Shared(wrappedValue: "", .toolOutputSecond("regexMatches"))
    }

    public func observeSettings() {
        if let newRegexPattern = userDefaults.string(forKey: SettingsKey.regexPattern.rawValue) {
            regexPattern = newRegexPattern
        }
    }

    public func setRegexPattern(_ pattern: String) {
        regexPattern = pattern
        userDefaults.set(pattern, forKey: SettingsKey.regexPattern.rawValue)
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let regexPattern = self.regexPattern

        conversionTask = Task { [weak self, regexMatches = regexMatches, input = input, regexPattern = regexPattern] in
            guard let self else { return }
            do {
                let config = RegexMatchesConfig(
                    wholeMatchColor: ThemeColor.Text.highlightedTextSecondary,
                    capturedGroupColor: ThemeColor.Text.highlightedTextPrimary
                )
                let result = try await regexMatches.matches(NSAttributedString(string: input), regexPattern, config)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = result.output.flatMap(\.capturedGroups).joined(separator: "\n") }
                    self.$outputSecondText.withLock { $0 = result.output.map(\.wholeMatch).joined(separator: "\n") }
                }
            } catch {
                if error is CancellationError {
                    return
                }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.$outputText.withLock { $0 = "\(error)" }
                    self.$outputSecondText.withLock { $0 = "" }
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

public struct RegexMatchesModelView: View {
    @Bindable var model: RegexMatchesModel

    public init(model: RegexMatchesModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField(
                    NSLocalizedString("Regex pattern", bundle: Bundle.module, comment: ""),
                    text: Binding(
                        get: { model.regexPattern },
                        set: { model.setRegexPattern($0) }
                    )
                )
                .font(.monospaced(.body)())
                .autocorrectionDisabled()
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
                .blissTextField()
                .onSubmit {
                    model.convertButtonTouched()
                }

                LoadingButton(
                    NSLocalizedString("Extract", bundle: Bundle.module, comment: ""),
                    isLoading: model.isConversionRequestInFlight
                ) {
                    model.convertButtonTouched()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Extract matches (⌘ Return)", bundle: Bundle.module, comment: ""))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditors })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.regexMatchesSplitViewFraction.rawValue))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.regexMatchesSplitViewLayout.rawValue))
                .styling(visibleThickness: 2)
        }
        .onAppear {
            model.observeSettings()
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Input", bundle: Bundle.module, comment: ""))
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
    }

    private var outputEditors: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("Capturing Groups", bundle: Bundle.module, comment: ""))
                    .font(.headline)
                    .padding(.horizontal, 8)

                TextEditor(text: Binding(
                    get: { model.outputText },
                    set: { newValue in model.$outputText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }

            Divider().padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("Matches", bundle: Bundle.module, comment: ""))
                    .font(.headline)
                    .padding(.horizontal, 8)

                TextEditor(text: Binding(
                    get: { model.outputSecondText },
                    set: { newValue in model.$outputSecondText.withLock { $0 = newValue } }
                ))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
            }
        }
    }
}

// preview
struct RegexMatchesModel_Previews: PreviewProvider {
    static var previews: some View {
        RegexMatchesModelView(model: .init())
    }
}

enum SettingsKey: String {
    case regexPattern = "RegexMatches_regexPattern"
    case regexMatchesSplitViewLayout = "RegexMatches_splitViewLayout"
    case regexMatchesSplitViewFraction = "RegexMatches_splitViewFraction"
}

public typealias RegexMatchesView = RegexMatchesModelView
