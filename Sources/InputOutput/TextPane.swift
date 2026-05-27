import Foundation
import SharedModels
import SwiftUI

public struct TextPane<Editor: View, LeadingActions: View, TrailingActions: View>: View {
    private let title: String
    private let minHeight: CGFloat
    private let horizontalPadding: CGFloat
    private let editor: Editor
    private let leadingActions: LeadingActions
    private let trailingActions: TrailingActions

    public init(
        title: String,
        minHeight: CGFloat = 220,
        horizontalPadding: CGFloat = 8,
        @ViewBuilder editor: () -> Editor,
        @ViewBuilder leadingActions: () -> LeadingActions,
        @ViewBuilder trailingActions: () -> TrailingActions
    ) {
        self.title = title
        self.minHeight = minHeight
        self.horizontalPadding = horizontalPadding
        self.editor = editor()
        self.leadingActions = leadingActions()
        self.trailingActions = trailingActions()
    }

    public var body: some View {
        PaneView(title: title) {
            editor
                .frame(minHeight: effectiveEditorMinHeight)
                .padding(.horizontal, horizontalPadding)
        } leadingActions: {
            leadingActions
        } trailingActions: {
            trailingActions
        }
    }

    private var effectiveEditorMinHeight: CGFloat {
        #if os(iOS)
            min(minHeight, 96)
        #else
            minHeight
        #endif
    }
}

public extension TextPane where LeadingActions == EmptyView, TrailingActions == EmptyView {
    init(
        title: String,
        minHeight: CGFloat = 220,
        horizontalPadding: CGFloat = 8,
        @ViewBuilder editor: () -> Editor
    ) {
        self.init(
            title: title,
            minHeight: minHeight,
            horizontalPadding: horizontalPadding,
            editor: editor,
            leadingActions: { EmptyView() },
            trailingActions: { EmptyView() }
        )
    }
}

public extension TextPane where LeadingActions == EmptyView {
    init(
        title: String,
        minHeight: CGFloat = 220,
        horizontalPadding: CGFloat = 8,
        @ViewBuilder editor: () -> Editor,
        @ViewBuilder trailingActions: () -> TrailingActions
    ) {
        self.init(
            title: title,
            minHeight: minHeight,
            horizontalPadding: horizontalPadding,
            editor: editor,
            leadingActions: { EmptyView() },
            trailingActions: trailingActions
        )
    }
}

public extension TextPane where TrailingActions == EmptyView {
    init(
        title: String,
        minHeight: CGFloat = 220,
        horizontalPadding: CGFloat = 8,
        @ViewBuilder editor: () -> Editor,
        @ViewBuilder leadingActions: () -> LeadingActions
    ) {
        self.init(
            title: title,
            minHeight: minHeight,
            horizontalPadding: horizontalPadding,
            editor: editor,
            leadingActions: leadingActions,
            trailingActions: { EmptyView() }
        )
    }
}

public struct PlainInputTextPane: View {
    private let title: String
    @Binding private var text: String
    private let minHeight: CGFloat
    private let allowsPaste: Bool
    private let allowsTextFileDrop: Bool

    public init(
        title: String,
        text: Binding<String>,
        minHeight: CGFloat = 220,
        allowsPaste: Bool = true,
        allowsTextFileDrop: Bool = true
    ) {
        self.title = title
        self._text = text
        self.minHeight = minHeight
        self.allowsPaste = allowsPaste
        self.allowsTextFileDrop = allowsTextFileDrop
    }

    public var body: some View {
        TextPane(
            title: title,
            minHeight: minHeight
        ) {
            PlainTextEditorView(text: $text)
                .overlay {
                    if allowsTextFileDrop {
                        DroppedTextFileOverlay { droppedText in
                            text = droppedText
                        }
                    }
                }
        } leadingActions: {
            if allowsPaste {
                PasteFromClipboardButton { pastedText in
                    text = pastedText
                }
            }
        }
    }
}

public struct PlainOutputTextPane: View {
    private let title: String
    @Binding private var text: String
    private let minHeight: CGFloat
    private let allowsCopy: Bool
    private let allowsSave: Bool
    private let onSendToTool: ((Tool) -> Void)?

    public init(
        title: String,
        text: Binding<String>,
        minHeight: CGFloat = 220,
        allowsCopy: Bool = true,
        allowsSave: Bool = true,
        onSendToTool: ((Tool) -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.minHeight = minHeight
        self.allowsCopy = allowsCopy
        self.allowsSave = allowsSave
        self.onSendToTool = onSendToTool
    }

    public var body: some View {
        TextPane(
            title: title,
            minHeight: minHeight
        ) {
            PlainTextEditorView(text: $text)
        } trailingActions: {
            if allowsCopy {
                CopyToClipboardButton {
                    text
                }
            }

            if allowsSave {
                SaveTextButton {
                    text
                }
            }

            if let onSendToTool {
                SendToToolButton { tool in
                    onSendToTool(tool)
                }
            }
        }
    }
}

public struct AttributedOutputTextPane: View {
    private let title: String
    @Binding private var attributedText: NSMutableAttributedString
    private let plainText: () -> String
    private let minHeight: CGFloat
    private let isEditable: Bool
    private let allowsCopy: Bool
    private let allowsSave: Bool
    private let onSendToTool: ((Tool) -> Void)?

    public init(
        title: String,
        attributedText: Binding<NSMutableAttributedString>,
        plainText: @escaping () -> String,
        minHeight: CGFloat = 220,
        isEditable: Bool = true,
        allowsCopy: Bool = true,
        allowsSave: Bool = true,
        onSendToTool: ((Tool) -> Void)? = nil
    ) {
        self.title = title
        self._attributedText = attributedText
        self.plainText = plainText
        self.minHeight = minHeight
        self.isEditable = isEditable
        self.allowsCopy = allowsCopy
        self.allowsSave = allowsSave
        self.onSendToTool = onSendToTool
    }

    public var body: some View {
        TextPane(
            title: title,
            minHeight: minHeight
        ) {
            AttributedTextEditorView(text: $attributedText, isEditable: isEditable)
        } trailingActions: {
            if allowsCopy {
                CopyToClipboardButton {
                    plainText()
                }
            }

            if allowsSave {
                SaveTextButton {
                    plainText()
                }
            }

            if let onSendToTool {
                SendToToolButton { tool in
                    onSendToTool(tool)
                }
            }
        }
    }
}
