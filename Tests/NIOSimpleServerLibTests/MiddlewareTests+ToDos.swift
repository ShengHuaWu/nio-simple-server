import Foundation
import XCTest
@testable import NIOSimpleServerLib

final class MiddlewareToDosTests: XCTestCase {
    private var state: ToDoState!
    private var environment: ToDoEnvironment!
    
    override func setUp() {
        super.setUp()
        
        state = .init()
        environment = .unimplemented
    }
    
    func testCreationSucceeds() {
        environment.jsonEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            
            return encoder
        }
        
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        environment.uuid = { id }
        
        environment.now = {
            Date(timeIntervalSince1970: 645606000)
        }
        
        let body = CreateTodoItemBody(description: "Blob", dueTo: environment.now())
        
        let response = Middleware.todos.run(&state, .create(body: body), environment)
        
        XCTAssertEqual(response.statusCode, 201)
        XCTAssertTrue(response.headers.isEmpty)
        XCTAssertEqual(state.todos.count, 1)
        
        let item = state.todos[0]
        
        XCTAssertEqual(response.body, try? environment.jsonEncoder().encode(item))
        XCTAssertEqual(item.id, id.uuidString)
        XCTAssertEqual(item.description, body.description)
        XCTAssertEqual(item.dueTo, body.dueTo)
        XCTAssertEqual(item.createdAt, environment.now())
        XCTAssertEqual(item.updatedAt, environment.now())
    }
    
    func testGetOneByIdSucceeds() {
        environment.jsonEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            
            return encoder
        }
        
        let item = ToDoItem(
            id: "XYZ",
            description: "This is a placeholder",
            dueTo: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        state.todos = [item]
        
        let response = Middleware.todos.run(&state, .get(id: item.id), environment)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.headers.isEmpty)
        XCTAssertEqual(response.body, try? environment.jsonEncoder().encode(item))
    }
    
    
    func testGetOneByIdFailsWhenItemNotFound() throws {
        let response = Middleware.todos.run(&state, .get(id: "Blob"), environment)
        
        XCTAssertEqual(response.statusCode, 404)
        XCTAssertTrue(response.headers.isEmpty)
        
        let apiError = try JSONDecoder().decode(APIError.self, from: response.body)
        // TODO: Assert `response.body` with the private error
        XCTAssertFalse(apiError.message.isEmpty)
        XCTAssertFalse(apiError.errorDump.isEmpty)
    }
}

// MARK: - Private
private extension ToDoEnvironment {
    static let unimplemented = Self(
        jsonEncoder: {
            XCTFail("JSON encoder is unimplemented yet.")
            return JSONEncoder()
        },
        uuid: {
            XCTFail("UUID is unimplemented yet.")
            return UUID()
        },
        now: {
            XCTFail("Now is unimplemented yet.")
            return Date()
        })
}
