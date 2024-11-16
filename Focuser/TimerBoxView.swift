import SwiftUI

struct TimerBoxView: View {
    @Binding var text: String
    @State private var isEditing = false
    @State private var isTimeEditing = false
    @FocusState private var isFocused: Bool
    @FocusState private var isTimeFocused: Bool
    @Binding var elapsedSeconds: Int
    @Binding var lastUpdateTime: Date
    @Binding var isOnBreak: Bool
    @Binding var previousTask: String
    @Binding var previousElapsedSeconds: Int
    @Binding var isTimerActive: Bool
    @State private var timeEditText: String = "0"
    let fontSize: CGFloat
    let height: CGFloat
    let borderWidth: CGFloat
    
    private let logger = Logger()
    
    private let defaultText = "What's up next?"
    
    private func formatElapsedTime(_ seconds: Int) -> String {
        if !isTimerActive {
            return "0 secs"
        }
        if seconds < 60 {
            return "\(seconds) secs"
        } else if seconds < 3600 {
            return "\(seconds / 60) mins"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return String(format: "%d:%02d hrs", hours, minutes)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Group {
                if isEditing {
                    TextField("", text: $text, onCommit: {
                        isEditing = false
                        if text != defaultText && !text.isEmpty {
                            isTimerActive = true
                            resetTimer()
                        }
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.leading)
                    .focused($isFocused)
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
            
            // Time display
            if isTimeEditing {
                TextField("", text: $timeEditText, onCommit: {
                    if let newTime = Int(timeEditText) {
                        elapsedSeconds = newTime * 60
                        lastUpdateTime = Date().addingTimeInterval(TimeInterval(-elapsedSeconds))
                    }
                    isTimeEditing = false
                })
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .focused($isTimeFocused)
                .onAppear {
                    timeEditText = "\(elapsedSeconds / 60)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTimeFocused = true
                        selectAllText()
                    }
                }
            } else {
                Text(formatElapsedTime(elapsedSeconds))
                    .font(.system(size: fontSize - 4))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(alignment: .trailing)
                    .onTapGesture {
                        if isTimerActive {
                            timeEditText = "\(elapsedSeconds / 60)"
                            isTimeEditing = true
                        }
                    }
            }
            
            Spacer()
                .frame(width: 20)
            
            HStack(spacing: 10) {
                Button(action: {
                    if !isOnBreak {
                        logAndUpdateTask()
                        text = defaultText
                        isTimerActive = false
                        isEditing = true
                        isFocused = true
                        selectAllText()
                    }
                }) {
                    Text("✅")
                        .font(.system(size: fontSize))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: toggleBreak) {
                    Text("☕️")
                        .font(.system(size: fontSize))
                }
                .frame(alignment: .trailing)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.9))
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white, lineWidth: borderWidth)
                .padding(borderWidth/2)  // Add padding half the border width
        )
        .padding(borderWidth/2)  // Add padding half the border width
    }
    
    private func selectAllText() {
        if let window = NSApplication.shared.windows.first,
           let fieldEditor = window.fieldEditor(true, for: nil) as? NSTextView {
            fieldEditor.selectAll(nil)
        }
    }
    
    private func logAndUpdateTask() {
        if !text.isEmpty && text != defaultText {
            logger.logTask(taskName: text, elapsedTime: elapsedSeconds / 60)
        }
        resetTimer()
    }
    
    private func resetTimer() {
        lastUpdateTime = Date()
        elapsedSeconds = 0
    }
    
    private func toggleBreak() {
        if isOnBreak {
            text = previousTask
            lastUpdateTime = Date().addingTimeInterval(TimeInterval(-previousElapsedSeconds))
            isOnBreak = false
            isTimerActive = true
        } else {
            previousTask = text
            previousElapsedSeconds = elapsedSeconds
            text = "Break"
            lastUpdateTime = Date()
            isOnBreak = true
            isTimerActive = true
        }
        isEditing = false
    }
}
