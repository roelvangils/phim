import SwiftUI
import WebKit
import UniformTypeIdentifiers

// Shared function for applying Zen Mode
func applyZenModeToWebView(_ webView: WKWebView?) {
    guard let webView = webView else { 
        debugPrint("Zen Mode: WebView is nil", type: .error)
        return 
    }
    
    debugPrint("Zen Mode: Attempting to apply reader mode", type: .info)
    
    // Create the reader mode JavaScript
    let readerScript = """
    (async () => {
        try {
            console.log('Zen Mode: Starting reader mode script');
            
            // Check if already in reader mode
            if (document.getElementById('reader-view')) {
                console.log('Zen Mode: Already in reader mode, reloading');
                location.reload();
                return;
            }
            
            const loadScript = src => new Promise((res, rej) => {
                console.log('Zen Mode: Loading script', src);
                const s = document.createElement('script');
                s.src = src;
                s.onload = () => {
                    console.log('Zen Mode: Script loaded', src);
                    res();
                };
                s.onerror = (err) => {
                    console.error('Zen Mode: Failed to load script', src, err);
                    rej(err);
                };
                document.head.appendChild(s);
            });

            // Load libraries - using latest version of Readability (0.6.0)
            await loadScript('https://cdn.jsdelivr.net/npm/@mozilla/readability@0.6.0/Readability.js');
            await loadScript('https://cdn.jsdelivr.net/npm/dompurify@3.1.6/dist/purify.min.js');

            // Clone doc so original isn't altered by Readability
            console.log('Zen Mode: Cloning document and parsing with Readability');
            const docClone = document.cloneNode(true);
            
            // Pre-process: Remove common unwanted elements before Readability parsing
            const selectorsToRemove = [
                'nav', 'header', 'footer', '.navigation', '.nav', '.menu',
                '.sidebar', '.advertisement', '.ads', '.social-share', '.social',
                '.comments', '#comments', '.related', '.related-posts',
                '.newsletter', '.subscribe', '.popup', '.modal',
                '.cookie', '.banner', '.alert', '.notice',
                '[role="navigation"]', '[role="banner"]', '[role="complementary"]',
                '.share', '.sharing', '.tags', '.post-tags', '.meta',
                '.breadcrumb', '.pagination', '.author-bio', '.bio',
                '.widget', '.widgets', '[class*="promo"]', '[class*="newsletter"]',
                '[id*="newsletter"]', '[class*="subscribe"]', '[id*="subscribe"]',
                '.recommended', '.suggestions', '.more-like-this'
            ];
            
            selectorsToRemove.forEach(selector => {
                docClone.querySelectorAll(selector).forEach(el => el.remove());
            });
            
            // Configure Readability with stricter options
            const reader = new Readability(docClone, {
                charThreshold: 100,
                classesToPreserve: [],
                keepClasses: false
            });
            const article = reader.parse();
            
            if (!article) {
                console.error('Zen Mode: Unable to extract article content from this page');
                alert('Unable to extract article content from this page');
                return;
            }
            console.log('Zen Mode: Article parsed successfully', article.title);
            console.log('Zen Mode: Article object keys:', Object.keys(article));
            console.log('Zen Mode: Full article object:', article);

            // Build reader content
            const main = document.createElement('main');
            main.id = 'reader-view';
            main.setAttribute('role', 'main');

            // Create a temporary container to clean the article content
            const tempDiv = document.createElement('div');
            
            // Debug what we're getting from Readability
            console.log('Zen Mode: typeof article.content:', typeof article.content);
            
            // The Readability library should return HTML string in the content property
            // If we're getting [object HTMLDivElement], something is wrong
            let contentHTML = '';
            if (typeof article.content === 'string') {
                // Check if it's the error string
                if (article.content === '[object HTMLDivElement]') {
                    console.error('Zen Mode: Got [object HTMLDivElement] string, parsing failed');
                    // Try to get content directly from the page
                    const articleEl = document.querySelector('article') || document.querySelector('main') || document.body;
                    contentHTML = articleEl ? articleEl.innerHTML : '';
                } else {
                    contentHTML = article.content;
                }
            } else if (article.content && typeof article.content === 'object') {
                // If it's an object, try to get innerHTML
                contentHTML = article.content.innerHTML || article.content.outerHTML || '';
            }
            
            tempDiv.innerHTML = contentHTML;
            
            // Post-process: Clean up the article content even more
            const elementsToRemove = [
                'button', 'form', 'input', 'select', 'textarea',
                'script', 'style', 'noscript', 'iframe',
                '[class*="share"]', '[class*="social"]', '[class*="comment"]',
                '[class*="related"]', '[class*="newsletter"]', '[class*="subscribe"]',
                '[class*="follow"]', '[class*="promo"]', '[class*="widget"]',
                '[class*="banner"]', '[class*="popup"]', '[class*="modal"]',
                '[id*="share"]', '[id*="social"]', '[id*="comment"]'
            ];
            
            elementsToRemove.forEach(selector => {
                try {
                    tempDiv.querySelectorAll(selector).forEach(el => el.remove());
                } catch (e) {
                    console.log('Zen Mode: Error removing selector', selector, e);
                }
            });
            
            // Remove empty paragraphs and clean up whitespace
            tempDiv.querySelectorAll('p').forEach(p => {
                if (!p.textContent.trim()) p.remove();
            });
            
            // Remove any remaining navigation-like lists at the beginning or end
            const firstChild = tempDiv.firstElementChild;
            const lastChild = tempDiv.lastElementChild;
            if (firstChild && firstChild.tagName === 'UL' && firstChild.textContent.length < 100) {
                firstChild.remove();
            }
            if (lastChild && lastChild.tagName === 'UL' && lastChild.textContent.length < 100) {
                lastChild.remove();
            }

            // Build the final HTML - super clean, just title and content
            console.log('Zen Mode: tempDiv type:', typeof tempDiv);
            console.log('Zen Mode: tempDiv:', tempDiv);
            console.log('Zen Mode: tempDiv.innerHTML type:', typeof tempDiv.innerHTML);
            console.log('Zen Mode: tempDiv.innerHTML:', tempDiv.innerHTML);
            
            // Get the cleaned content as a string
            let cleanedContent = '';
            if (tempDiv && tempDiv.innerHTML) {
                cleanedContent = tempDiv.innerHTML.toString();
            }
            
            console.log('Zen Mode: cleanedContent type:', typeof cleanedContent);
            console.log('Zen Mode: cleanedContent length:', cleanedContent.length);
            console.log('Zen Mode: cleanedContent first 200:', cleanedContent.substring(0, 200));
            
            const titleText = (article.title || document.title || 'Untitled').toString();
            
            // Build HTML without template literals or concatenation issues
            const html = ['<article><h1>', titleText, '</h1>', cleanedContent, '</article>'].join('');
            
            // Sanitize and set the content
            main.innerHTML = DOMPurify.sanitize(html, { 
                USE_PROFILES: { html: true },
                FORBID_TAGS: ['button', 'form', 'input'],
                FORBID_ATTR: ['onclick', 'onmouseover', 'onerror']
            });
            
            // Optionally add byline if it exists and looks legitimate
            if (article.byline && article.byline.length < 100 && !article.byline.includes('Share')) {
                const bylineEl = document.createElement('p');
                bylineEl.className = 'byline';
                bylineEl.style.opacity = '0.7';
                bylineEl.style.fontSize = '0.9em';
                bylineEl.style.marginTop = '-0.5em';
                bylineEl.style.marginBottom = '2em';
                bylineEl.textContent = article.byline;
                const h1 = main.querySelector('h1');
                if (h1 && h1.nextSibling) {
                    h1.parentNode.insertBefore(bylineEl, h1.nextSibling);
                }
            }

            // Zen mode styles optimized for Phim - ultra clean
            const style = document.createElement('style');
            style.textContent = `
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body { 
                    margin: 0; 
                    padding: 0; 
                    background: transparent;
                    color: #1d1d1f;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    -webkit-font-smoothing: antialiased;
                    -moz-osx-font-smoothing: grayscale;
                }
                
                #reader-view { 
                    max-width: 45ch; 
                    margin: 4rem auto; 
                    padding: 2rem; 
                    line-height: 1.6; 
                    font-size: 36pt;
                    font-weight: 400;
                    letter-spacing: -0.02em;
                }
                
                article {
                    width: 100%;
                }
                
                h1 { 
                    margin-bottom: 3rem; 
                    font-size: 52pt;
                    font-weight: 800;
                    line-height: 1.1;
                    letter-spacing: -0.03em;
                    color: #000;
                }
                
                .byline {
                    color: #6e6e73;
                    margin-bottom: 3rem !important;
                    font-size: 24pt;
                }
                
                h2 { 
                    margin-top: 3rem;
                    margin-bottom: 1.5rem;
                    font-size: 42pt;
                    font-weight: 700;
                    letter-spacing: -0.02em;
                    color: #000;
                }
                
                h3 { 
                    margin-top: 2.5rem;
                    margin-bottom: 1rem;
                    font-size: 32pt;
                    font-weight: 600;
                    color: #000;
                }
                
                p {
                    margin-bottom: 1.5rem;
                    color: #1d1d1f;
                }
                
                img, video { 
                    display: block;
                    max-width: 100%; 
                    height: auto;
                    margin: 2rem auto;
                    border-radius: 12px;
                }
                
                figure {
                    margin: 2rem 0;
                }
                
                figcaption {
                    text-align: center;
                    font-size: 0.875rem;
                    color: #6e6e73;
                    margin-top: 0.75rem;
                }
                
                a { 
                    color: #06c;
                    text-decoration: none;
                    border-bottom: 1px solid transparent;
                    transition: border-color 0.2s;
                }
                
                a:hover {
                    border-bottom-color: #06c;
                }
                
                blockquote {
                    border-left: 3px solid #d2d2d7;
                    padding-left: 1.5rem;
                    margin: 2rem 0;
                    color: #6e6e73;
                    font-style: italic;
                }
                
                pre {
                    background: #f5f5f7;
                    padding: 1.25rem;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 2rem 0;
                    font-size: 0.875rem;
                    line-height: 1.5;
                }
                
                code {
                    background: #f5f5f7;
                    padding: 0.125em 0.375em;
                    border-radius: 4px;
                    font-size: 0.875em;
                    font-family: "SF Mono", Monaco, "Courier New", monospace;
                }
                
                pre code {
                    background: none;
                    padding: 0;
                }
                
                ul, ol {
                    margin-bottom: 1.5rem;
                    padding-left: 2rem;
                }
                
                li {
                    margin-bottom: 0.5rem;
                }
                
                hr {
                    border: none;
                    border-top: 1px solid #d2d2d7;
                    margin: 3rem 0;
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 2rem 0;
                }
                
                th, td {
                    padding: 0.75rem;
                    text-align: left;
                    border-bottom: 1px solid #d2d2d7;
                }
                
                th {
                    font-weight: 600;
                    background: #f5f5f7;
                }
                @media (prefers-color-scheme: dark) {
                    body { 
                        color: #f5f5f7;
                    }
                    
                    h1, h2, h3 {
                        color: #fff;
                    }
                    
                    p {
                        color: #f5f5f7;
                    }
                    
                    .byline {
                        color: #86868b;
                    }
                    
                    a { 
                        color: #2997ff;
                    }
                    
                    a:hover {
                        border-bottom-color: #2997ff;
                    }
                    
                    blockquote {
                        border-left-color: #48484a;
                        color: #86868b;
                    }
                    
                    pre {
                        background: #1c1c1e;
                        color: #f5f5f7;
                    }
                    
                    code {
                        background: #1c1c1e;
                        color: #f5f5f7;
                    }
                    
                    hr {
                        border-top-color: #48484a;
                    }
                    
                    th, td {
                        border-bottom-color: #48484a;
                    }
                    
                    th {
                        background: #1c1c1e;
                    }
                }
        `;

            // Clear page and apply reader view
            console.log('Zen Mode: Applying reader view');
            document.head.appendChild(style);
            document.body.innerHTML = '';
            document.body.appendChild(main);
            
            // Scroll to top
            window.scrollTo(0, 0);
            console.log('Zen Mode: Reader view applied successfully');
        } catch (error) {
            console.error('Zen Mode: Error occurred', error);
            alert('Error applying Zen Mode: ' + error.message);
        }
    })();
    """
    
    webView.evaluateJavaScript(readerScript) { (result, error) in
        if let error = error {
            debugPrint("Zen Mode Error: \(error.localizedDescription)", type: .error)
            debugPrint("Full error: \(error)", type: .error)
        } else {
            debugPrint("Zen Mode: JavaScript executed successfully", type: .info)
        }
    }
}

