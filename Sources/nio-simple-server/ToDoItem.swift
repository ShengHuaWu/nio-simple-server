import Foundation

struct ToDoItem: Hashable, Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case description
        case dueTo = "due_to"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    let id: String
    let description: String
    let dueTo: Date
    let createdAt: Date
    let updatedAt: Date
}
