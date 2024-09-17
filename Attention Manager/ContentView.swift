//
//  ContentView.swift
//  Attention Manager
//
//  Created by Shawn Carolan on 8/17/24.
//

import SwiftUI

struct ContentView: View {
    @State private var text = "Whatcha doin?"
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @State private var lastUpdateTime = Date()
    @State private var elapsedTime = 0
    @State private var previousTask = ""
    
    private let minWidth: CGFloat = 250
    private let maxWidth: CGFloat = 650
    private let height: CGFloat = 60
    private let fontSize: CGFloat = 18
    private let borderWidth: CGFloat = 2

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Group {
                if isEditing {
                    TextField("", text: $text, onCommit: {
                        isEditing = false
                        logAndUpdateTask()
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                } else {
                    Text(text)
                        .onTapGesture {
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                            }
                        }
                }
            }
            .font(.system(size: fontSize))
            .foregroundColor(.white)
            
            Spacer()
            
            Text("\(elapsedTime) minutes")
                .font(.system(size: fontSize - 4))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Button(action: {
                logAndUpdateTask()
                text = "Break"
            }) {
                Text("☕️")
                    .font(.system(size: fontSize))
            }
            .buttonStyle(PlainButtonStyle())
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
    
    private func logAndUpdateTask() {
        if !previousTask.isEmpty {
            logTask(taskName: previousTask, elapsedTime: elapsedTime)
        }
        previousTask = text
        lastUpdateTime = Date()
        elapsedTime = 0
    }
}
