import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class SwiftPrettyModel {
    @ObservationIgnored
    @Shared(.toolInput("swiftPretty")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("swiftPretty")) public var outputText = ""

    public var lockwoodConfig = blissConfigLockwood
    public var useLockwood: Bool
    public var isConversionRequestInFlight = false

    @ObservationIgnored
    @Dependency(\.swiftPretty) private var swiftPretty

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public init(lockwoodConfig: String = blissConfigLockwood, useLockwood: Bool = true) {
        let inputText = Shared(wrappedValue: "", .toolInput("swiftPretty"))
        let outputText = Shared(wrappedValue: "", .toolOutput("swiftPretty"))
        self._inputText = inputText
        self._outputText = outputText
        self.lockwoodConfig = lockwoodConfig
        self.useLockwood = useLockwood
    }

    public init(
        input: String,
        output: String = "",
        lockwoodConfig: String = blissConfigLockwood,
        useLockwood: Bool = true
    ) {
        let inputText = Shared(wrappedValue: input, .toolInput("swiftPretty"))
        let outputText = Shared(wrappedValue: output, .toolOutput("swiftPretty"))
        self._inputText = inputText
        self._outputText = outputText
        self.lockwoodConfig = lockwoodConfig
        self.useLockwood = useLockwood
    }

    public func setLockwoodConfig(_ value: String) {
        lockwoodConfig = value
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        isConversionRequestInFlight = true
        let input = inputText
        let config = lockwoodConfig

        conversionTask = Task { [weak self, input = input, config = config, swiftPretty = swiftPretty] in
            guard let self else { return }
            do {
                let swiftCode = try await swiftPretty.convert(config, input)
                await MainActor.run {
                    isConversionRequestInFlight = false
                    $outputText.withLock { $0 = swiftCode }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    $outputText.withLock { $0 = "\(error)" }
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

public struct SwiftPrettyModelView: View {
    @Bindable var model: SwiftPrettyModel
    @State var configIsExpanded = true

    public init(model: SwiftPrettyModel) {
        self.model = model
    }

    public var body: some View {
        VSplit {
            VStack {
                lockwoodEditor
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                LoadingButton(
                    NSLocalizedString("Format", bundle: Bundle.module, comment: ""),
                    isLoading: model.isConversionRequestInFlight
                ) {
                    model.convertButtonTouched()
                }
                .padding(.bottom)
                .keyboardShortcut(.return, modifiers: [.command])
                .help(NSLocalizedString("Format code (Cmd+Return)", bundle: Bundle.module, comment: ""))
            }
        } bottom: {
            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.SwiftPretty.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.SwiftPretty.splitViewLayout))
                .styling(visibleThickness: 2)
        }
    }

    var lockwoodEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("nicklockwood/SwiftFormat Config", bundle: Bundle.module, comment: ""))
                .font(.headline)

            TextEditor(text: Binding(
                get: { model.lockwoodConfig },
                set: { model.setLockwoodConfig($0) }
            ))
            .font(.system(.body, design: .monospaced))
            .padding(4)
            .frame(minHeight: 120)
            .background(ThemeColor.Background.textBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ThemeColor.Background.separator, lineWidth: 1)
            )
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Raw", bundle: Bundle.module, comment: ""))
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
            Text(NSLocalizedString("Pretty", bundle: Bundle.module, comment: ""))
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

// preview
struct SwiftPrettyModel_Previews: PreviewProvider {
    static var previews: some View {
        SwiftPrettyModelView(model: .init())
    }
}

public let blissConfigLockwood = """
    --acronyms ID,URL,UUID
    --allman false
    --assetliterals visual-width
    --asynccapturing
    --beforemarks
    --binarygrouping 4,8
    --categorymark "MARK: %c"
    --classthreshold 0
    --closingparen balanced
    --closurevoid remove
    --commas always
    --conflictmarkers reject
    --decimalgrouping 3,6
    --elseposition same-line
    --emptybraces no-space
    --enumnamespaces always
    --enumthreshold 0
    --exponentcase lowercase
    --exponentgrouping disabled
    --extensionacl on-declarations
    --extensionlength 0
    --extensionmark "MARK: - %t + %c"
    --fractiongrouping disabled
    --fragment false
    --funcattributes prev-line
    --generictypes
    --groupedextension "MARK: %c"
    --guardelse auto
    --header strip
    --hexgrouping 4,8
    --hexliteralcase uppercase
    --ifdef no-indent
    --importgrouping alpha
    --indent 4
    --indentcase false
    --indentstrings false
    --lifecycle
    --lineaftermarks true
    --linebreaks lf
    --markcategories false
    --markextensions always
    --marktypes always
    --maxwidth 120
    --modifierorder
    --nevertrailing
    --nospaceoperators
    --nowrapoperators
    --octalgrouping 4,8
    --operatorfunc spaced
    --organizetypes actor,class,enum,struct
    --patternlet hoist
    --ranges spaced
    --redundanttype infer-locals-only
    --self init-only
    --selfrequired
    --semicolons inline
    --shortoptionals always
    --smarttabs enabled
    --someAny true
    --stripunusedargs always
    --structthreshold 0
    --tabwidth unspecified
    --throwcapturing
    --disable trailingclosures
    --trimwhitespace always
    --typeattributes prev-line
    --typeblanklines remove
    --typemark "MARK: - %t"
    --varattributes preserve
    --voidtype void
    --wraparguments before-first
    --wrapcollections before-first
    --wrapconditions after-first
    --wrapeffects preserve
    --wrapenumcases always
    --wrapparameters default
    --wrapreturntype preserve
    --wrapternary default
    --wraptypealiases preserve
    --xcodeindentation disabled
    --yodaswap always
    --disable enumNamespaces,unusedArguments,wrapMultilineStatementBraces
    --enable blankLineAfterImports,isEmpty,sortedSwitchCases,wrapConditionalBodies,wrapEnumCases,wrapSwitchCases
"""
