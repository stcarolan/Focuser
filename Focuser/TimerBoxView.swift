import SwiftUI

struct TimerBoxView: View {
    @Binding var text: String
    @Binding var elapsedSeconds: Int
    @Binding var lastUpdateTime: Date
    @Binding var isOnBreak: Bool
    @Binding var previousTask: String
    @Binding var previousElapsedSeconds: Int
    @Binding var isTimerActive: Bool
    
    @State private var isEditing = false
    @State private var isTimeEditing = false
    @State private var timeEditText: String = ""
    @FocusState private var isFocused: Bool
    @FocusState private var isTimeFocused: Bool
    
    let fontSize: CGFloat
    let height: CGFloat
    let borderWidth: CGFloat
    
    private let logger = Logger()
    private let defaultText = "What's up next?"
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if isEditing {
                    TextField("", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isFocused)
                        .font(.system(size: fontSize))
                        .foregroundColor(.white)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                                selectAllText()
                            }
                        }
                        .onSubmit {
                            endEditing()
                        }
                } else {
                    Text(text)
                        .font(.system(size: fontSize))
                        .foregroundColor(.white)
                        .onTapGesture {
                            isEditing = true
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if isTimeEditing {
                HStack(spacing: 4) {
                    TextField("", text: $timeEditText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isTimeFocused)
                        .font(.system(size: fontSize - 4))
                        .foregroundColor(.white)
                        .frame(width: 35)
                        .multilineTextAlignment(.trailing)
                        .onAppear {
                            timeEditText = String(elapsedSeconds / 60)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTimeFocused = true
                            }
                        }
                        .onSubmit {
                            if let minutes = Int(timeEditText) {
                                elapsedSeconds = minutes * 60
                                lastUpdateTime = Date().addingTimeInterval(TimeInterval(-elapsedSeconds))
                            }
                            isTimeEditing = false
                        }
                    
                    Text("mins")
                        .font(.system(size: fontSize - 4))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 80)
            } else {
                Text(formatElapsedTime(elapsedSeconds))
                    .font(.system(size: fontSize - 4))
                    .foregroundColor(.white.opacity(0.8))
                    .onTapGesture {
                        isTimeEditing = true
                    }
                    .frame(width: 80)
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
                .padding(borderWidth/2)
        )
        .padding(borderWidth/2)
    }
    
    private func endEditing() {
        isEditing = false
        if text != defaultText && !text.isEmpty {
            isTimerActive = true
            resetTimer()
        }
    }
    
    private func selectAllText() {
        if let window = NSApplication.shared.windows.first,
           let fieldEditor = window.fieldEditor(true, for: nil) as? NSTextView {
            fieldEditor.selectAll(nil)
        }
    }
    
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
