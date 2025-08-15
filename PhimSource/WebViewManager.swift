import WebKit

// Singleton to manage the WebView instance
class WebViewManager: ObservableObject {
    static let shared = WebViewManager()
    
    @Published var webView: WKWebView?
    
    private init() {}
    
    func setWebView(_ webView: WKWebView) {
        DispatchQueue.main.async {
            self.webView = webView
            debugPrint("WebViewManager: WebView set, is nil: \(webView == nil)", type: .info)
        }
    }
    
    func applyZenMode() {
        guard let webView = webView else {
            debugPrint("WebViewManager: Cannot apply Zen Mode - webView is nil", type: .error)
            return
        }
        
        applyZenModeToWebView(webView)
    }
}