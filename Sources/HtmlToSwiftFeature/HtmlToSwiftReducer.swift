import BlissTheme
import Dependencies
import DependenciesAdditions
import Foundation
import HtmlSwift
import InputOutput
import Observation
import SharedModels
import Sharing
import SwiftUI
import SyntaxHighlightClient

@MainActor
@Observable
public final class HtmlToSwiftModel {
    @ObservationIgnored
    @Shared(.toolInput("htmlToSwift")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("htmlToSwift")) public var outputText = ""

    public var isConversionRequestInFlight = false
    public var dsl: SwiftDSL = .binaryBirds
    public var component: HtmlOutputComponent = .fullHtml
    public var outputAttributedText = NSMutableAttributedString()

    @ObservationIgnored
    @Dependency(\.htmlToSwift) private var htmlToSwift
    @ObservationIgnored
    @Dependency(\.syntaxHighlight) private var syntaxHighlight
    @ObservationIgnored
    @Dependency(\.userDefaults) private var userDefaults

    private var conversionTask: Task<Void, Never>?
    private var highlightTask: Task<Void, Never>?
    private static let maxHighlightCharacters = 100_000

    public init(dsl: SwiftDSL = .binaryBirds, component: HtmlOutputComponent = .fullHtml) {
        let inputText = Shared(wrappedValue: "", .toolInput("htmlToSwift"))
        let outputText = Shared(wrappedValue: "", .toolOutput("htmlToSwift"))
        self._inputText = inputText
        self._outputText = outputText
        self.dsl = dsl
        self.component = component
        self.outputAttributedText = .init(attributedString: EditorAttributedStrings.regular(outputText.wrappedValue))
        observeSettings()
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("htmlToSwift"))
        let outputText = Shared(wrappedValue: output, .toolOutput("htmlToSwift"))
        self._inputText = inputText
        self._outputText = outputText
        self.outputAttributedText = .init(attributedString: EditorAttributedStrings.regular(outputText.wrappedValue))
        observeSettings()
    }

    public var outputString: String {
        outputText
    }

    public func observeSettings() {
        if let newDsl: SwiftDSL = userDefaults.rawRepresentable(forKey: SettingsKey.HtmlToSwift.dsl) {
            dsl = newDsl
        }
        if let newComponent: HtmlOutputComponent = userDefaults.rawRepresentable(forKey: SettingsKey.HtmlToSwift.component) {
            component = newComponent
        }
    }

    private func persistSettings() {
        userDefaults.set(dsl, forKey: SettingsKey.HtmlToSwift.dsl)
        userDefaults.set(component, forKey: SettingsKey.HtmlToSwift.component)
    }

    public func setDsl(_ value: SwiftDSL) {
        dsl = value
        persistSettings()
    }

    public func setComponent(_ value: HtmlOutputComponent) {
        component = value
        persistSettings()
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        conversionTask = nil
        highlightTask?.cancel()
        highlightTask = nil

        isConversionRequestInFlight = true
        let input = inputText
        let dsl = self.dsl
        let component = self.component
        let converter = htmlToSwift

        conversionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let swiftCode = try await converter.convert(input, for: dsl, output: component)
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.updateOutput(swiftCode)
                    self.highlightOutputIfNeeded(swiftCode)
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
                    self.updateOutput(
                        error.localizedDescription,
                        attributedText: EditorAttributedStrings.error(error.localizedDescription)
                    )
                }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        highlightTask?.cancel()
        highlightTask = nil
        isConversionRequestInFlight = false
    }

    public func setOutputAttributedText(_ value: NSMutableAttributedString) {
        outputAttributedText = value
        $outputText.withLock { $0 = value.string }
    }

    private func updateOutput(_ text: String, attributedText: NSAttributedString? = nil) {
        $outputText.withLock { $0 = text }
        outputAttributedText = .init(attributedString: attributedText ?? EditorAttributedStrings.regular(text))
    }

    private func highlightOutputIfNeeded(_ swiftCode: String) {
        guard swiftCode.count <= Self.maxHighlightCharacters else {
            return
        }

        let highlighter = syntaxHighlight
        highlightTask?.cancel()
        highlightTask = Task { [weak self] in
            guard let self else { return }
            let highlighted = await highlighter.highlightSwift(swiftCode)
            guard !Task.isCancelled, highlighted.length > 0 else {
                return
            }

            await MainActor.run {
                guard self.outputText == swiftCode else {
                    return
                }
                self.outputAttributedText = .init(attributedString: highlighted)
            }
        }
    }
}