struct ContentView: View {
    let urlString: String
    let vibrancyEnabled: Bool
    let fancyLoadingEnabled: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var currentURL: String = ""
    @State private var isInitialLoading: Bool = true
    @State private var hasCompletedInitialLoad: Bool = false
    @State private var webView: WKWebView?
    @State private var showClipboardPrompt: Bool = false
    @State private var clipboardURL: String = ""
    @State private var lastClipboardContent: String = ""
    @State private var showBrowserPrompt: Bool = false
    @State private var browserTab: BrowserDetector.BrowserTab?
    
    var body: some View {
        ZStack {
            // Vibrancy background that adapts to system appearance
            if vibrancyEnabled {
                VibrancyView()
                    .ignoresSafeArea()
                    .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            
            // WebView with blur effect during initial loading only
            WebView(urlString: urlString, vibrancyEnabled: vibrancyEnabled, fancyLoadingEnabled: fancyLoadingEnabled) { url in
                currentURL = url
            } onLoadingChange: { loading in
                if fancyLoadingEnabled && !hasCompletedInitialLoad {
                    isInitialLoading = loading
                    if !loading {
                        // Mark initial load as complete once the first page finishes loading
                        hasCompletedInitialLoad = true
                    }
                }
            } webViewProvider: { webViewInstance in
                debugPrint("ContentView: WebView instance provided, is nil: \(webViewInstance == nil)", type: .info)
                DispatchQueue.main.async {
                    webView = webViewInstance
                    debugPrint("ContentView: WebView stored in state, is nil: \(webView == nil)", type: .info)
                }
            }
            .frame(width: 1280, height: 832)
            .ignoresSafeArea()
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .blur(radius: fancyLoadingEnabled && isInitialLoading && !hasCompletedInitialLoad ? 20 : 0)
            .animation(.easeInOut(duration: 0.25), value: isInitialLoading)
            
            // Invisible drag strip at the top
            VStack {
                DragStripView()
                    .frame(height: 40)
                Spacer()
            }
            
            // Floating toolbar at bottom
            VStack {
                Spacer()
                FloatingToolbar(
                    currentURL: currentURL.isEmpty ? urlString : currentURL,
                    webView: webView
                )
                .padding(.bottom, 20)
            }
            
            // Clipboard URL prompt overlay
            if showClipboardPrompt {
                ClipboardPromptView(
                    url: clipboardURL,
                    onLoad: {
                        loadURLFromClipboard(clipboardURL)
                        showClipboardPrompt = false
                    },
                    onCancel: {
                        showClipboardPrompt = false
                    }
                )
            }
            
            // Browser URL prompt overlay
            if showBrowserPrompt, let tab = browserTab {
                BrowserPromptView(
                    tab: tab,
                    onLoad: {
                        loadURLFromClipboard(tab.url)
                        showBrowserPrompt = false
                    },
                    onCancel: {
                        showBrowserPrompt = false
                    }
                )
            }
        }
        .frame(width: 1280, height: 832)
        .onAppear {
            currentURL = urlString
            setupKeyboardShortcuts()
            checkForBrowserURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkForBrowserURL()
        }
        .onDrop(of: [.url, .plainText], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Check for Command+V
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
                handleCommandV()
                return nil // Consume the event
            }
            
            // Check for Enter/Escape when prompt is showing
            if showClipboardPrompt {
                if event.keyCode == 36 { // Enter key
                    loadURLFromClipboard(clipboardURL)
                    showClipboardPrompt = false
                    return nil
                } else if event.keyCode == 53 { // Escape key
                    showClipboardPrompt = false
                    return nil
                }
            }
            
            // Check if no modifiers are pressed (for single-key shortcuts)
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [] {
                switch event.charactersIgnoringModifiers {
                case "o", "O":
                    // Hide Phim window and open in browser
                    if let url = URL(string: currentURL.isEmpty ? urlString : currentURL) {
                        // Hide the window first
                        if let window = NSApplication.shared.windows.first {
                            window.orderOut(nil)
                        }
                        // Then open in default browser
                        NSWorkspace.shared.open(url)
                    }
                    return nil // Consume the event
                case "r", "R":
                    // Reload page
                    webView?.reload()
                    return nil // Consume the event
                case "c", "C":
                    // Copy current URL to clipboard
                    let url = currentURL.isEmpty ? urlString : currentURL
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                    return nil // Consume the event
                case "x", "X":
                    // Close Phim
                    NSApplication.shared.terminate(nil)
                    return nil // Consume the event
                case "z", "Z":
                    // Toggle Zen Mode
                    debugPrint("Keyboard shortcut Z pressed", type: .info)
                    WebViewManager.shared.applyZenMode()
                    return nil // Consume the event
                case "d", "D":
                    // Toggle Debug Console
                    DebugConsoleManager.shared.toggleConsole()
                    return nil // Consume the event
                default:
                    break
                }
            }
            return event // Let the event pass through
        }
    }
    
