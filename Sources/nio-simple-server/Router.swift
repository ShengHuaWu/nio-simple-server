import Foundation
import NIOHTTP1

enum TodoAction {
    case get(id: String)
    case getAll
    case create // TODO: Missing body
    case update // TODO: Missing body
    case delete(id: String)
}

struct Router<Action> {
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

extension Router where Action == TodoAction {
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
                return .get(id: pathComponents[indexOfId])
            } else {
                return .getAll
            }
            
        case .POST:
            return .create
            
        case .PUT:
            return .update
            
        case .DELETE:
            guard let indexOfTodos = pathComponents.firstIndex(of: "todos"),
                  let indexOfId = pathComponents.index(indexOfTodos, offsetBy: 1, limitedBy: pathComponents.endIndex) else {
                return nil
            }
            
            return .delete(id: pathComponents[indexOfId])
            
        default:
            return nil
        }
    }
}
