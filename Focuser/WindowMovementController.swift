import SwiftUI
import AppKit

struct WindowMovementController: NSViewRepresentable {
    let isEnabled: Bool
    
    class WindowControllerView: NSView {
        var isEnabled: Bool = true {
            didSet {
                if let window = self.window {
                    window.isMovableByWindowBackground = isEnabled
                }
            }
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window = self.window {
                window.isMovableByWindowBackground = isEnabled
            }
        }
    }
    
    func makeNSView(context: Context) -> WindowControllerView {
        let view = WindowControllerView()
        view.isEnabled = isEnabled
        return view
    }
    
    func updateNSView(_ nsView: WindowControllerView, context: Context) {
        nsView.isEnabled = isEnabled
    }
}
