import SwiftUI

/// A footer bar for editor views containing action buttons
public struct EditorFooterBar<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 16) {
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        #if os(macOS)
        .background(ThemeColor.Background.windowBackground)
        #else
        .background(Color(uiColor: .secondarySystemBackground))
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
            Label(title, systemImage: systemImage)
                .font(.callout)
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .foregroundStyle(isAnimating ? ThemeColor.Text.success : ThemeColor.Text.controlText)
        #else
        .foregroundStyle(isAnimating ? Color.green : Color.primary)
        #endif
    }
}
