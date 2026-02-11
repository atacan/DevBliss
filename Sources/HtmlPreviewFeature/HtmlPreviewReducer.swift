import BlissTheme
import ComposableArchitecture
import HtmlPreviewClient
import InputOutput
import SharedModels
import SplitView
import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

@Reducer
public struct HtmlPreviewReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("htmlPreview")) public var inputText = ""
        @Shared(.toolOutput("htmlPreview")) public var outputText = ""
        var input: InputEditorReducer.State
        var enableJavaScript: Bool = true
        var allowLinkNavigation: Bool = true
        var allowNetwork: Bool = false

        public init() {
            let inputText = Shared(wrappedValue: "", .toolInput("htmlPreview"))
            self._inputText = inputText
            self.input = InputEditorReducer.State(text: inputText.projectedValue)
        }

        public init(inputText: String) {
            let input = Shared(wrappedValue: inputText, .toolInput("htmlPreview"))
            self._inputText = input
            self.input = InputEditorReducer.State(text: input.projectedValue)
        }

        public var normalizedHTML: String {
            inputText
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
    }

    @Dependency(\.htmlPreview) var htmlPreview

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .input:
                let normalized = htmlPreview.normalize(state.input.text)
                state.input.$text.withLock { $0 = normalized }
                state.$inputText.withLock { $0 = normalized }
                return .none
            }
        }

        Scope(state: \.input, action: \.input) {
            InputEditorReducer()
        }
    }
}

public struct HtmlPreviewView: View {
    @Bindable var store: StoreOf<HtmlPreviewReducer>
    @StateObject private var webViewStore = HtmlPreviewWebViewStore()

    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.HtmlPreview.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.HtmlPreview.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(store: StoreOf<HtmlPreviewReducer>) {
        self.store = store
    }

    // MARK: - Reusable Controls

    private var enableJavaScriptToggle: some View {
        Toggle("Enable JavaScript", isOn: $store.enableJavaScript)
    }

    private var allowLinkNavigationToggle: some View {
        Toggle("Allow link navigation", isOn: $store.allowLinkNavigation)
    }

    private var allowNetworkToggle: some View {
        Toggle("Allow network", isOn: $store.allowNetwork)
    }

    private var openInBrowserButton: some View {
        LoadingButton("Open in Browser", isLoading: false) {
            openInBrowser(store.input.text)
        }
        .buttonStyle(.bordered)
    }

    private var reloadButton: some View {
        LoadingButton("Reload", isLoading: false) {
            webViewStore.reload(html: store.input.text)
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
        InputEditorView(store: store.scope(state: \.input, action: \.input), title: "HTML")
    }

    private var previewPane: some View {
        let settings = HtmlPreviewWebViewSettings(
            javaScriptEnabled: store.enableJavaScript,
            allowLinkNavigation: store.allowLinkNavigation,
            allowNetwork: store.allowNetwork
        )

        return HtmlPreviewWebView(
            html: store.input.text,
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

struct HtmlPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        HtmlPreviewView(store: .init(initialState: .init()) { HtmlPreviewReducer() })
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
