import BlissTheme
import SwiftUI

public struct SplitSettings {
    public var fractionKey: String
    public var layoutKey: String
    public var defaultFraction: CGFloat
    public var defaultLayout: SideBySideLayout
    public var primaryLabel: String
    public var secondaryLabel: String
    public var showsToolbar: Bool
    public var allowsPrimaryHiding: Bool

    public init(
        fractionKey: String,
        layoutKey: String,
        defaultFraction: CGFloat = 0.5,
        defaultLayout: SideBySideLayout = .horizontal,
        primaryLabel: String = "Primary pane",
        secondaryLabel: String = "Secondary pane",
        showsToolbar: Bool = true,
        allowsPrimaryHiding: Bool = true
    ) {
        self.fractionKey = fractionKey
        self.layoutKey = layoutKey
        self.defaultFraction = defaultFraction
        self.defaultLayout = defaultLayout
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.showsToolbar = showsToolbar
        self.allowsPrimaryHiding = allowsPrimaryHiding
    }
}

public struct TwoPaneToolView<Configuration: View, Primary: View, Secondary: View>: View {
    private let actionTitle: String
    private let actionHelp: String
    private let isLoading: Bool
    private let performAction: () -> Void
    private let splitSettings: SplitSettings
    private let configuration: Configuration
    private let primary: Primary
    private let secondary: Secondary

    public init(
        actionTitle: String,
        actionHelp: String,
        isLoading: Bool,
        performAction: @escaping () -> Void,
        splitSettings: SplitSettings,
        @ViewBuilder configuration: () -> Configuration,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.actionTitle = actionTitle
        self.actionHelp = actionHelp
        self.isLoading = isLoading
        self.performAction = performAction
        self.splitSettings = splitSettings
        self.configuration = configuration()
        self.primary = primary()
        self.secondary = secondary()
    }

    public var body: some View {
        VStack(spacing: 0) {
            configuration

            LoadingButton(actionTitle, isLoading: isLoading) {
                performAction()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help(actionHelp)
            .padding(.vertical, 8)

            Divider()

            SideBySideView(
                fractionKey: splitSettings.fractionKey,
                layoutKey: splitSettings.layoutKey,
                defaultFraction: splitSettings.defaultFraction,
                defaultLayout: splitSettings.defaultLayout,
                primaryLabel: splitSettings.primaryLabel,
                secondaryLabel: splitSettings.secondaryLabel,
                showsToolbar: splitSettings.showsToolbar,
                allowsPrimaryHiding: splitSettings.allowsPrimaryHiding
            ) {
                primary
            } secondary: {
                secondary
            }
        }
    }
}

public extension TwoPaneToolView where Configuration == EmptyView {
    init(
        actionTitle: String,
        actionHelp: String,
        isLoading: Bool,
        performAction: @escaping () -> Void,
        splitSettings: SplitSettings,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.init(
            actionTitle: actionTitle,
            actionHelp: actionHelp,
            isLoading: isLoading,
            performAction: performAction,
            splitSettings: splitSettings,
            configuration: { EmptyView() },
            primary: primary,
            secondary: secondary
        )
    }
}
