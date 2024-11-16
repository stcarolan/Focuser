import SwiftUI

struct DropPreview: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(height: 2)
            .padding(.horizontal, 4)
    }
}

struct TodoInputField: View {
    @Binding var newTodoText: String
    @FocusState private var isFocused: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Add new todo...", text: $newTodoText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }
                .onSubmit {
                    onSubmit()
                    // Keep focus after submitting
                    isFocused = true
                }
        }
        .padding(4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TodoListContent: View {
    @ObservedObject var todoStorage: TodoStorage
    @Binding var text: String
    @Binding var showTodoList: Bool
    let frameWidth: CGFloat
    let onDragBegan: () -> Void
    let onDragEnded: () -> Void
    let onTaskStart: () -> Void
    
    var body: some View {
        LazyVStack(spacing: 4) {
            ForEach(todoStorage.items) { item in
                TodoItemView(
                    item: Binding(
                        get: { item },
                        set: { todoStorage.update($0) }
                    ),
                    onStart: {
                        DispatchQueue.main.async {
                            text = item.text
                            showTodoList = false
                            if let index = todoStorage.items.firstIndex(where: { $0.id == item.id }) {
                                todoStorage.remove(at: index)
                            }
                            onTaskStart()
                        }
                    },
                    onDelete: {
                        DispatchQueue.main.async {
                            if let index = todoStorage.items.firstIndex(where: { $0.id == item.id }) {
                                todoStorage.remove(at: index)
                            }
                        }
                    }
                )
                .transition(.opacity)
                .draggable(item.id.uuidString) {
                    onDragBegan()
                    return TodoItemView(
                        item: .constant(item),
                        onStart: {},
                        onDelete: {}
                    )
                    .frame(width: frameWidth - 40)
                    .background(Color.blue)
                    .cornerRadius(6)
                    .opacity(0.8)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

struct TodoListView: View {
    @ObservedObject var todoStorage: TodoStorage
    @Binding var showTodoList: Bool
    @State private var newTodoText = ""
    @Binding var text: String
    let frameWidth: CGFloat
    let borderWidth: CGFloat
    let onDragBegan: () -> Void
    let onDragEnded: () -> Void
    let onTaskStart: () -> Void
    
    private func addNewTodo() {
        guard !newTodoText.isEmpty else { return }
        DispatchQueue.main.async {
            let newItem = TodoItem(id: UUID(), text: newTodoText)
            todoStorage.add(newItem)
            newTodoText = ""
        }
    }
    
    var body: some View {
        if showTodoList {
            VStack(spacing: 8) {
                TodoInputField(
                    newTodoText: $newTodoText,
                    onSubmit: addNewTodo
                )
                
                TodoListContent(
                    todoStorage: todoStorage,
                    text: $text,
                    showTodoList: $showTodoList,
                    frameWidth: frameWidth,
                    onDragBegan: onDragBegan,
                    onDragEnded: onDragEnded,
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
            .dropDestination(for: String.self) { items, location in
                guard let droppedId = items.first,
                      let sourceIndex = todoStorage.items.firstIndex(where: { $0.id.uuidString == droppedId })
                else { return false }
                
                let itemHeight: CGFloat = 35
                let headerHeight: CGFloat = 60
                let relativeY = location.y - headerHeight
                let destinationRow = max(0, min(Int(relativeY / itemHeight), todoStorage.items.count - 1))
                
                if sourceIndex != destinationRow {
                    DispatchQueue.main.async {
                        var newItems = todoStorage.items
                        let movedItem = newItems[sourceIndex]
                        newItems.remove(at: sourceIndex)
                        let finalDestination = destinationRow >= sourceIndex ? destinationRow : destinationRow
                        newItems.insert(movedItem, at: finalDestination)
                        todoStorage.items = newItems
                    }
                }
                
                onDragEnded()
                return true
            }
        }
    }
}
