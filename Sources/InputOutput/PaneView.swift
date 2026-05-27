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
                    .font(titleFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .padding(.top, titleTextTopPadding)
                Spacer()
            }
            .padding(.horizontal, titleHorizontalPadding)
            .padding(.vertical, titleVerticalPadding)
            .frame(minHeight: titleMinHeight, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(0)

            EditorFooterBar {
                leadingActions
                Spacer()
                trailingActions
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
    }

    private var titleHorizontalPadding: CGFloat {
        #if os(iOS)
            return 8
        #else
            return 16
        #endif
    }

    private var titleVerticalPadding: CGFloat {
        #if os(iOS)
            return 8
        #else
            return 4
        #endif
    }

    private var titleMinHeight: CGFloat {
        #if os(iOS)
            return 40
        #else
            return 0
        #endif
    }

    private var titleTextTopPadding: CGFloat {
        #if os(iOS)
            return 4
        #else
            return 0
        #endif
    }

    private var titleFont: Font {
        #if os(iOS)
            return .subheadline.weight(.semibold)
        #else
            return .headline
        #endif
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
