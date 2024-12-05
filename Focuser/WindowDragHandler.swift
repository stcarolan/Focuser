import SwiftUI
import AppKit

struct WindowDragHandler: NSViewRepresentable {
    let isEnabled: Bool
    
    class DragView: NSView {
        var isEnabled: Bool = true {
            didSet {
                if let window = window {
                    window.isMovableByWindowBackground = isEnabled
                }
            }
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window = window {
                window.isMovableByWindowBackground = isEnabled
            }
        }
    }
    
    func makeNSView(context: Context) -> DragView {
        let view = DragView()
        view.isEnabled = isEnabled
        return view
    }
    
    func updateNSView(_ nsView: DragView, context: Context) {
        nsView.isEnabled = isEnabled
    }
}

struct WindowDraggableModifier: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content.background(WindowDragHandler(isEnabled: isEnabled))
    }
}

extension View {
    func windowDraggable(isEnabled: Bool = true) -> some View {
        modifier(WindowDraggableModifier(isEnabled: isEnabled))
    }
}
