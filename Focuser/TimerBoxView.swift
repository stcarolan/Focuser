import SwiftUI

struct TimerBoxView: View {
    @Binding var text: String
    @Binding var elapsedSeconds: Int
    @Binding var lastUpdateTime: Date
    @Binding var isOnBreak: Bool
    @Binding var previousTask: String
    @Binding var previousElapsedSeconds: Int
    @Binding var isTimerActive: Bool
    @ObservedObject var todoStorage: TodoStorage
    
    @State private var dragOffset: CGPoint?
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @State private var isTimeEditing = false
    @State private var timeEditText: String = ""
    @FocusState private var isTimeFocused: Bool
    @State private var showingSnoozePopover = false
    @State private var selectedDate = Date()
    
    let fontSize: CGFloat
    let height: CGFloat
    let borderWidth: CGFloat
    
    private let defaultText = "Next up?"
    
    private var screen: NSScreen {
        NSScreen.main ?? NSScreen.screens[0]
    }

    private func getDefaultSnoozeDate() -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        // Set to 9:00 AM
        let components = DateComponents(
            year: Calendar.current.component(.year, from: tomorrow),
            month: Calendar.current.component(.month, from: tomorrow),
            day: Calendar.current.component(.day, from: tomorrow),
            hour: 9,
            minute: 0
        )
        return Calendar.current.date(from: components) ?? tomorrow
    }

    private func completeTaskAndStartNext(withShift: Bool) {
        if !isOnBreak {
            logAndUpdateTask()
            
            if withShift && !todoStorage.items.isEmpty {
                // Get the first todo item
                let nextItem = todoStorage.items[0]
                
                // Remove it from the list
                todoStorage.remove(at: 0)
                
                // Set it as the current task
                text = nextItem.text
                elapsedSeconds = nextItem.elapsedSeconds
                isTimerActive = true
            } else {
                text = defaultText
                isTimerActive = false
                isEditing = true
            }
        }
    }
    
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
                .frame(width: 20)
            
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
            
            HStack(spacing: 6) {
                Button(action: {}) {
                     Text("✅")
                         .font(.system(size: fontSize))
                 }
                 .buttonStyle(PlainButtonStyle())
                 .simultaneousGesture(
                     DragGesture(minimumDistance: 0)
                         .onEnded { value in
                             let isShiftHeld = NSEvent.modifierFlags.contains(.shift)
                             completeTaskAndStartNext(withShift: isShiftHeld)
                         }
                 )
                
                Button(action: {
                    selectedDate = getDefaultSnoozeDate()
                    showingSnoozePopover = true
                }) {
                    Text("🔔")
                        .font(.system(size: fontSize))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showingSnoozePopover, arrowEdge: .trailing) {
                    VStack(spacing: 12) {
                        DatePicker(
                            "Snooze until",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        
                        HStack {
                            Button("Cancel") {
                                showingSnoozePopover = false
                            }
                            .keyboardShortcut(.escape)
                            
                            Spacer()
                            
                            Button("Snooze") {
                                snoozeCurrentTask()
                                showingSnoozePopover = false
                            }
                            .keyboardShortcut(.return)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .frame(width: 300)
                }
                .disabled(text == defaultText || isOnBreak)
                
                Button(action: pauseTask) {
                    Text("⏸️")
                        .font(.system(size: fontSize))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(text == defaultText || isOnBreak)
                
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
        .simultaneousGesture(
            DragGesture()
                .onChanged { gesture in
                    if let window = NSApp.keyWindow {
                        let translation = gesture.translation
                        let currentPosition = window.frame.origin
                        window.setFrameOrigin(NSPoint(
                            x: currentPosition.x + translation.width,
                            y: currentPosition.y - translation.height
                        ))
                    }
                }
        )
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
    
    private func pauseTask() {
        if text != defaultText && !isOnBreak {
            // Create new todo item from current task
            let pausedItem = TodoItem(
                id: UUID(),
                text: text,
                elapsedSeconds: elapsedSeconds
            )
            // Add to the beginning of the todo list
            todoStorage.addToTop(pausedItem)
            
            // Reset the current task state
            isTimerActive = false
            text = defaultText
            elapsedSeconds = 0
            lastUpdateTime = Date()
        }
    }
    
    private func snoozeCurrentTask() {
        if text != defaultText && !isOnBreak {
            // Create new todo item from current task with snooze time
            let snoozedItem = TodoItem(
                id: UUID(),
                text: text,
                elapsedSeconds: elapsedSeconds,
                snoozeUntil: selectedDate
            )
            // Add to the beginning of the todo list
            todoStorage.addToTop(snoozedItem)
            
            // Reset the current task state
            isTimerActive = false
            text = defaultText
            elapsedSeconds = 0
            lastUpdateTime = Date()
            
            // Ensure window remains active
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first {
                    window.makeKey()
                }
            }
        }
    }

    private func logAndUpdateTask() {
        if !text.isEmpty && text != defaultText {
            Logger().logTask(taskName: text, elapsedTime: elapsedSeconds / 60)
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
            elapsedSeconds = previousElapsedSeconds
            // Only start the timer if we're returning to a real task
            if text != defaultText {
                lastUpdateTime = Date().addingTimeInterval(TimeInterval(-previousElapsedSeconds))
                isTimerActive = true
            } else {
                isTimerActive = false
            }
            isOnBreak = false
        } else {
            previousTask = text
            previousElapsedSeconds = elapsedSeconds
            text = "Enjoy the break!"
            resetTimer()
            isOnBreak = true
            isTimerActive = true
        }
        isEditing = false
    }
}
