import SwiftUI
import Metal

class AppState: ObservableObject {
    @Published var isAppActive = true
}

@main
struct FocuserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 250, minHeight: 60)
                .background(HostingWindowFinder { window in
                    window?.styleMask.remove(.titled)
                    window?.styleMask.insert(.fullSizeContentView)
                    window?.isMovableByWindowBackground = true
                    window?.backgroundColor = .clear
                    window?.isOpaque = false
                    window?.level = .floating
                    window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                    window?.contentView?.wantsLayer = true
                    window?.contentView?.layer?.cornerRadius = 20
                    
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        window?.delegate = appDelegate
                    }
                })
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
    
//    NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
//        updateWindowFrame()
//    }
}

struct HostingWindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var lastFrame: NSRect?
    var windowMonitor: Any?
    @ObservedObject private var appState = AppState()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            configureWindow(window)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillSleep(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidWake(_:)), name: NSWorkspace.didWakeNotification, object: nil)
    }

    func configureWindow(_ window: NSWindow) {
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.styleMask.remove(.titled)
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        
        window.contentMinSize = NSSize(width: 250, height: 60)
        window.contentMaxSize = NSSize(width: 650, height: 60)
        window.setContentSize(NSSize(width: 600, height: 60))

        window.makeKeyAndOrderFront(nil)

        windowMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak window] event in
            guard let window = window else { return }
            if event.type == .leftMouseUp {
                window.level = .floating
            } else if window.frame.intersects(NSRect(x: 0, y: NSScreen.main?.frame.height ?? 0, width: NSScreen.main?.frame.width ?? 0, height: 1)) {
                window.level = .normal
            }
        }
        
        lastFrame = window.frame
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard let lastFrame = lastFrame else { return frameSize }
        let newOrigin = NSPoint(x: lastFrame.maxX - frameSize.width, y: lastFrame.minY)
        sender.setFrameOrigin(newOrigin)
        return frameSize
    }
    
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            lastFrame = window.frame
        }
    }
    
    @objc func applicationWillSleep(_ notification: Notification) {
        appState.isAppActive = false
    }
    
    @objc func applicationDidWake(_ notification: Notification) {
        DispatchQueue.main.async {
            self.appState.isAppActive = true
            self.refreshWindowState()
        }
    }
    
    func refreshWindowState() {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating
            window.orderFront(nil)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let windowMonitor = windowMonitor {
            NSEvent.removeMonitor(windowMonitor)
        }
    }
    
    func updateWindowFrame() {
        if let window = NSApplication.shared.windows.first {
            let minSize = CGSize(width: 300, height: 300)
            window.setContentSize(minSize)
            window.styleMask = [.resizable, .titled]
        }
    }
}
