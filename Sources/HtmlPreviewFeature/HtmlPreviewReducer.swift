import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
public final class HtmlPreviewModel {
    @ObservationIgnored
    @Shared(.toolInput("htmlPreview")) public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("htmlPreview")) public var outputText = ""

    public var enableJavaScript: Bool = true
    public var allowLinkNavigation: Bool = true
    public var allowNetwork: Bool = false

    @ObservationIgnored
    @Dependency(\.htmlPreview) private var htmlPreview

    public init() {
        let inputText = Shared(wrappedValue: "", .toolInput("htmlPreview"))
        let outputText = Shared(wrappedValue: "", .toolOutput("htmlPreview"))

        self._inputText = inputText
        self._outputText = outputText
    }

    public init(inputText: String, outputText: String = "") {
        let input = Shared(wrappedValue: inputText, .toolInput("htmlPreview"))
        let output = Shared(wrappedValue: outputText, .toolOutput("htmlPreview"))

        self._inputText = input
        self._outputText = output
    }

    public var normalizedHTML: String {
        htmlPreview.normalize(inputText)
    }
}

public struct HtmlPreviewModelView: View {
    @Bindable var model: HtmlPreviewModel
    @StateObject private var webViewStore = HtmlPreviewWebViewStore()

    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HtmlPreview.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HtmlPreview.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: HtmlPreviewModel) {
        self.model = model
    }

    // MARK: - Reusable Controls

    private var enableJavaScriptToggle: some View {
        Toggle("Enable JavaScript", isOn: $model.enableJavaScript)
    }

    private var allowLinkNavigationToggle: some View {
        Toggle("Allow link navigation", isOn: $model.allowLinkNavigation)
    }

    private var allowNetworkToggle: some View {
        Toggle("Allow network", isOn: $model.allowNetwork)
    }

    private var openInBrowserButton: some View {
        LoadingButton("Open in Browser", isLoading: false) {
            openInBrowser(model.inputText)
        }
        .buttonStyle(.bordered)
    }

    private var reloadButton: some View {
        LoadingButton("Reload", isLoading: false) {
            webViewStore.reload(html: model.inputText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            VStack(spacing: 8) {
                enableJavaScriptToggle
                allowLinkNavigationToggle
                allowNetworkToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #else
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    enableJavaScriptToggle
                        .toggleStyle(.checkbox)
                    allowLinkNavigationToggle
                        .toggleStyle(.checkbox)
                    allowNetworkToggle
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #endif

            HStack(spacing: 12) {
                openInBrowserButton
                reloadButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

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
            Text("HTML")
                .font(.headline)
                .padding(.horizontal, 8)

            TextEditor(text: Binding(
                get: { model.inputText },
                set: { newValue in model.$inputText.withLock { $0 = newValue } }
            ))
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
        }
    }

    private var previewPane: some View {
        let settings = HtmlPreviewWebViewSettings(
            javaScriptEnabled: model.enableJavaScript,
            allowLinkNavigation: model.allowLinkNavigation,
            allowNetwork: model.allowNetwork
        )

        return HtmlPreviewWebView(
            html: model.inputText,
            settings: settings,
            webViewStore: webViewStore
        )
        .id(settings.cacheKey)
    }

    private func openInBrowser(_ html: String) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("devbliss-preview-\(UUID().uuidString).html")
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

struct HtmlPreviewModelView_Previews: PreviewProvider {
    static var previews: some View {
        HtmlPreviewModelView(model: .init())
    }
}

struct HtmlPreviewWebViewSettings: Equatable {
    var javaScriptEnabled: Bool
    var allowLinkNavigation: Bool
    var allowNetwork: Bool

    var cacheKey: String {
        "\(javaScriptEnabled)-\(allowLinkNavigation)-\(allowNetwork)"
    }
}

final class HtmlPreviewWebViewStore: ObservableObject {
    fileprivate var webView: WKWebView?

    func reload(html: String) {
        webView?.loadHTMLString(html, baseURL: nil)
    }
}

struct HtmlPreviewWebView: View {
    let html: String
    let settings: HtmlPreviewWebViewSettings
    let webViewStore: HtmlPreviewWebViewStore

    var body: some View {
        HtmlPreviewWebViewRepresentable(html: html, settings: settings, webViewStore: webViewStore)
    }
}

#if os(macOS)
struct HtmlPreviewWebViewRepresentable: NSViewRepresentable {
    let html: String
    let settings: HtmlPreviewWebViewSettings
    let webViewStore: HtmlPreviewWebViewStore

    func makeCoordinator() -> Coordinator {
        Coordinator(settings: settings)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = settings.javaScriptEnabled
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webViewStore.webView = webView
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.settings = settings
        nsView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var settings: HtmlPreviewWebViewSettings

        init(settings: HtmlPreviewWebViewSettings) {
            self.settings = settings
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if !settings.allowNetwork, let url = navigationAction.request.url, isNetworkURL(url) {
                decisionHandler(.cancel)
                return
            }

            if !settings.allowLinkNavigation, navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
#else
struct HtmlPreviewWebViewRepresentable: UIViewRepresentable {
    let html: String
    let settings: HtmlPreviewWebViewSettings
    let webViewStore: HtmlPreviewWebViewStore

    func makeCoordinator() -> Coordinator {
        Coordinator(settings: settings)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = settings.javaScriptEnabled
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webViewStore.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.settings = settings
        uiView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var settings: HtmlPreviewWebViewSettings

        init(settings: HtmlPreviewWebViewSettings) {
            self.settings = settings
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if !settings.allowNetwork, let url = navigationAction.request.url, isNetworkURL(url) {
                decisionHandler(.cancel)
                return
            }

            if !settings.allowLinkNavigation, navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
#endif

private func isNetworkURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else { return false }
    return scheme == "http" || scheme == "https"
}
