import Foundation

enum TodoAction {
    case get(id: String)
    case getAll
    case create(body: CreateTodoItemBody)
    case update(body: UpdateTodoItemBody)
    case delete(id: String)
}

struct ToDoState {
    var todos: [ToDoItem] = []
}

struct Response {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}

struct Middleware<State, Action> {
    let run: (inout State, Action) -> Response
}

// TODO: Implement state
extension Middleware where State == ToDoState, Action == TodoAction {
    static let todos = Middleware { state, action in
        switch action {
        case let .get(id):
            guard let item = state.todos.first(where: { $0.id == id }) else {
                return .init(statusCode: 404, headers: [:], body: "Todo item not found".data(using: .utf8)!)
            }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {                
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: try encoder.encode(item)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo item failure".data(using: .utf8)!)
            }
            
        case .getAll:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: try encoder.encode(state.todos)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo items failure".data(using: .utf8)!)
            }
            
        case let .create(body):
            let now = Date()
            let item = ToDoItem(
                id: UUID().uuidString,
                description: body.description,
                dueTo: body.dueTo,
                createdAt: now,
                updatedAt: now
            )
            state.todos.append(item)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {
                return .init(
                    statusCode: 201,
                    headers: [:],
                    body: try encoder.encode(item)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo item failure".data(using: .utf8)!)
            }
            
        case .update:
            return .init(statusCode: 200, headers: [:], body: "Updated".data(using: .utf8)!)
            
        case .delete(id: let id):
            return .init(statusCode: 205, headers: [:], body: "Deleted".data(using: .utf8)!)
        }
    }
}
