import BlissTheme
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct UrlParserView: View {
    @Bindable var model: UrlParserModel

    public init(model: UrlParserModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Enter URL", text: Binding(
                    get: { model.inputText },
                    set: { model.parseInputChanged($0) }
                ))
                    .blissTextField()
                    .onSubmit {
                        model.parseButtonTouched()
                    }

                LoadingButton("Parse", isLoading: false) {
                    model.parseButtonTouched()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Parse (⌘ Return)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Toggle("Auto-detect", isOn: $model.autoDetect)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .help("Automatically parse when URL includes multiple query items")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            if let result = model.result {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 16)], spacing: 16) {
                        ResultCard(title: "Protocol", value: result.scheme, icon: "chevron.left.forwardslash.chevron.right")
                        ResultCard(title: "Host", value: result.host, icon: "globe")
                        ResultCard(title: "Port", value: result.port.isEmpty ? "-" : result.port, icon: "number")
                        ResultCard(title: "Path", value: result.path.isEmpty ? "/" : result.path, icon: "folder")
                        ResultCard(title: "File", value: result.fileName.isEmpty ? "-" : result.fileName, icon: "doc")
                        ResultCard(title: "Fragment", value: result.fragment.isEmpty ? "-" : result.fragment, icon: "number")
                        ResultCard(title: "Query JSON", value: result.queryJSON, icon: "curlybraces")
                    }
                    .padding()
                }
            } else {
                Spacer()
                Text("Enter a URL to see parsed components")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
}

public typealias UrlParserModelView = UrlParserView

private struct ResultCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    #else
                    UIPasteboard.general.string = value
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
            }

            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct UrlParserView_Previews: PreviewProvider {
    static var previews: some View {
        UrlParserView(model: .init())
    }
}

