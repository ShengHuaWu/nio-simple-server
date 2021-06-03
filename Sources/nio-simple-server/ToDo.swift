import Foundation

final class ToDoController {
    private var items: Set<ToDoItem> = []
    
    func create() -> ToDoItem {
        fatalError()
    }
    
    func read(by id: UUID) -> ToDoItem? {
        fatalError()
    }
    
    func update() -> ToDoItem? {
        fatalError()
    }
    
    func delete(by id: UUID) {
        fatalError()
    }
}
