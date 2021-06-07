import Foundation
import NIOHTTP1

enum Action {
    case getToDo(id: String)
    case getAllToDos
    case createToDo // TODO: Missing body
    case updateToDo // TODO: Missing body
    case deleteToDo(id: String)
}

struct Router {
    let route: (URLRequest) -> Action?
}

extension Router {
    func combine(_ routers: [Router]) -> Router {
        .init { request in
            for router in routers {
                if let action = router.route(request) {
                    return action
                }
            }
            
            return nil
        }
    }
    
    func combine(_ routers: Router...) -> Router {
        combine(routers)
    }
}

extension Router {
    static let todos = Router { request in
        guard let url = request.url, let components = URLComponents(string: url.absoluteString) else {
            return nil
        }
        
        // TODO: Parsers seem reasonable here
        let pathComponents = components.path.split(separator: "/").map(String.init)
        guard pathComponents.contains("todos") else {
            return nil
        }
        
        let method = request.httpMethod.map(HTTPMethod.init(rawValue:)) ?? .GET
        switch method {
        case .GET:
            if let indexOfTodos = pathComponents.firstIndex(of: "todos"),
               let indexOfId = pathComponents.index(indexOfTodos, offsetBy: 1, limitedBy: pathComponents.endIndex - 1) {
                return .getToDo(id: pathComponents[indexOfId])
            } else {
                return .getAllToDos
            }
            
        case .POST:
            return .createToDo
            
        case .PUT:
            return .updateToDo
            
        case .DELETE:
            guard let indexOfTodos = pathComponents.firstIndex(of: "todos"),
                  let indexOfId = pathComponents.index(indexOfTodos, offsetBy: 1, limitedBy: pathComponents.endIndex) else {
                return nil
            }
            
            return .deleteToDo(id: pathComponents[indexOfId])
            
        default:
            return nil
        }
    }
}
