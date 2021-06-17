import Foundation

public struct Middleware<State, Action, Environment> {
    let run: (inout State, Action, Environment) -> Response
}
