import SwiftUI

struct TodoItemView: View {
    @Binding var item: TodoItem
    let onStart: () -> Void
    let onDelete: () -> Void
    
    @State private var editingText: String = ""
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
                        DispatchQueue.main.async {
                            isEditing = true
                        }
                    }
                    .onSubmit {
                        DispatchQueue.main.async {
                            var updatedItem = item
                            updatedItem.text = editingText
                            updatedItem.isEditing = false
                            item = updatedItem
                        }
                    }
                    .onExternalKeyPress(.escape) {
                        DispatchQueue.main.async {
                            var updatedItem = item
                            updatedItem.isEditing = false
                            item = updatedItem
                        }
                    }
            } else {
                Text(item.text)
                    .foregroundColor(.white)
                    .onTapGesture(count: 2) {
                        DispatchQueue.main.async {
                            var updatedItem = item
                            updatedItem.isEditing = true
                            item = updatedItem
                        }
                    }
            }
            
            Spacer()
            
            Button(action: onStart) {
                Text("▶️")
                    .font(.system(size: 15))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Text("×")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle()) // Make the entire row draggable
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
}

extension View {
    func onExternalKeyPress(_ key: KeyEquivalent, action: @escaping () -> Void) -> some View {
        self.background(KeyPressHandlerView(key: key, action: action))
    }
}

struct KeyPressHandlerView: NSViewRepresentable {
    let key: KeyEquivalent
    let action: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.key = key
        view.action = action
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class KeyView: NSView {
        var key: KeyEquivalent = "\0"
        var action: (() -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            if event.characters == String(key.character) {
                action?()
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
