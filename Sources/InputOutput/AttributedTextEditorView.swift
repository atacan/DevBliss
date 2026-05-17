import SwiftUI

#if os(macOS)
    import MacSwiftUI
#endif

public struct AttributedTextEditorView: View {
    @Binding private var text: NSMutableAttributedString
    private let isEditable: Bool

    public init(
        text: Binding<NSMutableAttributedString>,
        isEditable: Bool = true
    ) {
        self._text = text
        self.isEditable = isEditable
    }

    public var body: some View {
        #if os(macOS)
            MacEditorView(text: $text, hasHorizontalScroll: false, isEditable: isEditable)
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
        #elseif os(iOS)
            if isEditable {
                TextEditor(
                    text: Binding(
                        get: { text.string },
                        set: { text = .init(attributedString: EditorAttributedStrings.regular($0)) }
                    )
                )
                .font(.monospaced(.body)())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .scrollContentBackground(.hidden)
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
            }
            else {
                ScrollView {
                    Text(AttributedString(text))
                        .font(.monospaced(.body)())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
                }
            }
        #endif
    }
}
