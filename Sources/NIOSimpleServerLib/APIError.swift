import Foundation

struct APIError: Codable, Error {
    let errorDump: String
    let message: String
    
    init(error: Error) {
        var string = ""
        dump(error, to: &string)
        self.errorDump = string
        self.message = error.localizedDescription
    }
}