    private func handleCommandV() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string),
              !clipboardString.isEmpty else {
            return
        }
        
        if let extractedURL = extractURLFromText(clipboardString) {
            let url = normalizeURL(extractedURL)
            loadURLFromClipboard(url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            // Try to load as URL first
            if provider.hasItemConformingToTypeIdentifier("public.url") {
                provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, error in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self.loadURLFromClipboard(url.absoluteString)
                        }
                    }
                }
            }
            // Try to load as text that might be a URL
            else if provider.hasItemConformingToTypeIdentifier("public.text") {
                provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
                    if let text = item as? String, self.isValidURL(text) {
                        DispatchQueue.main.async {
                            let url = self.normalizeURL(text)
                            self.loadURLFromClipboard(url)
                        }
                    }
                }
            }
        }
    }
    
    private func checkForBrowserURL() {
        // First check for browser URL
        if let tab = BrowserDetector.shared.getCurrentBrowserTab() {
            // Don't show prompt if we're already loading this URL
            if tab.url != currentURL && isValidURL(tab.url) {
                browserTab = tab
                showBrowserPrompt = true
                return // Don't check clipboard if we found a browser URL
            }
        }
        
        // Fall back to clipboard check if no browser URL found
        checkClipboardForURL()
    }
    
    private func checkClipboardForURL() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string),
              !clipboardString.isEmpty,
              clipboardString != lastClipboardContent else {
            return
        }
        
        // Try to extract URL from clipboard content
        if let extractedURL = extractURLFromText(clipboardString) {
            // Update last clipboard content
            lastClipboardContent = clipboardString
            
            // Don't show prompt if we're already loading this URL
            let normalizedURL = normalizeURL(extractedURL)
            if normalizedURL == currentURL {
                return
            }
            
            clipboardURL = normalizedURL
            showClipboardPrompt = true
        }
    }
    
    private func extractURLFromText(_ text: String) -> String? {
        // First try to detect URLs with common patterns
        let patterns = [
            // Standard URLs with protocols
            #"https?://[^\s<>\[\]{}()|\\^`"']+"#,
            #"file://[^\s<>\[\]{}()|\\^`"']+"#,
            // Markdown-style links [text](url)
            #"\[([^\]]+)\]\(([^)]+)\)"#,
            // HTML anchor tags
            #"<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>"#,
            // Plain domains that look like URLs
            #"(?:^|\s)((?:www\.)?[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+)(?:/[^\s]*)?"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    // For markdown links, extract the URL part (second capture group)
                    if pattern.contains("\\]\\(") && match.numberOfRanges > 2 {
                        if let urlRange = Range(match.range(at: 2), in: text) {
                            return String(text[urlRange])
                        }
                    }
                    // For HTML links, extract the href value
                    else if pattern.contains("href=") && match.numberOfRanges > 1 {
                        if let urlRange = Range(match.range(at: 1), in: text) {
                            return String(text[urlRange])
                        }
                    }
                    // For domain patterns without protocol
                    else if pattern.contains("www\\.") && match.numberOfRanges > 1 {
                        if let urlRange = Range(match.range(at: 1), in: text) {
                            let domain = String(text[urlRange])
                            // Add https:// if it's just a domain
                            if !domain.hasPrefix("http") {
                                return domain
                            }
                            return domain
                        }
                    }
                    // For standard URLs, extract the whole match
                    else {
                        if let urlRange = Range(match.range, in: text) {
                            return String(text[urlRange])
                        }
                    }
                }
            }
        }
        
        // If no URL pattern found, check if the entire text is a valid URL
        if isValidURL(text) {
            return text
        }
        
        return nil
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // Check for URL patterns
        if string.hasPrefix("http://") || string.hasPrefix("https://") || string.hasPrefix("file://") {
            return true
        }
        
        // Check if it might be a domain
        if string.contains(".") && !string.contains(" ") && !string.hasPrefix("/") {
            return true
        }
        
        // Check if it's a file path
        if FileManager.default.fileExists(atPath: string) {
            return true
        }
        
        return false
    }
    
    private func normalizeURL(_ string: String) -> String {
        // Already a full URL
        if string.hasPrefix("http://") || string.hasPrefix("https://") || string.hasPrefix("file://") {
            return string
        }
        
        // File path
        if FileManager.default.fileExists(atPath: string) {
            return URL(fileURLWithPath: string).absoluteString
        }
        
        // Assume it's a domain
        return "https://\(string)"
    }
    
    private func loadURLFromClipboard(_ url: String) {
        // Update the current URL state first
        currentURL = url
        
        // Load the URL in the webview
        if let webView = webView, let nsURL = URL(string: url) {
            DispatchQueue.main.async {
                webView.load(URLRequest(url: nsURL))
            }
        } else {
            // If webView is not ready, we need to reload the entire view with the new URL
            if let window = NSApplication.shared.windows.first {
                window.contentView = NSHostingView(
                    rootView: ContentView(
                        urlString: url,
                        vibrancyEnabled: self.vibrancyEnabled,
                        fancyLoadingEnabled: self.fancyLoadingEnabled
                    )
                )
            }
        }
    }
}

