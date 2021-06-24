import Foundation

public struct Middleware<State, Action, Environment> {
    let run: (inout State, Action, Environment) -> Response
}

extension Middleware {
    func pullback<GlobalState, GlobalAction, GlobalEnvironment>(
        state: WritableKeyPath<GlobalState, State>,
        action: @escaping (GlobalAction) -> Action?,
        environment: @escaping (GlobalEnvironment) -> Environment
    ) -> Middleware<GlobalState, GlobalAction, GlobalEnvironment> {
        .init { globalState, globalAction, globalEnvironment in
            guard let localAction = action(globalAction) else {
                return .init(statusCode: 404, apiError: .init(error: NotFound()))
            }
            
            var localState = globalState[keyPath: state]
            let localEnvironment = environment(globalEnvironment)
            let response = self.run(&localState, localAction, localEnvironment)
            globalState[keyPath: state] = localState
            
            return response
        }
    }
}

private struct NotFound: Error {}
