import SwiftUI

struct TodoItemView: View {
    @Binding var item: TodoItem
    let onStart: () -> Void
    let onDelete: () -> Void
    
    @State private var editingText: String = ""
    @State private var isHovered: Bool = false
    @FocusState private var isEditing: Bool
    
    var body: some View {
        HStack {
            if item.isEditing {
                TextField("", text: $editingText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .focused($isEditing)
                    .onAppear {
                        editingText = item.text
                        isEditing = true
                    }
                    .onSubmit {
                        var updatedItem = item
                        updatedItem.text = editingText
                        updatedItem.isEditing = false
                        item = updatedItem
                    }
                    .onKeyPress(.escape) {
                        var updatedItem = item
                        updatedItem.isEditing = false
                        item = updatedItem
                        return .handled
                    }
            } else {
                Text(item.text)
                    .foregroundColor(.white)
                    .onTapGesture(count: 2) {
                        var updatedItem = item
                        updatedItem.isEditing = true
                        item = updatedItem
                    }
            }
            
            Spacer()
            
            if isHovered {
                HStack(spacing: 10) {
                    Button(action: onStart) {
                        Text(">")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onDelete) {
                        Text("×")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(Color.clear)
    }
}
