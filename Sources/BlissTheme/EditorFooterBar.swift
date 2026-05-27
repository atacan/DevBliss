import SwiftUI

/// A footer bar for editor views containing action buttons
public struct EditorFooterBar<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: footerSpacing) {
            content
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, verticalPadding)
        .padding(.bottom, bottomPadding)
        .frame(minHeight: minHeight)
        #if os(macOS)
        .background(ThemeColor.Background.windowBackground)
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
    }

    private var footerSpacing: CGFloat {
        #if os(iOS)
            return 8
        #else
            return 16
        #endif
    }

    private var horizontalPadding: CGFloat {
        #if os(iOS)
            return 8
        #else
            return 12
        #endif
    }

    private var verticalPadding: CGFloat {
        #if os(iOS)
            return 8
        #else
            return 8
        #endif
    }

    private var bottomPadding: CGFloat {
        #if os(iOS)
            return 10
        #else
            return 8
        #endif
    }

    private var minHeight: CGFloat {
        #if os(iOS)
            return 52
        #else
            return 0
        #endif
    }
}

/// A button styled for use in editor footer bars
public struct EditorFooterButton: View {
    let title: String
    let systemImage: String
    let isAnimating: Bool
    let action: () -> Void

    public init(
        _ title: String,
        systemImage: String,
        isAnimating: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isAnimating = isAnimating
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            #if os(iOS)
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            #else
            Label(title, systemImage: systemImage)
                .font(.callout)
            #endif
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .foregroundStyle(isAnimating ? ThemeColor.Text.success : ThemeColor.Text.controlText)
        #else
        .foregroundStyle(isAnimating ? Color.green : Color.primary)
        #endif
    }
}
