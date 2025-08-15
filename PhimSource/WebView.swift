import SwiftUI
import WebKit



struct WebView: NSViewRepresentable {
    let urlString: String
    var vibrancyEnabled: Bool = true
    var fancyLoadingEnabled: Bool = true
    var onURLChange: ((String) -> Void)?
    var onLoadingChange: ((Bool) -> Void)?
    var webViewProvider: ((WKWebView) -> Void)?
    
    init(urlString: String, vibrancyEnabled: Bool = true, fancyLoadingEnabled: Bool = true, onURLChange: ((String) -> Void)? = nil, onLoadingChange: ((Bool) -> Void)? = nil, webViewProvider: ((WKWebView) -> Void)? = nil) {
        self.urlString = urlString
        self.vibrancyEnabled = vibrancyEnabled
        self.fancyLoadingEnabled = fancyLoadingEnabled
        self.onURLChange = onURLChange
        self.onLoadingChange = onLoadingChange
        self.webViewProvider = webViewProvider
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true
        
        // Use non-persistent data store (like private/incognito mode)
        configuration.websiteDataStore = .nonPersistent()
        
        // Disable caching
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.suppressesIncrementalRendering = true
        
        // Additional privacy settings
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Only inject vibrancy scripts if enabled
        if vibrancyEnabled {
            let vibrancyScript = """
        (function() {
            // CSS for common white background patterns
            const css = `
                html, body, main, #main {
                    background-color: transparent !important;
                }
                
                /* Common white background patterns */
                [style*="background-color: white"],
                [style*="background-color:#fff"],
                [style*="background-color: #fff"],
                [style*="background-color: rgb(255"],
                [style*="background-color: rgba(255"],
                [style*="background: white"],
                [style*="background:#fff"],
                [style*="background: #fff"],
                .bg-white, .white-bg, .light-bg,
                .container, .content, .wrapper, .page,
                .card, .panel, .modal-backdrop {
                    background-color: transparent !important;
                }
            `;
            
            // Inject CSS
            const style = document.createElement('style');
            style.setAttribute('data-peep-vibrancy', 'true');
            style.textContent = css;
            document.head.appendChild(style);
            
            // Function to check if color is light
            function isLightColor(color) {
                if (!color || color === 'transparent' || color === 'initial' || color === 'inherit') {
                    return false;
                }
                
                // Parse rgb/rgba values
                const match = color.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
                if (match) {
                    const r = parseInt(match[1]);
                    const g = parseInt(match[2]);
                    const b = parseInt(match[3]);
                    // Calculate brightness (HSP Color Model)
                    const brightness = Math.sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
                    return brightness > 230; // Threshold for "light" colors
                }
                return false;
            }
            
            // Function to process elements
            function processElements(elements) {
                const containers = ['div', 'section', 'article', 'main', 'aside', 'header', 'footer', 'nav'];
                elements.forEach(el => {
                    // Only process container elements
                    if (!containers.includes(el.tagName.toLowerCase())) return;
                    
                    const computed = window.getComputedStyle(el);
                    if (isLightColor(computed.backgroundColor)) {
                        el.style.setProperty('background-color', 'transparent', 'important');
                    }
                });
            }
            
            // Initial scan after page loads
            function initialScan() {
                const elements = document.querySelectorAll('div, section, article, main, aside, header, footer, nav');
                processElements(elements);
            }
            
            // Run initial scan
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', initialScan);
            } else {
                setTimeout(initialScan, 100);
            }
            
            // Debounce function
            function debounce(func, wait) {
                let timeout;
                return function executedFunction(...args) {
                    const later = () => {
                        clearTimeout(timeout);
                        func(...args);
                    };
                    clearTimeout(timeout);
                    timeout = setTimeout(later, wait);
                };
            }
            
            // MutationObserver for dynamic content (limited to main content areas)
            const observer = new MutationObserver(debounce((mutations) => {
                const newElements = new Set();
                mutations.forEach(mutation => {
                    mutation.addedNodes.forEach(node => {
                        if (node.nodeType === 1) { // Element node
                            newElements.add(node);
                            // Also check children
                            const children = node.querySelectorAll?.('div, section, article, main, aside, header, footer, nav');
                            if (children) {
                                children.forEach(child => newElements.add(child));
                            }
                        }
                    });
                });
                if (newElements.size > 0) {
                    processElements(Array.from(newElements));
                }
            }, 200));
            
            // Start observing (only body and main content areas)
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
            
            // Store observer for potential cleanup
            window.peepVibrancyObserver = observer;
        })();
        """
            let userScript = WKUserScript(source: vibrancyScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            configuration.userContentController.addUserScript(userScript)
        }
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        webView.navigationDelegate = context.coordinator
        
        // Make the WebView background transparent
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = NSColor.clear
        }
        
        // Provide the webView instance to the parent
        webViewProvider?(webView)
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Handle vibrancy toggle
        if vibrancyEnabled {
            context.coordinator.enableVibrancy(in: webView)
        } else {
            context.coordinator.disableVibrancy(in: webView)
        }
        
        // Load content if needed
        if webView.url == nil {
            loadContent(in: webView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Report URL change
            if let url = webView.url?.absoluteString {
                parent.onURLChange?(url)
            }
            
            // Toggle vibrancy based on current state
            if parent.vibrancyEnabled {
                enableVibrancy(in: webView)
            } else {
                disableVibrancy(in: webView)
            }
            
            // Notify loading complete after a small delay to ensure CSS injection is done
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.parent.onLoadingChange?(false)
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Report URL change when navigation starts
            if let url = webView.url?.absoluteString {
                parent.onURLChange?(url)
            }
            // Notify loading started
            parent.onLoadingChange?(true)
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            // Page has started rendering
            parent.onLoadingChange?(true)
        }
        
        func enableVibrancy(in webView: WKWebView) {
            let script = """
            (function() {
                // Remove any existing disable styles
                const disableStyle = document.querySelector('style[data-peep-vibrancy-disabled]');
                if (disableStyle) disableStyle.remove();
                
                // Re-apply vibrancy if not already present
                if (!document.querySelector('style[data-peep-vibrancy="true"]')) {
                    const css = `
                        html, body, main, #main {
                            background-color: transparent !important;
                        }
                        [style*="background-color: white"],
                        [style*="background-color:#fff"],
                        [style*="background-color: #fff"],
                        [style*="background-color: rgb(255"],
                        [style*="background-color: rgba(255"],
                        [style*="background: white"],
                        [style*="background:#fff"],
                        [style*="background: #fff"],
                        .bg-white, .white-bg, .light-bg,
                        .container, .content, .wrapper, .page,
                        .card, .panel, .modal-backdrop {
                            background-color: transparent !important;
                        }
                    `;
                    const style = document.createElement('style');
                    style.setAttribute('data-peep-vibrancy', 'true');
                    style.textContent = css;
                    document.head.appendChild(style);
                    
                    // Re-scan for light backgrounds
                    const elements = document.querySelectorAll('div, section, article, main, aside, header, footer, nav');
                    elements.forEach(el => {
                        const computed = window.getComputedStyle(el);
                        const color = computed.backgroundColor;
                        if (color && color !== 'transparent') {
                            const match = color.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
                            if (match) {
                                const r = parseInt(match[1]);
                                const g = parseInt(match[2]);
                                const b = parseInt(match[3]);
                                const brightness = Math.sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
                                if (brightness > 230) {
                                    el.style.setProperty('background-color', 'transparent', 'important');
                                }
                            }
                        }
                    });
                }
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        func disableVibrancy(in webView: WKWebView) {
            let script = """
            (function() {
                // Remove vibrancy styles
                const vibrancyStyle = document.querySelector('style[data-peep-vibrancy="true"]');
                if (vibrancyStyle) vibrancyStyle.remove();
                
                // Stop observer if exists
                if (window.peepVibrancyObserver) {
                    window.peepVibrancyObserver.disconnect();
                    window.peepVibrancyObserver = null;
                }
                
                // Add style to reset backgrounds
                const style = document.createElement('style');
                style.setAttribute('data-peep-vibrancy-disabled', 'true');
                style.textContent = `
                    html, body, main, #main {
                        background-color: initial !important;
                    }
                `;
                document.head.appendChild(style);
                
                // Remove inline transparent styles we added
                document.querySelectorAll('[style*="background-color: transparent"]').forEach(el => {
                    el.style.removeProperty('background-color');
                });
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    private func loadContent(in webView: WKWebView) {
        guard !urlString.isEmpty else { return }
        
        // Check if it's a local file path
        if urlString.hasPrefix("/") || urlString.hasPrefix("file://") {
            let path = urlString.replacingOccurrences(of: "file://", with: "")
            let fileURL = URL(fileURLWithPath: path)
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        } else if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        } else if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            // Try adding https:// prefix
            if let url = URL(string: "https://\(urlString)") {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
}