import SwiftUI

#if os(macOS)
    import MacSwiftUI
#endif

public struct PlainTextEditorView: View {
    @Binding private var text: String
    private let isActivitySheetPresented: Binding<Bool>

    public init(
        text: Binding<String>,
        isActivitySheetPresented: Binding<Bool> = .constant(false)
    ) {
        self._text = text
        self.isActivitySheetPresented = isActivitySheetPresented
    }

    public var body: some View {
        #if os(macOS)
            PlainMacEditorView(text: $text)
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
        #elseif os(iOS)
            TextEditor(text: $text)
                .font(.monospaced(.body)())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .scrollContentBackground(.hidden)
                .accessibilityTextContentType(SwiftUI.AccessibilityTextContentType.sourceCode)
                .sheet(isPresented: isActivitySheetPresented) {
                    PlainTextEditorActivityView(
                        isSheetPresented: isActivitySheetPresented,
                        activityItems: [text],
                        applicationActivities: []
                    )
                }
        #endif
    }
}

#if os(iOS)
    private struct PlainTextEditorActivityView: UIViewControllerRepresentable {
        @Binding var isSheetPresented: Bool
        var activityItems: [Any]
        var applicationActivities: [UIActivity]?

        func makeUIViewController(
            context: UIViewControllerRepresentableContext<PlainTextEditorActivityView>
        ) -> UIActivityViewController {
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            controller.completionWithItemsHandler = { _, _, _, _ in
                isSheetPresented = false
            }
            return controller
        }

        func updateUIViewController(
            _ uiViewController: UIActivityViewController,
            context: UIViewControllerRepresentableContext<PlainTextEditorActivityView>
        ) {}
    }
#endif
