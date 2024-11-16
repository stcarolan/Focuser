import Foundation
import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isEditing: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, text
        // isEditing is transient and not stored
    }
}

class TodoStorage: ObservableObject {
    @Published var items: [TodoItem] = [] {
        didSet {
            save()
        }
    }
    
    private let key = "stored_todos"
    
    init() {
        load()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            items = decoded
        }
    }
    
    func add(_ item: TodoItem) {
        items.append(item)
    }
    
    func remove(at index: Int) {
        items.remove(at: index)
    }
    
    func update(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    
    // Single move method that handles both IndexSet and direct index moves
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}