struct FloatingToolbar: View {
    let currentURL: String
    let webView: WKWebView?
    @Environment(\.colorScheme) var colorScheme
    @State private var browserName: String = "Browser"
    
    var body: some View {
        HStack(spacing: 8) {
            // Open in browser
            ToolbarButton(
                shortcut: "O",
                label: "Open in \(browserName)",
                action: openInBrowser
            )
            
            Divider()
                .frame(height: 18)
                .opacity(0.2)
            
            // Reload page
            ToolbarButton(
                shortcut: "R",
                label: "Reload",
                action: reloadPage
            )
            
            Divider()
                .frame(height: 18)
                .opacity(0.2)
            
            // Copy address
            ToolbarButton(
                shortcut: "C",
                label: "Copy Address",
                action: copyAddress
            )
            
            Divider()
                .frame(height: 18)
                .opacity(0.2)
            
            // Zen Mode
            ToolbarButton(
                shortcut: "Z",
                label: "Zen Mode",
                action: toggleZenMode
            )
            
            Divider()
                .frame(height: 18)
                .opacity(0.2)
            
            // Close Phim
            ToolbarButton(
                shortcut: "X",
                label: "Close Phim",
                action: closePhim
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onAppear {
            loadBrowserName()
        }
        .background(
            ZStack {
                // Vibrancy background for toolbar with pill shape
                ToolbarVibrancyView()
                    .clipShape(Capsule())
                
                // Subtle border
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    private func openInBrowser() {
        if let url = URL(string: currentURL) {
            // Hide the window first
            if let window = NSApplication.shared.windows.first {
                window.orderOut(nil)
            }
            // Then open in default browser
            NSWorkspace.shared.open(url)
        }
    }
    
    private func reloadPage() {
        webView?.reload()
    }
    
    private func copyAddress() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentURL, forType: .string)
    }
    
    private func toggleZenMode() {
        debugPrint("FloatingToolbar: toggleZenMode called", type: .info)
        WebViewManager.shared.applyZenMode()
    }
    
    private func closePhim() {
        NSApplication.shared.terminate(nil)
    }
    
    private func loadBrowserName() {
        // Get the default browser bundle identifier for HTTP URLs
        if let browserURL = LSCopyDefaultApplicationURLForURL(
            URL(string: "https://")! as CFURL,
            .viewer,
            nil
        )?.takeRetainedValue() as URL? {
            
            // Get browser name from the bundle
            if let bundle = Bundle(url: browserURL),
               let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                browserName = appName
            } else {
                // Fallback to extracting name from path
                browserName = browserURL.deletingPathExtension().lastPathComponent
            }
        }
    }
}

struct ToolbarButton: View {
    let shortcut: String
    let label: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Keyboard shortcut in circle
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(isHovered ? 0.9 : 0.5))
                        .frame(width: 18, height: 18)
                    Text(shortcut)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(NSColor.windowBackgroundColor))
                }
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ToolbarVibrancyView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let vibrancyView = NSVisualEffectView()
        vibrancyView.blendingMode = .withinWindow
        vibrancyView.state = .active
        vibrancyView.material = .hudWindow
        return vibrancyView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Material automatically adapts to system appearance
    }
}

