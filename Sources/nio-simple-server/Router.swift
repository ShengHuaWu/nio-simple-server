import Foundation
import NIOHTTP1

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
            guard let httpBody = request.httpBody else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
                        
            do {
                return .create(body: try decoder.decode(CreateTodoItemBody.self, from: httpBody))
            } catch {
                return nil
            }
            
        case .PUT:
            guard let httpBody = request.httpBody else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            
            do {
                return .update(body: try decoder.decode(UpdateTodoItemBody.self, from: httpBody))
            } catch {
                return nil
            }
            
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
