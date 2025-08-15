import SwiftUI
import AppKit
import Combine
import Sparkle

@main
struct PhimApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var vibrancyEnabled = true
    @State private var fancyLoadingEnabled = true
    
    var body: some Scene {
        WindowGroup {
            ContentView(urlString: appDelegate.urlString, vibrancyEnabled: vibrancyEnabled, fancyLoadingEnabled: fancyLoadingEnabled)
                .onAppear {
                    appDelegate.configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1280, height: 832)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appDelegate.updaterController.updater.checkForUpdates()
                }
            }
            CommandGroup(after: .toolbar) {
                Toggle("Vibrancy", isOn: $vibrancyEnabled)
                    .keyboardShortcut("V", modifiers: [.command, .shift])
                Toggle("Fancy loading", isOn: $fancyLoadingEnabled)
                    .keyboardShortcut("L", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var urlString: String = ""
    var window: NSWindow?
    var lastClipboardString: String = ""
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        loadURL()
        // Initialize clipboard tracking
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            lastClipboardString = clipboardString
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Customize menu bar
        customizeMenuBar()
        
        // Force create a window immediately
        if NSApplication.shared.windows.isEmpty {
            createAndShowWindow()
        } else {
            configureWindow()
        }
        
        // Ensure the app is active
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func customizeMenuBar() {
        // Remove unnecessary menu items
        if let mainMenu = NSApplication.shared.mainMenu {
            // Remove File menu items for new windows/tabs
            if let fileMenu = mainMenu.item(withTitle: "File")?.submenu {
                if let item = fileMenu.item(withTitle: "New") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "New Window") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "New Tab") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Open...") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Open Recent") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Save") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Save As...") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Revert to Saved") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Page Setup...") {
                    fileMenu.removeItem(item)
                }
                if let item = fileMenu.item(withTitle: "Print...") {
                    fileMenu.removeItem(item)
                }
            }
            
            // Remove Window menu items for tabs
            if let windowMenu = mainMenu.item(withTitle: "Window")?.submenu {
                if let item = windowMenu.item(withTitle: "Show Previous Tab") {
                    windowMenu.removeItem(item)
                }
                if let item = windowMenu.item(withTitle: "Show Next Tab") {
                    windowMenu.removeItem(item)
                }
                if let item = windowMenu.item(withTitle: "Move Tab to New Window") {
                    windowMenu.removeItem(item)
                }
                if let item = windowMenu.item(withTitle: "Merge All Windows") {
                    windowMenu.removeItem(item)
                }
            }
        }
    }
    
    func createAndShowWindow() {
        let contentView = NSHostingView(rootView: ContentView(urlString: self.urlString, vibrancyEnabled: true, fancyLoadingEnabled: true))
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 832),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = contentView
        window.setContentSize(NSSize(width: 1280, height: 832))
        window.center()
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.invalidateShadow()
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
    }
    
    func configureWindow() {
        if let window = NSApplication.shared.windows.first {
            window.styleMask = [.borderless, .fullSizeContentView]
            window.setContentSize(NSSize(width: 1280, height: 832))
            window.center()
            window.isMovableByWindowBackground = true
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.hasShadow = true
            window.invalidateShadow()
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Prevent creating new windows when dock icon is clicked
        return false
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Clipboard checking is now handled by ContentView with a prompt
        // checkClipboardForURL() - Disabled to prevent automatic loading
    }
    
    private func checkClipboardForURL() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string),
              !clipboardString.isEmpty,
              clipboardString != lastClipboardString else {
            return
        }
        
        // Check if it's a valid URL or file path
        var isValidURL = false
        var urlToLoad = ""
        
        // Check for URL patterns
        if clipboardString.hasPrefix("http://") || 
           clipboardString.hasPrefix("https://") ||
           clipboardString.hasPrefix("file://") {
            isValidURL = true
            urlToLoad = clipboardString
        } else if clipboardString.contains(".") && !clipboardString.contains(" ") {
            // Might be a domain like "example.com"
            if !clipboardString.hasPrefix("/") {
                // Try adding https://
                urlToLoad = "https://\(clipboardString)"
                isValidURL = true
            }
        } else if FileManager.default.fileExists(atPath: clipboardString) {
            // It's a file path
            urlToLoad = URL(fileURLWithPath: clipboardString).absoluteString
            isValidURL = true
        }
        
        if isValidURL && urlToLoad != self.urlString {
            // Update the last clipboard string
            lastClipboardString = clipboardString
            self.urlString = urlToLoad
            
            // Update the window with fade transition
            if let window = self.window ?? NSApplication.shared.windows.first {
                // Create new content view
                let newContentView = NSHostingView(
                    rootView: ContentView(
                        urlString: self.urlString,
                        vibrancyEnabled: true,
                        fancyLoadingEnabled: true
                    )
                )
                
                // Animate the transition
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    window.contentView?.animator().alphaValue = 0
                }) {
                    // After fade out, switch content and fade in
                    window.contentView = newContentView
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.3
                        window.contentView?.animator().alphaValue = 1
                    })
                }
            }
        }
    }
    
    // Handle files opened via "Open With" context menu
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        // Convert file path to file URL
        let fileURL = URL(fileURLWithPath: filename)
        self.urlString = fileURL.absoluteString
        
        // Update the existing window or create a new one
        if let window = self.window {
            // Update the content view with new URL
            window.contentView = NSHostingView(
                rootView: ContentView(
                    urlString: self.urlString,
                    vibrancyEnabled: true,
                    fancyLoadingEnabled: true
                )
            )
        } else if !NSApplication.shared.windows.isEmpty {
            // Update first window
            if let window = NSApplication.shared.windows.first {
                window.contentView = NSHostingView(
                    rootView: ContentView(
                        urlString: self.urlString,
                        vibrancyEnabled: true,
                        fancyLoadingEnabled: true
                    )
                )
            }
        }
        return true
    }
    
    // Handle multiple files
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        // For simplicity, just open the first file
        if let firstFile = filenames.first {
            _ = application(sender, openFile: firstFile)
        }
    }
    
    // Handle URLs opened via URL scheme
    func application(_ application: NSApplication, open urls: [URL]) {
        if let firstURL = urls.first {
            self.urlString = firstURL.absoluteString
            
            // Update the existing window
            if let window = self.window ?? NSApplication.shared.windows.first {
                window.contentView = NSHostingView(
                    rootView: ContentView(
                        urlString: self.urlString,
                        vibrancyEnabled: true,
                        fancyLoadingEnabled: true
                    )
                )
            }
        }
    }
    
    private func loadURL() {
        // Check for piped input first
        if !FileHandle.standardInput.isATTY {
            let inputData = FileHandle.standardInput.readDataToEndOfFile()
            if let input = String(data: inputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !input.isEmpty {
                // Check if it's a file path without file:// prefix
                if FileManager.default.fileExists(atPath: input) {
                    self.urlString = URL(fileURLWithPath: input).absoluteString
                } else {
                    self.urlString = input
                }
                return
            }
        }
        
        // Check command line arguments
        let args = CommandLine.arguments
        if args.count > 1 {
            let arg = args[1]
            // Check if it's a file path
            if FileManager.default.fileExists(atPath: arg) {
                self.urlString = URL(fileURLWithPath: arg).absoluteString
            } else if arg.hasPrefix("/") {
                // Absolute path that might not exist yet
                self.urlString = URL(fileURLWithPath: arg).absoluteString
            } else {
                // Assume it's a URL or relative path
                self.urlString = arg
            }
            return
        }
        
        // Default to welcome page if no URL provided
        if let welcomePath = Bundle.main.path(forResource: "welcome", ofType: "html") {
            self.urlString = "file://\(welcomePath)"
        } else {
            // Fallback if welcome.html is not found
            self.urlString = "https://example.com"
        }
    }
}

extension FileHandle {
    var isATTY: Bool {
        return isatty(fileDescriptor) != 0
    }
}