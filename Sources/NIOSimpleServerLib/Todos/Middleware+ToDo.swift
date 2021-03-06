import Foundation

struct ToDoState {
    var todos: [ToDoItem] = []
}
public enum ToDoAction {
    case get(id: String)
    case getAll
    case create(body: CreateTodoItemBody)
    case update(id: String, body: UpdateTodoItemBody)
    case delete(id: String)
}
struct ToDoEnvironment {
    var jsonEncoder: () -> JSONEncoder
    var uuid: () -> UUID
    var now: () -> Date
}

/*
 TODO: Handle response in a unified structure, e.g.
 {
     "data": { ... }
 }
 */
extension Middleware where State == ToDoState, Action == ToDoAction, Environment == ToDoEnvironment {
    static let todos = Middleware { state, action, environment in
        switch action {
        case let .get(id):
            guard let item = state.todos.first(where: { $0.id == id }) else {
                return .init(statusCode: 404, apiError: .init(error: TodoNotFound()))
            }
            
            return .init(statusCode: 200, encoder: environment.jsonEncoder(), encodable: item)
            
        case .getAll:
            return .init(statusCode: 200, encoder: environment.jsonEncoder(), encodable: state.todos)
            
        case let .create(body):
            let now = environment.now()
            let item = ToDoItem(
                id: environment.uuid().uuidString,
                description: body.description,
                dueTo: body.dueTo,
                createdAt: now,
                updatedAt: now
            )
            state.todos.append(item)
            
            return .init(statusCode: 201, encoder: environment.jsonEncoder(), encodable: item)
            
        case let .update(id, body):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(statusCode: 404, apiError: .init(error: TodoNotFound()))
            }
            
            let now = environment.now()
            let item = state.todos.remove(at: index)
            let newItem = item.update(body: body, now: now)
            state.todos.insert(newItem, at: index)
            
            return .init(statusCode: 200, encoder: environment.jsonEncoder(), encodable: newItem)
            
        case let .delete(id):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(statusCode: 404, apiError: .init(error: TodoNotFound()))
            }
            
            let item = state.todos.remove(at: index)
            
            return .init(statusCode: 204, encoder: environment.jsonEncoder(), encodable: item)
        }
    }
}

// MARK: - Private
private struct TodoNotFound: Error {}
