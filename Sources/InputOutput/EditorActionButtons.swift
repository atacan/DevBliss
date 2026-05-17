import BlissTheme
import ClipboardClient
import Dependencies
import SwiftUI

#if os(macOS)
    import FilePanelsClient
#endif

public struct PasteFromClipboardButton: View {
    @Dependency(\.clipboard) private var clipboard
    @State private var isAnimating = false

    private let title: String
    private let onPaste: (String) -> Void

    public init(
        _ title: String = "Paste",
        onPaste: @escaping (String) -> Void
    ) {
        self.title = title
        self.onPaste = onPaste
    }

    public var body: some View {
        EditorFooterButton(
            title,
            systemImage: "doc.on.clipboard.fill",
            isAnimating: isAnimating
        ) {
            guard let text = clipboard.getString() else {
                return
            }
            onPaste(text)
            animate()
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])
        .help("Paste from clipboard (Command+Shift+P)")
        .accessibilityLabel("Paste from clipboard")
    }

    private func animate() {
        isAnimating = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            isAnimating = false
        }
    }
}

public struct CopyToClipboardButton: View {
    @Dependency(\.clipboard) private var clipboard
    @State private var isAnimating = false

    private let title: String
    private let text: () -> String

    public init(
        _ title: String = "Copy",
        text: @escaping () -> String
    ) {
        self.title = title
        self.text = text
    }

    public var body: some View {
        EditorFooterButton(
            title,
            systemImage: "doc.on.clipboard",
            isAnimating: isAnimating
        ) {
            clipboard.copyString(text())
            animate()
        }
        .keyboardShortcut("c", modifiers: [.command, .shift])
        .help("Copy to clipboard (Command+Shift+C)")
        .accessibilityLabel("Copy to clipboard")
    }

    private func animate() {
        isAnimating = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            isAnimating = false
        }
    }
}

public struct SaveTextButton: View {
    @State private var isActivitySheetPresented = false

    #if os(macOS)
        @Dependency(\.filePanel) private var filePanel
    #endif

    private let title: String
    private let text: () -> String

    public init(
        _ title: String = "Save As...",
        text: @escaping () -> String
    ) {
        self.title = title
        self.text = text
    }

    public var body: some View {
        EditorFooterButton(title, systemImage: "opticaldiscdrive") {
            save()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .help("Save to disk (Command+Shift+S)")
        .accessibilityLabel("Save to disk")
        #if os(iOS)
            .sheet(isPresented: $isActivitySheetPresented) {
                SaveTextActivityView(
                    isSheetPresented: $isActivitySheetPresented,
                    activityItems: [text()],
                    applicationActivities: []
                )
            }
        #endif
    }

    private func save() {
        #if os(macOS)
            filePanel.saveWithPanel(.init(textToSave: text()))
        #else
            isActivitySheetPresented = true
        #endif
    }
}

#if os(iOS)
    private struct SaveTextActivityView: UIViewControllerRepresentable {
        @Binding var isSheetPresented: Bool
        var activityItems: [Any]
        var applicationActivities: [UIActivity]?

        func makeUIViewController(
            context: UIViewControllerRepresentableContext<SaveTextActivityView>
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
            context: UIViewControllerRepresentableContext<SaveTextActivityView>
        ) {}
    }
#endif
