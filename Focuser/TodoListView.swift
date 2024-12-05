import SwiftUI

struct TodoInputField: View {
    @Binding var newTodoText: String
    let onSubmit: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            TextField("Add todo (* for top)...", text: $newTodoText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }
                .onSubmit {
                    onSubmit()
                    isFocused = true
                }
        }
        .padding(4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TodoDropDelegate: DropDelegate {
    let todoStorage: TodoStorage
    let item: TodoItem
    @Binding var dragItem: TodoItem?

    func dropEntered(info: DropInfo) {
        guard let dragItem = dragItem,
              dragItem != item else { return }
              
        // Get the indices from the visible items array
        guard let fromIndex = todoStorage.items.firstIndex(where: { $0.id == dragItem.id }),
              let toIndex = todoStorage.items.firstIndex(where: { $0.id == item.id }) else { return }

        if fromIndex != toIndex {
            withAnimation {
                // Use the TodoStorage move method instead of directly modifying items
                todoStorage.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        dragItem = nil // Clear the drag item after the drop
        return true
    }
}

struct TodoListContent: View {
    @ObservedObject var todoStorage: TodoStorage
    @Binding var text: String
    @Binding var showTodoList: Bool
    @Binding var elapsedSeconds: Int
    @Binding var lastUpdateTime: Date
    let frameWidth: CGFloat
    let onTaskStart: () -> Void

    @State private var dragItem: TodoItem?

    var body: some View {
        //LazyVStack(spacing: 4) {
        VStack(spacing: 4) {
            ForEach(todoStorage.items) { item in
                    TodoItemView(
                        item: Binding(
                            get: { item },
                            set: { todoStorage.update($0) }
                        ),
                        onStart: {
                            text = item.text
                            showTodoList = false
                            if let index = todoStorage.items.firstIndex(where: { $0.id == item.id }) {
                                todoStorage.remove(at: index)
                            }
                            onTaskStart()
                        },
                        onDelete: {
                            if let index = todoStorage.items.firstIndex(where: { $0.id == item.id }) {
                                todoStorage.remove(at: index)
                            }
                        }
                    )
                    .onDrag {
                        dragItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: TodoDropDelegate(
                        todoStorage: todoStorage,
                        item: item,
                        dragItem: $dragItem
                    ))
                    .opacity(dragItem?.id == item.id ? 0 : 1)
                    .contentShape(Rectangle()) // Ensures the draggable area is recognized
                    .background(Color.clear)   // Prevents window drag
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle()) // Ensures the draggable area is recognized
            .background(Color.clear)   // Prevents window drag
        }
}

struct TodoListView: View {
    @ObservedObject var todoStorage: TodoStorage
    @Binding var showTodoList: Bool
    @State private var newTodoText = ""
    @Binding var text: String
    @Binding var elapsedSeconds: Int
    @Binding var lastUpdateTime: Date
    let frameWidth: CGFloat
    let borderWidth: CGFloat
    let onTaskStart: () -> Void
    
    private func addNewTodo() {
        // First trim whitespace from both ends
        let trimmedText = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Check if the trimmed text starts or ends with an asterisk
        let isPriority = trimmedText.hasPrefix("*") || trimmedText.hasSuffix("*")
        
        // Clean the text by removing asterisks and any remaining whitespace
        let cleanText = trimmedText
            .trimmingCharacters(in: CharacterSet(charactersIn: "*"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanText.isEmpty else { return }
        
        let newItem = TodoItem(id: UUID(), text: cleanText)
        
        // Add to top if priority, otherwise add to bottom
        if isPriority {
            todoStorage.addToTop(newItem)
        } else {
            todoStorage.add(newItem)
        }
        
        newTodoText = ""
    }

    var body: some View {
        VStack(spacing: 8) {
            TodoInputField(
                newTodoText: $newTodoText,
                onSubmit: addNewTodo
            )
            
            TodoListContent(
                todoStorage: todoStorage,
                text: $text,
                showTodoList: $showTodoList,
                elapsedSeconds: $elapsedSeconds,
                lastUpdateTime: $lastUpdateTime,
                frameWidth: frameWidth,
                onTaskStart: onTaskStart
            )
        }
        .padding(10)
        .frame(width: frameWidth)
        .background(Color.blue.opacity(0.9))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white, lineWidth: borderWidth)
        )
        .transition(
            .asymmetric(
                insertion: .offset(y: -20).combined(with: .opacity),
                removal: .offset(y: -20).combined(with: .opacity)
            )
        )
    }
}
