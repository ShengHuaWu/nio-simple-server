import Foundation

struct APIError: Encodable, Error {
    let errorDump: String
    let message: String
    
    init(error: Error) {
        var string = ""
        dump(error, to: &string)
        self.errorDump = string
        self.message = error.localizedDescription
    }
}
