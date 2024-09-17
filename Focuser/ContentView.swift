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
    
    private let minWidth: CGFloat = 250
    private let maxWidth: CGFloat = 650
    private let height: CGFloat = 60
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
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onChange(of: text) { oldValue, newValue in
                        if oldValue != newValue && !isOnBreak {
                            resetTimer()
                        }
                    }
                    .onChange(of: shouldSelectAllText) { oldValue, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.selectAllText()
                                self.shouldSelectAllText = false
                            }
                        }
                    }
                } else {
                    Text(text)
                        .onTapGesture {
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                                self.selectAllText()
                            }
                        }
                }
            }
            .font(.system(size: fontSize))
            .foregroundColor(.white)
            
            Spacer(minLength: 20)
                        
            Text("\(elapsedTime) minutes")
                .font(.system(size: fontSize - 4))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: {
                    if !isOnBreak {
                        logAndUpdateTask()
                        text = "What's up next?"
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
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: min(max(minWidth, textWidth() + 200), maxWidth), height: height)
        .background(Color.blue.opacity(0.9))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: borderWidth)
        )
        .onReceive(timer) { _ in
            elapsedTime = Int(Date().timeIntervalSince(lastUpdateTime) / 60)
        }
    }

    private func textWidth() -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
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
