import Foundation
import XCTest
@testable import NIOSimpleServerLib

final class MiddlewareToDosTests: XCTestCase {
    private var state: ToDoState!
    
    override func setUp() {
        super.setUp()
        
        state = .init()
    }
    
    func testCreateToDoSucceeds() {
        var environment = ToDoEnvironment.unimplemented
        environment.jsonEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            
            return encoder
        }
        
        environment.now = {
            Date(timeIntervalSince1970: 645606000)
        }
        
        let body = CreateTodoItemBody(description: "Blob", dueTo: environment.now())
        
        let response = Middleware.todos.run(&state, .create(body: body), environment)
        
        XCTAssertEqual(response.statusCode, 201)
        XCTAssertEqual(response.headers, [:])
        XCTAssertEqual(state.todos.count, 1)
        
        let item = state.todos[0]
        
        XCTAssertEqual(response.body, try? environment.jsonEncoder().encode(item))
        XCTAssertEqual(item.description, body.description)
        XCTAssertEqual(item.dueTo, body.dueTo)
        XCTAssertEqual(item.createdAt, environment.now())
        XCTAssertEqual(item.updatedAt, environment.now())
    }
}

// MARK: - Private
private extension ToDoEnvironment {
    static let unimplemented = Self(
        jsonEncoder: {
            XCTFail("JSON encoder is unimplemented yet.")
            return JSONEncoder()
        },
        now: {
            XCTFail("Now is unimplemented yet.")
            return Date()
        })
}
