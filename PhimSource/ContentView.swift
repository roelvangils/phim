import SwiftUI
import WebKit

struct ContentView: View {
    let urlString: String
    let vibrancyEnabled: Bool
    let fancyLoadingEnabled: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var currentURL: String = ""
    @State private var isInitialLoading: Bool = true
    @State private var hasCompletedInitialLoad: Bool = false
    @State private var webView: WKWebView?
    
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
            
            // Floating toolbar at bottom
            VStack {
                Spacer()
                FloatingToolbar(
                    currentURL: currentURL.isEmpty ? urlString : currentURL,
                    webView: webView
                )
                .padding(.bottom, 20)
            }
        }
        .frame(width: 1280, height: 832)
        .onAppear {
            currentURL = urlString
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
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

// NSViewRepresentable for the vibrancy effect
struct VibrancyView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let vibrancyView = NSVisualEffectView()
        vibrancyView.blendingMode = .behindWindow
        vibrancyView.state = .active
        vibrancyView.material = .popover
        return vibrancyView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // The material automatically adapts to the system appearance
        // .popover material changes between light and dark based on system settings
    }
}