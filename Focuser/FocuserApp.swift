import SwiftUI

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

@main
struct FocuserApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        
        // Use only borderless and fullSizeContentView
        window.styleMask = [.borderless, .fullSizeContentView]
        
        // Make window interactive without title bar
        // window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        
        // Make window stay active
        window.hidesOnDeactivate = false
        window.canBecomeVisibleWithoutLogin = true
        
        // Enable mouse events
        window.acceptsMouseMovedEvents = true
        
        // Set initial size and allow resizing only vertically
        window.setContentSize(NSSize(width: 400, height: 60))
        window.minSize = NSSize(width: 250, height: 60)
        window.maxSize = NSSize(width: 850, height: 800)
        
        // Configure content view
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 10
        
        let delegate = WindowDelegate()
        window.delegate = delegate
        
        // Store delegate as associated object to keep it alive
        objc_setAssociatedObject(window, "windowDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        
        // Override the window's canBecomeKey behavior
        class CustomWindow: NSWindow {
            override var canBecomeKey: Bool {
                return true
            }
            
            override var canBecomeMain: Bool {
                return true
            }
        }
        
        // Create a new window with our custom behavior
        let customWindow = CustomWindow(
            contentRect: window.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        
        // Copy over the important properties
        customWindow.contentView = window.contentView
        // customWindow.isMovableByWindowBackground = true
        customWindow.isOpaque = false
        customWindow.backgroundColor = .clear
        customWindow.level = .floating
        customWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        customWindow.hasShadow = true
        customWindow.hidesOnDeactivate = false
        customWindow.canBecomeVisibleWithoutLogin = true
        customWindow.delegate = delegate
        
        // Replace the original window
        window.orderOut(nil)
        customWindow.makeKeyAndOrderFront(nil)
    }
}

class AppState: ObservableObject {
    @Published var isAppActive = true
}

class WindowDelegate: NSObject, NSWindowDelegate {
    override init() {
        super.init()
        
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
    
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        // Keep content at top when window resizes
        window.contentView?.frame.origin.y = window.frame.height - (window.contentView?.frame.height ?? 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
