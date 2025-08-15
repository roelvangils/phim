import SwiftUI
import AppKit

// Singleton to manage console messages
class DebugConsoleManager: ObservableObject {
    static let shared = DebugConsoleManager()
    
    @Published var messages: [ConsoleMessage] = []
    private var consoleWindow: NSWindow?
    
    struct ConsoleMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: MessageType
        
        enum MessageType {
            case log
            case error
            case info
        }
        
        var color: Color {
            switch type {
            case .log: return .primary
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    func log(_ message: String) {
        DispatchQueue.main.async {
            self.messages.append(ConsoleMessage(timestamp: Date(), message: message, type: .log))
            self.scrollToBottom()
        }
    }
    
    func error(_ message: String) {
        DispatchQueue.main.async {
            self.messages.append(ConsoleMessage(timestamp: Date(), message: message, type: .error))
            self.scrollToBottom()
        }
    }
    
    func info(_ message: String) {
        DispatchQueue.main.async {
            self.messages.append(ConsoleMessage(timestamp: Date(), message: message, type: .info))
            self.scrollToBottom()
        }
    }
    
    func clear() {
        messages.removeAll()
    }
    
    private func scrollToBottom() {
        // Trigger scroll to bottom when new message added
    }
    
    func showConsole() {
        if consoleWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "Phim Debug Console"
            window.level = .floating
            window.isReleasedWhenClosed = false
            
            let consoleView = DebugConsoleView()
                .environmentObject(self)
            
            window.contentView = NSHostingView(rootView: consoleView)
            consoleWindow = window
        }
        
        consoleWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideConsole() {
        consoleWindow?.orderOut(nil)
    }
    
    func toggleConsole() {
        if consoleWindow?.isVisible == true {
            hideConsole()
        } else {
            showConsole()
        }
    }
}

struct DebugConsoleView: View {
    @EnvironmentObject var consoleManager: DebugConsoleManager
    @State private var searchText = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    var filteredMessages: [DebugConsoleManager.ConsoleMessage] {
        if searchText.isEmpty {
            return consoleManager.messages
        }
        return consoleManager.messages.filter { 
            $0.message.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                Spacer()
                
                Button("Clear") {
                    consoleManager.clear()
                }
                
                Button("Copy All") {
                    let allMessages = consoleManager.messages
                        .map { "[\(dateFormatter.string(from: $0.timestamp))] \($0.message)" }
                        .joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(allMessages, forType: .string)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Console output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredMessages) { message in
                            HStack(alignment: .top, spacing: 8) {
                                Text("[\(dateFormatter.string(from: message.timestamp))]")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text(message.message)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(message.color)
                                    .textSelection(.enabled)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .id(message.id)
                        }
                        
                        // Invisible anchor for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: consoleManager.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// Helper function to redirect print statements
func debugPrint(_ message: String, type: DebugConsoleManager.ConsoleMessage.MessageType = .log) {
    print(message) // Still print to terminal
    
    switch type {
    case .log:
        DebugConsoleManager.shared.log(message)
    case .error:
        DebugConsoleManager.shared.error(message)
    case .info:
        DebugConsoleManager.shared.info(message)
    }
}