import Foundation

enum TodoAction {
    case get(id: String)
    case getAll
    case create(body: CreateTodoItemBody)
    case update(id: String, body: UpdateTodoItemBody)
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
            
            let encoder = JSONEncoder() // TODO: Use environment
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
            let encoder = JSONEncoder() // TODO: Use environment
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
            let now = Date() // TODO: Use environment
            let item = ToDoItem(
                id: UUID().uuidString,
                description: body.description,
                dueTo: body.dueTo,
                createdAt: now,
                updatedAt: now
            )
            state.todos.append(item)
            
            let encoder = JSONEncoder() // TODO: Use environment
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
            
        case let .update(id, body):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(statusCode: 404, headers: [:], body: "Todo item not found".data(using: .utf8)!)
            }
            
            let now = Date() // TODO: Use environment
            let item = state.todos.remove(at: index)
            let newItem = item.update(body: body, now: now)
            state.todos.insert(newItem, at: index)
            
            let encoder = JSONEncoder() // TODO: Use environment
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: try encoder.encode(newItem)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo item failure".data(using: .utf8)!)
            }
            
        case let .delete(id):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(statusCode: 205, headers: [:], body: "Todo item not found".data(using: .utf8)!) // TODO: Change the body
            }
            
            let item = state.todos.remove(at: index)
            let encoder = JSONEncoder() // TODO: Use environment
            encoder.dateEncodingStrategy = .millisecondsSince1970
            do {
                return .init(
                    statusCode: 204,
                    headers: [:],
                    body: try encoder.encode(item)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: "Encoding todo item failure".data(using: .utf8)!)
            }            
        }
    }
}
