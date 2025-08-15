import SwiftUI
import WebKit
import UniformTypeIdentifiers

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
                webView = webViewInstance
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
        }
        .frame(width: 1280, height: 832)
        .onAppear {
            currentURL = urlString
            setupKeyboardShortcuts()
            checkClipboardForURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkClipboardForURL()
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
        
        if isValidURL(clipboardString) {
            let url = normalizeURL(clipboardString)
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
    
    private func checkClipboardForURL() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string),
              !clipboardString.isEmpty,
              clipboardString != lastClipboardContent,
              isValidURL(clipboardString) else {
            return
        }
        
        // Update last clipboard content
        lastClipboardContent = clipboardString
        
        // Don't show prompt if we're already loading this URL
        let normalizedURL = normalizeURL(clipboardString)
        if normalizedURL == currentURL {
            return
        }
        
        clipboardURL = normalizedURL
        showClipboardPrompt = true
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