public struct HtmlToSwiftModelView: View {
    @Bindable var model: HtmlToSwiftModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: HtmlToSwiftModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }

    public var body: some View {
        TwoPaneToolView(
            actionTitle: NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
            actionHelp: NSLocalizedString("Convert code (⌘ Return)", bundle: Bundle.module, comment: ""),
            isLoading: model.isConversionRequestInFlight,
            performAction: model.convertButtonTouched,
            splitSettings: .init(
                fractionKey: SettingsKey.HtmlToSwift.splitViewFraction,
                layoutKey: SettingsKey.HtmlToSwift.splitViewLayout,
                defaultLayout: defaultSplitLayout,
                primaryLabel: NSLocalizedString("Html", bundle: Bundle.module, comment: ""),
                secondaryLabel: NSLocalizedString("Swift", bundle: Bundle.module, comment: "")
            )
        ) {
            configurationView
        } primary: {
            PlainInputTextPane(
                title: NSLocalizedString("Html", bundle: Bundle.module, comment: ""),
                text: inputTextBinding
            )
        } secondary: {
            AttributedOutputTextPane(
                title: NSLocalizedString("Swift", bundle: Bundle.module, comment: ""),
                attributedText: outputAttributedTextBinding,
                plainText: { model.outputText },
                onSendToTool: sendOutputToTool
            )
        }
        .onAppear {
            model.observeSettings()
        }
    }

    private var configurationView: some View {
        ViewThatFits(in: .horizontal) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""))
                    dslPicker
                        .blissMenuPicker(width: 180)

                    ConfigLabel(NSLocalizedString("Component", bundle: Bundle.module, comment: ""))
                    componentPicker
                        .blissMenuPicker(width: 160)
                }
            }

            Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    ConfigLabel(NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""))
                    dslPicker
                        .blissMenuPicker(width: 170)
                }

                GridRow {
                    ConfigLabel(NSLocalizedString("Component", bundle: Bundle.module, comment: ""))
                    componentPicker
                        .blissMenuPicker(width: 170)
                }
            }
        }
        .padding(.horizontal, configurationHorizontalPadding)
        .padding(.vertical, configurationVerticalPadding)
    }

    private var dslPicker: some View {
        Picker(
            NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""),
            selection: Binding(
                get: { model.dsl },
                set: { model.setDsl($0) }
            )
        ) {
            ForEach(SwiftDSL.allCases) { dsl in
                Text(dslLibraryName(for: dsl))
                    .tag(dsl)
            }
        }
    }

    private var componentPicker: some View {
        Picker(
            NSLocalizedString("Component", bundle: Bundle.module, comment: ""),
            selection: Binding(
                get: { model.component },
                set: { model.setComponent($0) }
            )
        ) {
            ForEach(HtmlOutputComponent.allCases) { component in
                Text(outputComponentPickerName(for: component))
                    .tag(component)
            }
        }
    }

    private var defaultSplitLayout: SideBySideLayout {
        #if os(iOS)
            return .vertical
        #else
            return .horizontal
        #endif
    }

    private var configurationHorizontalPadding: CGFloat {
        #if os(iOS)
            return 12
        #else
            return 16
        #endif
    }

    private var configurationVerticalPadding: CGFloat {
        #if os(iOS)
            return 6
        #else
            return 8
        #endif
    }

    private var sendOutputToTool: ((Tool) -> Void)? {
        guard let onSendOutputToTool else {
            return nil
        }

        return { tool in
            onSendOutputToTool(model.outputText, tool)
        }
    }

    private var inputTextBinding: Binding<String> {
        Binding(
            get: { model.inputText },
            set: { newValue in model.$inputText.withLock { $0 = newValue } }
        )
    }

    private var outputAttributedTextBinding: Binding<NSMutableAttributedString> {
        Binding(
            get: { model.outputAttributedText },
            set: { model.setOutputAttributedText($0) }
        )
    }

    private func dslLibraryName(for dsl: SwiftDSL) -> String {
        switch dsl {
        case .binaryBirds:
            return NSLocalizedString(
                "Binary Birds",
                bundle: Bundle.module,
                comment: "picker description for which dsl library to use. don't translate."
            )
        case .pointFree:
            return NSLocalizedString(
                "Point﹒Free",
                bundle: Bundle.module,
                comment: "picker description for which dsl library to use. don't translate."
            )
        }
    }

    private func outputComponentPickerName(for component: HtmlOutputComponent) -> String {
        switch component {
        case .fullHtml:
            return NSLocalizedString(
                "Full <html>",
                bundle: Bundle.module,
                comment: "picker description for which html component to output"
            )
        case .onlyBody:
            return NSLocalizedString(
                "Only <body>",
                bundle: Bundle.module,
                comment: "picker description for which html component to output"
            )
        case .onlyHead:
            return NSLocalizedString(
                "Only <head>",
                bundle: Bundle.module,
                comment: "picker description for which html component to output"
            )
        }
    }
}

struct HtmlToSwiftReducer_Previews: PreviewProvider {
    static var previews: some View {
        HtmlToSwiftModelView(model: .init())
    }
}

#if DEBUG
    public struct HtmlToSwiftApp: App {
        public init() {}

        public var body: some Scene {
            WindowGroup {
                HtmlToSwiftModelView(model: .init())
            }
            #if os(macOS)
                .windowStyle(.titleBar)
                .windowToolbarStyle(.unified(showsTitle: true))
            #endif
        }
    }

#endif
