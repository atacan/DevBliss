import BlissTheme
import Dependencies
import DependenciesAdditions
import Foundation
import HtmlSwift
import Observation
import SharedModels
import Sharing
import SplitView
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

    @ObservationIgnored
    @Dependency(\.htmlToSwift) private var htmlToSwift
    @ObservationIgnored
    @Dependency(\.syntaxHighlight) private var syntaxHighlight
    @ObservationIgnored
    @Dependency(\.userDefaults) private var userDefaults

    private var conversionTask: Task<Void, Never>?

    public init(dsl: SwiftDSL = .binaryBirds, component: HtmlOutputComponent = .fullHtml) {
        let inputText = Shared(wrappedValue: "", .toolInput("htmlToSwift"))
        let outputText = Shared(wrappedValue: "", .toolOutput("htmlToSwift"))
        self._inputText = inputText
        self._outputText = outputText
        self.dsl = dsl
        self.component = component
        observeSettings()
    }

    public init(input: String, output: String = "") {
        let inputText = Shared(wrappedValue: input, .toolInput("htmlToSwift"))
        let outputText = Shared(wrappedValue: output, .toolOutput("htmlToSwift"))
        self._inputText = inputText
        self._outputText = outputText
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
                    self.$outputText.withLock { $0 = swiftCode }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    self.isConversionRequestInFlight = false
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
}

extension HtmlToSwiftModel: Equatable {
    public static func == (lhs: HtmlToSwiftModel, rhs: HtmlToSwiftModel) -> Bool {
        lhs === rhs
    }
}

public struct HtmlToSwiftModelView: View {
    @Bindable var model: HtmlToSwiftModel

    public init(model: HtmlToSwiftModel) {
        self.model = model
    }

    #if os(iOS)
        private let pickerTitleSpace: CGFloat = 0
    #elseif os(macOS)
        private let pickerTitleSpace: CGFloat = 4
    #endif

    public var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel(NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("DSL Library", bundle: Bundle.module, comment: ""),
                        selection: $model.dsl
                    ) {
                        ForEach(SwiftDSL.allCases) { dsl in
                            Text(dslLibraryName(for: dsl))
                                .tag(dsl)
                        }
                    }
                    .blissMenuPicker(width: 180)

                    ConfigLabel(NSLocalizedString("Component", bundle: Bundle.module, comment: ""))
                    Picker(
                        NSLocalizedString("Component", bundle: Bundle.module, comment: ""),
                        selection: $model.component
                    ) {
                        ForEach(HtmlOutputComponent.allCases) { component in
                            Text(outputComponentPickerName(for: component))
                                .tag(component)
                        }
                    }
                    .blissMenuPicker(width: 160)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            LoadingButton(
                NSLocalizedString("Convert", bundle: Bundle.module, comment: ""),
                isLoading: model.isConversionRequestInFlight
            ) {
                model.convertButtonTouched()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(NSLocalizedString("Convert code (⌘ Return)", bundle: Bundle.module, comment: ""))
            .padding(.vertical, 8)

            Divider()

            Split(primary: { inputEditor }, secondary: { outputEditor })
                .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HtmlToSwift.splitViewFraction))
                .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HtmlToSwift.splitViewLayout))
                .styling(visibleThickness: 2)
        }
        .onAppear {
            model.observeSettings()
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Html")
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
            Text("Swift")
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
