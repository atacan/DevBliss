import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI
import Textual

@MainActor
@Observable
public final class MarkdownPreviewModel {
    @ObservationIgnored
    @Shared(.toolInput("markdownPreview")) public var inputText = ""

    public enum PreviewStyle: String, CaseIterable, Identifiable {
        case defaultStyle = "Default"
        case gitHub

        public var id: Self { self }
    }

    public var previewStyle: PreviewStyle = .gitHub

    @ObservationIgnored
    @Dependency(\.markdownPreview) private var markdownPreview

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("markdownPreview"))
        self._inputText = inputText
    }

    public init(inputText: String) {
        let input = Shared(wrappedValue: inputText, .toolInput("markdownPreview"))
        self._inputText = input
    }

    public var normalizedMarkdown: String {
        markdownPreview.normalize(inputText)
    }
}

public struct MarkdownPreviewModelView: View {
    @Bindable var model: MarkdownPreviewModel

    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.MarkdownPreview.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.MarkdownPreview.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: MarkdownPreviewModel) {
        self.model = model
    }

    // MARK: - Reusable Controls

    private var stylePicker: some View {
        Picker("Style", selection: $model.previewStyle) {
            ForEach(MarkdownPreviewModel.PreviewStyle.allCases) { style in
                Text(style.rawValue).tag(style)
            }
        }
    }

    private var openInBrowserButton: some View {
        LoadingButton("Open in Browser", isLoading: false) {
            openInBrowser(model.inputText)
        }
        .buttonStyle(.bordered)
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            HStack(spacing: 12) {
                stylePicker
                openInBrowserButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #else
            HStack(spacing: 12) {
                stylePicker
                    .frame(width: 150)
                openInBrowserButton
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #endif

            Divider()

            Split(primary: { inputEditor }, secondary: { previewPane })
                .fraction(fraction)
                .layout(layout)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Markdown")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .font(.system(size: 13, design: .monospaced))
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var previewPane: some View {
        Group {
            if model.inputText.isEmpty {
                ContentUnavailableCompatView()
            } else {
                ScrollView {
                    structuredTextView
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var structuredTextView: some View {
        switch model.previewStyle {
        case .defaultStyle:
            StructuredText(markdown: model.normalizedMarkdown)
                .textual.textSelection(.enabled)
        case .gitHub:
            StructuredText(markdown: model.normalizedMarkdown)
                .textual.structuredTextStyle(.gitHub)
                .textual.textSelection(.enabled)
        }
    }

    private func openInBrowser(_ markdown: String) {
        let html = """
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: -apple-system, sans-serif; margin: 2em auto; max-width: 42em; padding: 0 1em; line-height: 1.5; }
              pre { background: #f6f8fa; border-radius: 6px; padding: 1em; overflow-x: auto; }
              code { background: rgba(175,184,193,0.2); border-radius: 4px; padding: 0.1em 0.3em; }
              pre code { background: none; padding: 0; }
              blockquote { border-left: 0.25em solid #d0d7de; color: #57606a; margin: 0; padding-left: 1em; }
              table { border-collapse: collapse; }
              th, td { border: 1px solid #d0d7de; padding: 0.4em 0.8em; }
            </style>
          </head>
          <body>
        \(markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            )
          </body>
        </html>
        """

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("devbliss-markdown-preview-\(UUID().uuidString).md.html")
        do {
            guard let data = html.data(using: .utf8) else {
                return
            }
            try data.write(to: tempURL)
            #if os(macOS)
            NSWorkspace.shared.open(tempURL)
            #else
            UIApplication.shared.open(tempURL)
            #endif
        } catch {
            #if os(macOS)
            NSSound.beep()
            #endif
        }
    }
}

private struct ContentUnavailableCompatView: View {
    var body: some View {
        ContentUnavailableView(
            "No Markdown",
            systemImage: "doc.richtext",
            description: Text("Enter some Markdown to preview")
        )
    }
}

struct MarkdownPreviewModelView_Previews: PreviewProvider {
    static var previews: some View {
        MarkdownPreviewModelView(model: .init())
    }
}
