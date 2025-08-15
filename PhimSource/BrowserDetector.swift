import Foundation
import AppKit

class BrowserDetector {
    static let shared = BrowserDetector()
    
    private init() {}
    
    struct BrowserTab {
        let url: String
        let title: String
        let browserName: String
    }
    
    // Get the current tab from the frontmost browser
    func getCurrentBrowserTab() -> BrowserTab? {
        // First check which browser is frontmost
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            let bundleID = frontmostApp.bundleIdentifier ?? ""
            
            switch bundleID {
            case "com.apple.Safari":
                if isBrowserRunning("Safari") {
                    return getSafariCurrentTab()
                }
            case "com.google.Chrome":
                if isBrowserRunning("Google Chrome") {
                    return getChromeCurrentTab()
                }
            case "com.brave.Browser":
                if isBrowserRunning("Brave Browser") {
                    return getBraveCurrentTab()
                }
            case "com.microsoft.edgemac":
                if isBrowserRunning("Microsoft Edge") {
                    return getEdgeCurrentTab()
                }
            case "org.mozilla.firefox":
                // Firefox doesn't support AppleScript well
                return nil
            case "com.vivaldi.Vivaldi":
                if isBrowserRunning("Vivaldi") {
                    return getVivaldiCurrentTab()
                }
            default:
                // If no browser is frontmost, try to find the most recently used one
                return getMostRecentBrowserTab()
            }
        }
        
        return getMostRecentBrowserTab()
    }
    
    private func getMostRecentBrowserTab() -> BrowserTab? {
        // Try browsers in order of likelihood, but only if they're running
        if isBrowserRunning("Safari"), let tab = getSafariCurrentTab() { return tab }
        if isBrowserRunning("Google Chrome"), let tab = getChromeCurrentTab() { return tab }
        if isBrowserRunning("Brave Browser"), let tab = getBraveCurrentTab() { return tab }
        if isBrowserRunning("Microsoft Edge"), let tab = getEdgeCurrentTab() { return tab }
        if isBrowserRunning("Vivaldi"), let tab = getVivaldiCurrentTab() { return tab }
        return nil
    }
    
    private func isBrowserRunning(_ browserName: String) -> Bool {
        // Check if the browser is currently running
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { app in
            app.localizedName == browserName
        }
    }
    
    private func getSafariCurrentTab() -> BrowserTab? {
        guard isBrowserRunning("Safari") else { return nil }
        
        let script = """
        tell application "Safari"
            if (count of windows) > 0 then
                set currentTab to current tab of front window
                set tabURL to URL of currentTab
                set tabTitle to name of currentTab
                return tabURL & "|||" & tabTitle
            end if
        end tell
        """
        
        if let result = runAppleScript(script) {
            let parts = result.split(separator: "|||").map(String.init)
            if parts.count >= 2 {
                return BrowserTab(url: parts[0], title: parts[1], browserName: "Safari")
            }
        }
        return nil
    }
    
    private func getChromeCurrentTab() -> BrowserTab? {
        guard isBrowserRunning("Google Chrome") else { return nil }
        
        let script = """
        tell application "Google Chrome"
            if (count of windows) > 0 then
                set tabURL to URL of active tab of front window
                set tabTitle to title of active tab of front window
                return tabURL & "|||" & tabTitle
            end if
        end tell
        """
        
        if let result = runAppleScript(script) {
            let parts = result.split(separator: "|||").map(String.init)
            if parts.count >= 2 {
                return BrowserTab(url: parts[0], title: parts[1], browserName: "Chrome")
            }
        }
        return nil
    }
    
    private func getBraveCurrentTab() -> BrowserTab? {
        guard isBrowserRunning("Brave Browser") else { return nil }
        
        let script = """
        tell application "Brave Browser"
            if (count of windows) > 0 then
                set tabURL to URL of active tab of front window
                set tabTitle to title of active tab of front window
                return tabURL & "|||" & tabTitle
            end if
        end tell
        """
        
        if let result = runAppleScript(script) {
            let parts = result.split(separator: "|||").map(String.init)
            if parts.count >= 2 {
                return BrowserTab(url: parts[0], title: parts[1], browserName: "Brave")
            }
        }
        return nil
    }
    
    private func getEdgeCurrentTab() -> BrowserTab? {
        guard isBrowserRunning("Microsoft Edge") else { return nil }
        
        let script = """
        tell application "Microsoft Edge"
            if (count of windows) > 0 then
                set tabURL to URL of active tab of front window
                set tabTitle to title of active tab of front window
                return tabURL & "|||" & tabTitle
            end if
        end tell
        """
        
        if let result = runAppleScript(script) {
            let parts = result.split(separator: "|||").map(String.init)
            if parts.count >= 2 {
                return BrowserTab(url: parts[0], title: parts[1], browserName: "Edge")
            }
        }
        return nil
    }
    
    private func getFirefoxCurrentTab() -> BrowserTab? {
        // Firefox doesn't support AppleScript well, so we can't get the URL
        // Return nil for now
        return nil
    }
    
    private func getVivaldiCurrentTab() -> BrowserTab? {
        guard isBrowserRunning("Vivaldi") else { return nil }
        
        let script = """
        tell application "Vivaldi"
            if (count of windows) > 0 then
                set tabURL to URL of active tab of front window
                set tabTitle to title of active tab of front window
                return tabURL & "|||" & tabTitle
            end if
        end tell
        """
        
        if let result = runAppleScript(script) {
            let parts = result.split(separator: "|||").map(String.init)
            if parts.count >= 2 {
                return BrowserTab(url: parts[0], title: parts[1], browserName: "Vivaldi")
            }
        }
        return nil
    }
    
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        
        guard let scriptObject = NSAppleScript(source: script) else {
            return nil
        }
        
        let output = scriptObject.executeAndReturnError(&error)
        
        if let error = error {
            debugPrint("AppleScript error: \(error)", type: .error)
            return nil
        }
        
        return output.stringValue
    }
    
    // Check if we have permission to control System Events
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        return AXIsProcessTrustedWithOptions(options)
    }
}