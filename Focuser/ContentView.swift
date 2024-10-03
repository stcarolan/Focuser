import SwiftUI

struct ContentView: View {
    @State private var text = "What's up next?"
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @State private var lastUpdateTime = Date()
    @State private var elapsedTime = 0
    @State private var isOnBreak = false
    @State private var previousTask = ""
    @State private var previousElapsedTime = 0
    @State private var shouldSelectAllText = false
    @State private var frameWidth: CGFloat = 0
    @State private var isAwake = true

    private let minWidth: CGFloat = 0
    private let maxWidth: CGFloat = 750
    private let height: CGFloat = 40
    private let fontSize: CGFloat = 18
    private let borderWidth: CGFloat = 2
    
    private let logger = Logger()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if isEditing {
                    TextField("", text: $text, onCommit: {
                        isEditing = false
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.leading)
                    .focused($isFocused)
                    .onChange(of: text) { oldValue, newValue in
                        if oldValue != newValue && !isOnBreak {
                            resetTimer()
                        }
                    }
                } else {
                    Text(text)
                        .lineLimit(1)
                        .onTapGesture {
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                                selectAllText()
                            }
                        }
                }
            }
            .frame(alignment: .leading)
            .font(.system(size: fontSize))
            .foregroundColor(.white)
            
            Spacer()
                        
            Text("\(elapsedTime) mins")
                .font(.system(size: fontSize - 4))
                .foregroundColor(.white.opacity(0.8))
                .frame(alignment: .leading)
            
            Spacer()
                .frame(width: 20)
            
            HStack(spacing: 10) {
                Button(action: {
                    if !isOnBreak {
                        logAndUpdateTask()
                        text = "Next up?"
                        isEditing = true
                        isFocused = true
                        shouldSelectAllText = true
                    }
                }) {
                    Text("✅")
                        .font(.system(size: fontSize))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    if isOnBreak {
                        // Ending break, restore previous task
                        text = previousTask
                        elapsedTime = previousElapsedTime
                        isOnBreak = false
                        lastUpdateTime = Date().addingTimeInterval(TimeInterval(-elapsedTime * 60))
                    } else {
                        // Starting break
                        previousTask = text
                        previousElapsedTime = elapsedTime
                        text = "Break"
                        elapsedTime = 0
                        isOnBreak = true
                        lastUpdateTime = Date()
                    }
                    isEditing = false
                }) {
                    Text("☕️")
                        .font(.system(size: fontSize))
                }
                .frame(alignment: .trailing)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(15)
        .frame(width: calcFrameWidth(), height: height)
        .background(Color.blue.opacity(0.9))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: borderWidth)
        )
        .onReceive(timer) { _ in
            if isAwake {
                elapsedTime = Int(Date().timeIntervalSince(lastUpdateTime) / 60)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.willSleepNotification)) { _ in
            isAwake = false
            isEditing = false
            isFocused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)) { _ in
            isAwake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isEditing = true
                isFocused = true
                selectAllText()
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                isFocused = true
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
    
    private func selectAllText() {
        if let window = NSApplication.shared.windows.first,
           let fieldEditor = window.fieldEditor(true, for: nil) as? NSTextView {
            fieldEditor.selectAll(nil)
        }
    }
    
    private func logAndUpdateTask() {
        if !text.isEmpty && text != "What's up next?" {
            logger.logTask(taskName: text, elapsedTime: elapsedTime)
        }
        resetTimer()
    }
    
    private func resetTimer() {
        lastUpdateTime = Date()
        elapsedTime = 0
    }
}