// NSViewRepresentable for the vibrancy effect with semi-transparent overlay
struct VibrancyView: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSView {
        // Create a container view
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // Create the vibrancy effect view
        let vibrancyView = NSVisualEffectView()
        vibrancyView.blendingMode = .behindWindow
        vibrancyView.state = .active
        vibrancyView.material = .underWindowBackground
        vibrancyView.autoresizingMask = [.width, .height]
        vibrancyView.frame = containerView.bounds
        
        // Add vibrancy view to container
        containerView.addSubview(vibrancyView)
        
        // Create overlay view with 33% opaque white/black background based on appearance
        let overlayView = NSView()
        overlayView.wantsLayer = true
        let overlayColor = colorScheme == .dark 
            ? NSColor.black.withAlphaComponent(0.33)
            : NSColor.white.withAlphaComponent(0.33)
        overlayView.layer?.backgroundColor = overlayColor.cgColor
        overlayView.autoresizingMask = [.width, .height]
        overlayView.frame = containerView.bounds
        
        // Add overlay on top of vibrancy
        containerView.addSubview(overlayView)
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update vibrancy material when needed
        if let vibrancyView = nsView.subviews.first as? NSVisualEffectView {
            vibrancyView.material = .underWindowBackground
        }
        
        // Update overlay color based on current appearance
        if nsView.subviews.count > 1 {
            let overlayColor = colorScheme == .dark 
                ? NSColor.black.withAlphaComponent(0.33)
                : NSColor.white.withAlphaComponent(0.33)
            nsView.subviews[1].layer?.backgroundColor = overlayColor.cgColor
        }
    }
}

