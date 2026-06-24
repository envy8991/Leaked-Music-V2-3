import SwiftUI
import WebKit

@main
struct MovieBoxHostApp: App {
    var body: some Scene {
        WindowGroup {
            MovieBoxBrowserView()
        }
    }
}

struct MovieBoxBrowserView: View {
    @State private var webView = MovieBoxWebView.makeConfiguredWebView()
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var estimatedProgress = 0.0
    @State private var loadError: String?

    var body: some View {
        ZStack(alignment: .top) {
            MovieBoxWebView(
                webView: webView,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                estimatedProgress: $estimatedProgress,
                loadError: $loadError
            )
            .ignoresSafeArea(.container, edges: .bottom)

            if isLoading && estimatedProgress < 1 {
                ProgressView(value: estimatedProgress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .background(Color.black.opacity(0.35))
            }
        }
        .safeAreaInset(edge: .bottom) {
            BrowserToolbar(
                canGoBack: canGoBack,
                canGoForward: canGoForward,
                isLoading: isLoading,
                goBack: { webView.goBack() },
                goForward: { webView.goForward() },
                reload: { webView.reload() },
                stop: { webView.stopLoading() }
            )
        }
        .alert("Unable to Load Page", isPresented: Binding(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("Retry") {
                loadError = nil
                webView.reload()
            }
            Button("Dismiss", role: .cancel) {
                loadError = nil
            }
        } message: {
            Text(loadError ?? "Please check your connection and try again.")
        }
        .preferredColorScheme(.dark)
    }
}

struct BrowserToolbar: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let isLoading: Bool
    let goBack: () -> Void
    let goForward: () -> Void
    let reload: () -> Void
    let stop: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Button(action: goBack) {
                Image(systemName: "chevron.backward")
            }
            .disabled(!canGoBack)

            Button(action: goForward) {
                Image(systemName: "chevron.forward")
            }
            .disabled(!canGoForward)

            Spacer()

            Text("MovieBox Pro")
                .font(.headline)
                .lineLimit(1)

            Spacer()

            Button(action: isLoading ? stop : reload) {
                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
            }
        }
        .font(.title3)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct MovieBoxWebView: UIViewRepresentable {
    private static let movieBoxURL = URL(string: "https://www.movieboxpro.app")!

    let webView: WKWebView
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double
    @Binding var loadError: String?

    static func makeConfiguredWebView() -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1 MovieBoxHost/1.0"
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.decelerationRate = .normal
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.observe(webView)
        if webView.url == nil {
            webView.load(URLRequest(url: Self.movieBoxURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let parent: MovieBoxWebView
        private var observations: [NSKeyValueObservation] = []

        init(_ parent: MovieBoxWebView) {
            self.parent = parent
        }

        func observe(_ webView: WKWebView) {
            observations = [
                webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                    self?.parent.canGoBack = webView.canGoBack
                },
                webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                    self?.parent.canGoForward = webView.canGoForward
                },
                webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                    self?.parent.isLoading = webView.isLoading
                },
                webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                    self?.parent.estimatedProgress = webView.estimatedProgress
                }
            ]
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        private func handle(_ error: Error) {
            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }
            parent.loadError = error.localizedDescription
        }
    }
}
