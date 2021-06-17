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

public struct CreateTodoItemBody: Decodable {
    private enum CodingKeys: String, CodingKey {
        case description
        case dueTo = "due_to"
    }
    
    let description: String
    let dueTo: Date
}

public struct UpdateTodoItemBody: Decodable {
    private enum CodingKeys: String, CodingKey {
        case description
        case dueTo = "due_to"
    }
    
    let description: String?
    let dueTo: Date?
}

extension ToDoItem {
    func update(body: UpdateTodoItemBody, now: Date) -> Self {
        ToDoItem(
            id: id,
            description: body.description ?? description,
            dueTo: body.dueTo ?? dueTo,
            createdAt: createdAt,
            updatedAt: now
        )
    }
}
