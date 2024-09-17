import SwiftUI
import Metal

@main
struct FocuserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 300, minHeight: 60)
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
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            configureWindow(window)
        }
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

        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak window] event in
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
}
