import BlissTheme
import SwiftUI

public struct PaneView<Content: View, LeadingActions: View, TrailingActions: View>: View {
    private let title: String
    private let content: Content
    private let leadingActions: LeadingActions
    private let trailingActions: TrailingActions

    public init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder leadingActions: () -> LeadingActions,
        @ViewBuilder trailingActions: () -> TrailingActions
    ) {
        self.title = title
        self.content = content()
        self.leadingActions = leadingActions()
        self.trailingActions = trailingActions()
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            EditorFooterBar {
                leadingActions
                Spacer()
                trailingActions
            }
        }
    }
}

public extension PaneView where LeadingActions == EmptyView, TrailingActions == EmptyView {
    init(title: String, @ViewBuilder content: () -> Content) {
        self.init(
            title: title,
            content: content,
            leadingActions: { EmptyView() },
            trailingActions: { EmptyView() }
        )
    }
}

public extension PaneView where LeadingActions == EmptyView {
    init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailingActions: () -> TrailingActions
    ) {
        self.init(
            title: title,
            content: content,
            leadingActions: { EmptyView() },
            trailingActions: trailingActions
        )
    }
}

public extension PaneView where TrailingActions == EmptyView {
    init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder leadingActions: () -> LeadingActions
    ) {
        self.init(
            title: title,
            content: content,
            leadingActions: leadingActions,
            trailingActions: { EmptyView() }
        )
    }
}
