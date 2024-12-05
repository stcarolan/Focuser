import SwiftUI
import AppKit

    struct ContentView: View {
    @StateObject private var todoStorage = TodoStorage()
    @State private var text = "Next up?"
    @State private var lastUpdateTime = Date()
    @State private var elapsedSeconds = 0
    @State private var isOnBreak = false
    @State private var previousTask = ""
    @State private var previousElapsedSeconds = 0
    @State private var frameWidth: CGFloat = 330
    @State private var showTodoList = false
    @State private var isTimerActive = false
    @State private var hoverWorkItem: DispatchWorkItem?
    
    private let minWidth: CGFloat = 360
    private let maxWidth: CGFloat = 900
    private let height: CGFloat = 24
    private let fontSize: CGFloat = 18
    private let borderWidth: CGFloat = 2
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            TimerBoxView(
                text: $text,
                elapsedSeconds: $elapsedSeconds,
                lastUpdateTime: $lastUpdateTime,
                isOnBreak: $isOnBreak,
                previousTask: $previousTask,
                previousElapsedSeconds: $previousElapsedSeconds,
                isTimerActive: $isTimerActive,
                todoStorage: todoStorage,
                fontSize: fontSize,
                height: height,
                borderWidth: borderWidth
            )
            .frame(width: calcFrameWidth())
            .onHover { hovering in
                hoverWorkItem?.cancel()
                
                if hovering {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    let workItem = DispatchWorkItem {
                        withAnimation(.spring(duration: 0.3)) {
                            showTodoList = true
                        }
                    }
                    hoverWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
                }
            }
            
            if showTodoList {
                TodoListView(
                    todoStorage: todoStorage,
                    showTodoList: $showTodoList,
                    text: $text,
                    elapsedSeconds: $elapsedSeconds,
                    lastUpdateTime: $lastUpdateTime,
                    frameWidth: calcFrameWidth(),
                    borderWidth: borderWidth,
                    onTaskStart: {
                        isTimerActive = true
//                        lastUpdateTime = Date()
//                        elapsedSeconds = 0
                        showTodoList = false
                    }
                )
                .transition(.move(edge: .top))
            }
            Spacer(minLength: 0)
        }
        .onReceive(timer) { _ in
            if isTimerActive {
                elapsedSeconds = Int(Date().timeIntervalSince(lastUpdateTime))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            withAnimation(.spring(duration: 0.3)) {
                showTodoList = false
            }
        }
    }
    
    private func calcFrameWidth() -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        var frameWidth = max(minWidth, size.width + 290)
        frameWidth = min(frameWidth, maxWidth)
        return frameWidth
    }
}
