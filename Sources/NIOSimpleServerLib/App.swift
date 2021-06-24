import Foundation

public struct AppState {
    var todo: ToDoState
}
public enum AppAction {
    case todo(ToDoAction)
}
public struct AppEnvironment {
    var jsonEncoder: () -> JSONEncoder
    var uuid: () -> UUID
    var now: () -> Date
}

extension AppAction {
    var todo: ToDoAction? {
        guard case let .todo(todoAction) = self else {
            return nil
        }
        
        return todoAction
    }
}


extension AppEnvironment {
    var todo: ToDoEnvironment {
        .init(
            jsonEncoder: jsonEncoder,
            uuid: uuid,
            now: now
        )
    }
}

extension AppEnvironment {
    static let live = Self.init(
        jsonEncoder: {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            
            return encoder
        },
        uuid: UUID.init,
        now: Date.init
        )
}

public let appMiddleware: Middleware<AppState, AppAction, AppEnvironment> = Middleware.todos.pullback(
    state: \.todo,
    action: \.todo,
    environment: \.todo
)