// Invisible drag strip for window dragging
struct DragStripView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DragView()
        view.wantsLayer = true
        
        // Make it invisible but still interactive
        view.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Uncomment the next line to see the drag area during testing
        // view.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.1).cgColor
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            self.window?.performDrag(with: event)
        }
        
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
        }
    }
}

// Clipboard prompt overlay view
struct ClipboardPromptView: View {
    let url: String
    let onLoad: () -> Void
    let onCancel: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Prompt card
            VStack(spacing: 20) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("URL detected in clipboard")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(url)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button(action: onLoad) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Load URL")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.return, modifiers: [])
                }
                
                Text("Press Enter to load • Escape to cancel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(radius: 20)
            )
            .frame(maxWidth: 500)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
}

// Browser URL prompt overlay view
struct BrowserPromptView: View {
    let tab: BrowserDetector.BrowserTab
    let onLoad: () -> Void
    let onCancel: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Prompt card
            VStack(spacing: 20) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Browser tab detected")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(tab.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.horizontal)
                
                Text(tab.url)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.horizontal)
                
                Text("From \(tab.browserName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button(action: onLoad) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Load Tab")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.return, modifiers: [])
                }
                
                Text("Press Enter to load • Escape to cancel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(radius: 20)
            )
            .frame(maxWidth: 500)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
}
