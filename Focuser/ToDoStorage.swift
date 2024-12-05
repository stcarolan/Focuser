import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var elapsedSeconds: Int = 0
    var isEditing: Bool = false
    var snoozeUntil: Date? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, text, elapsedSeconds, snoozeUntil
        // isEditing is transient and not stored
    }
}

class TodoStorage: ObservableObject {
    private var allItems: [TodoItem] = [] {
        didSet {
            filterAndSortItems()
            save()
        }
    }
    
    @Published private(set) var items: [TodoItem] = []
    
    private let key = "stored_todos"
    
    // Define the old data structure for migration
    private struct LegacyTodoItem: Codable {
        let id: UUID
        var text: String
    }
    
    init() {
        loadWithMigration()
        startSnoozeTimer()
    }
    
    private func filterAndSortItems() {
        let now = Date()
        items = allItems.filter { item in
            if let snoozeUntil = item.snoozeUntil {
                return now >= snoozeUntil
            }
            return true
        }
    }
    
    private func startSnoozeTimer() {
        // Check every minute for expired snoozes
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.filterAndSortItems()
        }
    }
    
    private func loadWithMigration() {
        if let data = UserDefaults.standard.data(forKey: key) {
            // First try to decode with new format
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                allItems = decoded
                filterAndSortItems()
            } else {
                // If that fails, try to decode with old format and migrate
                if let legacyItems = try? JSONDecoder().decode([LegacyTodoItem].self, from: data) {
                    // Convert old items to new format
                    allItems = legacyItems.map { oldItem in
                        TodoItem(id: oldItem.id, text: oldItem.text, elapsedSeconds: 0)
                    }
                    filterAndSortItems()
                    // Save in new format
                    save()
                }
            }
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(allItems) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // CRUD Operations
    func addToTop(_ item: TodoItem) {
        allItems.insert(item, at: 0)
    }
    
    func add(_ item: TodoItem) {
        allItems.append(item)
    }
    
    func remove(at index: Int) {
        // Find the corresponding index in allItems
        let itemToRemove = items[index]
        if let allItemsIndex = allItems.firstIndex(where: { $0.id == itemToRemove.id }) {
            allItems.remove(at: allItemsIndex)
        }
    }
    
    func update(_ item: TodoItem) {
        if let index = allItems.firstIndex(where: { $0.id == item.id }) {
            allItems[index] = item
        }
    }
    
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        // First, get the items being moved
        let movedItems = source.map { items[$0] }
        
        // Remove items from their original positions
        var currentAllItems = allItems
        for item in movedItems.reversed() {
            if let index = currentAllItems.firstIndex(where: { $0.id == item.id }) {
                currentAllItems.remove(at: index)
            }
        }
        
        // Find the destination index in allItems
        let destinationItem = items[destination > items.count ? items.count - 1 : max(0, destination - 1)]
        let destinationIndex = currentAllItems.firstIndex(where: { $0.id == destinationItem.id }) ?? 0
        
        // Insert all moved items at the new position
        for (offset, item) in movedItems.enumerated() {
            let insertionIndex = min(destinationIndex + offset, currentAllItems.count)
            currentAllItems.insert(item, at: insertionIndex)
        }
        
        allItems = currentAllItems
    }
    
    func recoverOldData() {
        print("All UserDefaults keys:", UserDefaults.standard.dictionaryRepresentation().keys)
        
        if let data = UserDefaults.standard.data(forKey: key) {
            print("Found data for key:", key)
            print("Data size:", data.count, "bytes")
            
            // Try to decode as raw JSON to see the structure
            if let json = try? JSONSerialization.jsonObject(with: data) {
                print("Raw JSON structure:", json)
            }
            
            // Try to decode with old format
            if let legacyItems = try? JSONDecoder().decode([LegacyTodoItem].self, from: data) {
                print("Successfully decoded legacy items:", legacyItems)
                // Convert old items to new format
                allItems = legacyItems.map { oldItem in
                    TodoItem(id: oldItem.id, text: oldItem.text, elapsedSeconds: 0)
                }
                // Save in new format
                save()
                print("Migrated and saved", allItems.count, "items")
            } else {
                print("Failed to decode as legacy items")
            }
        } else {
            print("No data found for key:", key)
        }
    }
}
