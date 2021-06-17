import Foundation

// TODO: Combine Router & Middleware ???
public struct Router<Action> {
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
