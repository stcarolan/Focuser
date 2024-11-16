import SwiftUI

struct ContentView: View {
    @StateObject private var todoStorage = TodoStorage()
    @State private var text = "What's up next?"
    @State private var lastUpdateTime = Date()
    @State private var elapsedSeconds = 0
    @State private var isOnBreak = false
    @State private var previousTask = ""
    @State private var previousElapsedSeconds = 0
    @State private var frameWidth: CGFloat = 330
    @State private var isDraggingTodo = false
    @State private var showTodoList = false
    @State private var isTimerActive = false  // New state to track if timer should be running
    
    private let minWidth: CGFloat = 250
    private let maxWidth: CGFloat = 850
    private let height: CGFloat = 24
    private let fontSize: CGFloat = 18
    private let borderWidth: CGFloat = 2
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())
                .frame(height: 30)
                .position(x: calcFrameWidth() / 2, y: 25)
            
            VStack(spacing: 0) {
                TimerBoxView(
                    text: $text,
                    elapsedSeconds: $elapsedSeconds,
                    lastUpdateTime: $lastUpdateTime,
                    isOnBreak: $isOnBreak,
                    previousTask: $previousTask,
                    previousElapsedSeconds: $previousElapsedSeconds,
                    isTimerActive: $isTimerActive,  // Pass the new binding
                    fontSize: fontSize,
                    height: height,
                    borderWidth: borderWidth
                )
                .frame(width: calcFrameWidth())
                .onTapGesture(count: 2) {
                    withAnimation(.spring(duration: 0.3)) {
                        showTodoList.toggle()
                    }
                }
                
                if showTodoList {
                    TodoListView(
                        todoStorage: todoStorage,
                        showTodoList: $showTodoList,
                        text: $text,
                        frameWidth: calcFrameWidth(),
                        borderWidth: borderWidth,
                        onDragBegan: {
                            Task { @MainActor in
                                isDraggingTodo = true
                            }
                        },
                        onDragEnded: {
                            Task { @MainActor in
                                isDraggingTodo = false
                            }
                        },
                        onTaskStart: { // New closure for starting tasks from todo list
                            isTimerActive = true
                            lastUpdateTime = Date()
                            elapsedSeconds = 0
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }
            }
        }
        .onAppear {
            if let window = NSApp.windows.first {
                window.isMovableByWindowBackground = true
            }
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    if showTodoList {
                        withAnimation(.spring(duration: 0.3)) {
                            showTodoList = false
                        }
                    }
                }
            }
        }
        .onChange(of: showTodoList) { _, isShowing in
            Task { @MainActor in
                if let window = NSApp.windows.first {
                    window.isMovableByWindowBackground = true
                }
            }
        }
        .onReceive(timer) { _ in
            Task { @MainActor in
                if isTimerActive {
                    elapsedSeconds = Int(Date().timeIntervalSince(lastUpdateTime))
                }
            }
        }
    }
    
    private func calcFrameWidth() -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        var frameWidth = max(minWidth, size.width + 200)
        frameWidth = min(frameWidth, maxWidth)
        return frameWidth
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() // Replace `ContentView` with your view name
    }
}
