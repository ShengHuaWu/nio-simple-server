import Foundation

struct Response {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}

struct Middleware<Action> {
    let run: (Action) -> Response
}

// TODO: Implement state
extension Middleware where Action == TodoAction {
    static let todos = Middleware { action in
        switch action {
        case let .get(id):
            let item = ToDoItem(
                id: id,
                description: "This is a fake one",
                dueTo: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {
                let body = try encoder.encode(item)
                
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: body
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo item failure".data(using: .utf8)!)
            }
            
        case .getAll:
            let item = ToDoItem(
                id: "XYZ",
                description: "This is a fake one",
                dueTo: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {
                let body = try encoder.encode([item])
                
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: body
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo items failure".data(using: .utf8)!)
            }
            
        case .create:
            return .init(statusCode: 201, headers: [:], body: "Created".data(using: .utf8)!)
            
        case .update:
            return .init(statusCode: 200, headers: [:], body: "Updated".data(using: .utf8)!)
            
        case .delete(id: let id):
            return .init(statusCode: 205, headers: [:], body: "Deleted".data(using: .utf8)!)
        }
    }
}
