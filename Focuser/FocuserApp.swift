import SwiftUI

@main
struct FocuserApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background {
                    WindowAccessor { window in
                        configureWindow(window)
                    }
                }
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
    
    private func configureWindow(_ window: NSWindow?) {
        guard let window = window else { return }
        
        window.styleMask.remove(.titled)
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 10
        
        let delegate = WindowDelegate()
        window.delegate = delegate
        
        // Store delegate as associated object to keep it alive
        objc_setAssociatedObject(window, "windowDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
    }
}

class AppState: ObservableObject {
    @Published var isAppActive = true
}

// Simpler window access helper
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            callback(view?.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowDelegate: NSObject, NSWindowDelegate {
    override init() {
        super.init()
        
        // Set up sleep/wake notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    private func windowDidMove(_ notification: NSNotification) {
        // Marked as private to match NSWindowDelegate protocol exactly
        guard let window = notification.object as? NSWindow else { return }
        // Handle any post-move logic here if needed
    }
    
    @objc private func handleSleep() {
        if let window = NSApp.mainWindow {
            window.level = .normal
        }
    }
    
    @objc private func handleWake() {
        if let window = NSApp.mainWindow {
            window.level = .floating
            window.orderFront(nil)
        }
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Preserve window width during resize
        var newSize = frameSize
        newSize.height = 60  // Keep fixed height
        return newSize
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
