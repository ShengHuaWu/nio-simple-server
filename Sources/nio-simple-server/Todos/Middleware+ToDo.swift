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

struct ToDoEnvironment {
    var jsonEncoder: () -> JSONEncoder
    var now: () -> Date
}

/*
 TODO: Handle response in a unified structure, e.g.
 {
     "data": { ... }
 }
 */
extension Middleware where State == ToDoState, Action == TodoAction, Environment == ToDoEnvironment {
    private struct TodoNotFound: Error {}
    
    static let todos = Middleware { state, action, environment in
        switch action {
        case let .get(id):
            guard let item = state.todos.first(where: { $0.id == id }) else {
                return .init(statusCode: 404, apiError: .init(error: TodoNotFound()))
            }
            
            return .init(statusCode: 200, encodable: item)
            
        case .getAll:
            return .init(statusCode: 200, encodable: state.todos)
            
        case let .create(body):
            let now = environment.now()
            let item = ToDoItem(
                id: UUID().uuidString,
                description: body.description,
                dueTo: body.dueTo,
                createdAt: now,
                updatedAt: now
            )
            state.todos.append(item)
            
            return .init(statusCode: 201, encodable: item)
            
        case let .update(id, body):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(statusCode: 404, apiError: .init(error: TodoNotFound()))
            }
            
            let now = environment.now()
            let item = state.todos.remove(at: index)
            let newItem = item.update(body: body, now: now)
            state.todos.insert(newItem, at: index)
            
            return .init(statusCode: 200, encodable: newItem)
            
        case let .delete(id):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(statusCode: 404, apiError: .init(error: TodoNotFound()))
            }
            
            let item = state.todos.remove(at: index)
            
            return .init(statusCode: 204, encodable: item)
        }
    }
}
