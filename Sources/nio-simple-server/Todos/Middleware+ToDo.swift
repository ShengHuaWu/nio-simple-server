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

enum ToDoError: Error {
    case itemNotFound
    case encodingFailure
}

// TODO: Handle response headers properly
extension Middleware where State == ToDoState, Action == TodoAction, Environment == ToDoEnvironment {
    static let todos = Middleware { state, action, environment in
        switch action {
        case let .get(id):
            guard let item = state.todos.first(where: { $0.id == id }) else {
                return .init(
                    statusCode: 404,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.itemNotFound)) // TODO: Consider throwing from middleware
                )
            }
            
            do {
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: try environment.jsonEncoder().encode(item)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.encodingFailure)) // TODO: Consider throwing from middleware
                )
            }
            
        case .getAll:
            do {
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: try environment.jsonEncoder().encode(state.todos)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.encodingFailure)) // TODO: Consider throwing from middleware
                )
            }
            
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
            
            do {
                return .init(
                    statusCode: 201,
                    headers: [:],
                    body: try environment.jsonEncoder().encode(item)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.encodingFailure)) // TODO: Consider throwing from middleware
                )
            }
            
        case let .update(id, body):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(
                    statusCode: 404,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.itemNotFound)) // TODO: Consider throwing from middleware
                )
            }
            
            let now = environment.now()
            let item = state.todos.remove(at: index)
            let newItem = item.update(body: body, now: now)
            state.todos.insert(newItem, at: index)
            
            do {
                return .init(
                    statusCode: 200,
                    headers: [:],
                    body: try environment.jsonEncoder().encode(newItem)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.encodingFailure)) // TODO: Consider throwing from middleware
                )
            }
            
        case let .delete(id):
            guard let index = state.todos.firstIndex(where: { $0.id == id }) else {
                return .init(
                    statusCode: 205,
                    headers: [:],
                    body: "The item is not found".data(using: .utf8)! // TODO: Should return a JSON structure
                )
            }
            
            let item = state.todos.remove(at: index)
            do {
                return .init(
                    statusCode: 204,
                    headers: [:],
                    body: try environment.jsonEncoder().encode(item)
                )
            } catch {
                return .init(
                    statusCode: 500,
                    headers: [:],
                    body: try! environment.jsonEncoder().encode(APIError(error: ToDoError.encodingFailure)) // TODO: Consider throwing from middleware
                )
            }
        }
    }
}
