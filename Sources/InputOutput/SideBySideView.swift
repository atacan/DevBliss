import SplitView
import SwiftUI

public enum SideBySideLayout {
    case horizontal
    case vertical

    fileprivate var splitLayout: SplitLayout {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}

public struct SideBySideView<Primary: View, Secondary: View>: View {
    private let fraction: FractionHolder
    @StateObject private var layout: LayoutHolder
    @StateObject private var hide = SideHolder()

    private let primaryLabel: String
    private let secondaryLabel: String
    private let showsToolbar: Bool
    private let allowsPrimaryHiding: Bool
    private let splitterThickness: CGFloat
    private let primary: () -> Primary
    private let secondary: () -> Secondary

    public init(
        fractionKey: String,
        layoutKey: String,
        defaultFraction: CGFloat = 0.5,
        defaultLayout: SideBySideLayout = .horizontal,
        primaryLabel: String = "Primary pane",
        secondaryLabel: String = "Secondary pane",
        showsToolbar: Bool = true,
        allowsPrimaryHiding: Bool = true,
        splitterThickness: CGFloat = 2,
        @ViewBuilder primary: @escaping () -> Primary,
        @ViewBuilder secondary: @escaping () -> Secondary
    ) {
        self.fraction = FractionHolder.usingUserDefaults(defaultFraction, key: fractionKey)
        self._layout = StateObject(
            wrappedValue: LayoutHolder.usingUserDefaults(defaultLayout.splitLayout, preservingDefaultFor: layoutKey)
        )
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.showsToolbar = showsToolbar
        self.allowsPrimaryHiding = allowsPrimaryHiding
        self.splitterThickness = splitterThickness
        self.primary = primary
        self.secondary = secondary
    }

    public var body: some View {
        Split(primary: primary, secondary: secondary)
            .fraction(fraction)
            .layout(layout)
            .hide(hide)
            .styling(visibleThickness: splitterThickness)
            .toolbar {
                if showsToolbar {
                    ToolbarItemGroup {
                        SideBySideToolbarItems(
                            layout: layout,
                            hide: hide,
                            primaryLabel: primaryLabel,
                            secondaryLabel: secondaryLabel,
                            allowsPrimaryHiding: allowsPrimaryHiding
                        )
                    }
                }
            }
    }
}

private struct SideBySideToolbarItems: View {
    @ObservedObject var layout: LayoutHolder
    @ObservedObject var hide: SideHolder

    let primaryLabel: String
    let secondaryLabel: String
    let allowsPrimaryHiding: Bool

    var body: some View {
        Button {
            withAnimation {
                layout.toggle()
            }
        } label: {
            Image(systemName: layout.isHorizontal ? "rectangle.split.1x2" : "rectangle.split.2x1")
        }
        .keyboardShortcut(KeyEquivalent("a"), modifiers: [.command, .shift])
        .disabled(hide.side != nil)
        .help(layout.isHorizontal ? "Stack panes vertically" : "Place panes side-by-side")
        .accessibilityLabel(layout.isHorizontal ? "Stack panes vertically" : "Place panes side-by-side")
        .accessibilityHint(
            layout.isHorizontal
                ? "\(primaryLabel) and \(secondaryLabel) will be positioned one above the other"
                : "\(primaryLabel) and \(secondaryLabel) will be positioned next to each other"
        )

        if allowsPrimaryHiding {
            Button {
                withAnimation {
                    if hide.side == nil {
                        hide.hide(.primary)
                    }
                    else {
                        hide.toggle()
                    }
                }
            } label: {
                if hide.side == nil {
                    Image(
                        systemName: layout.isHorizontal
                            ? "rectangle.lefthalf.inset.filled.arrow.left"
                            : "dock.arrow.up.rectangle"
                    )
                }
                else {
                    Image(
                        systemName: layout.isHorizontal
                            ? "rectangle.righthalf.inset.filled.arrow.right"
                            : "dock.arrow.down.rectangle"
                    )
                }
            }
            .keyboardShortcut(KeyEquivalent("l"), modifiers: [.command, .option])
            .help(hide.side == nil ? "Hide \(primaryLabel)" : "Show \(primaryLabel)")
            .accessibilityLabel(hide.side == nil ? "Hide \(primaryLabel)" : "Show \(primaryLabel)")
        }
    }
}

private extension LayoutHolder {
    static func usingUserDefaults(_ defaultLayout: SplitLayout, preservingDefaultFor key: String) -> LayoutHolder {
        LayoutHolder(
            defaultLayout,
            getter: {
                guard
                    let value = UserDefaults.standard.value(forKey: key) as? String,
                    let persistedLayout = SplitLayout(rawValue: value)
                else {
                    return defaultLayout
                }
                return persistedLayout
            },
            setter: { layout in
                UserDefaults.standard.set(layout.rawValue, forKey: key)
            }
        )
    }
}
