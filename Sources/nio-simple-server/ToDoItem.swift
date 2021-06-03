import Foundation

struct ToDoItem: Hashable {
    let id: UUID
    let description: String
    let dueTo: Date
    let createdAt: Date
    let updatedAt: Date
}
