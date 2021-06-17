import Foundation

struct Response {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}

// TODO: Construct proper headers
extension Response {
    init(statusCode: Int, apiError: APIError) {
        self.headers = [:]
        
        do {
            self.body = try JSONEncoder().encode(apiError)
            self.statusCode = statusCode
        } catch let error {
            assertionFailure("Encoding api error fails while creating response, the api error is \n \(apiError.localizedDescription) ")
            self.body = error.localizedDescription.data(using: .utf8) ?? Data()
            self.statusCode = 500
        }
    }
    
    init<T: Encodable>(statusCode: Int, encoder: JSONEncoder, encodable: T) {
        self.headers = [:]
        
        do {
            self.body = try encoder.encode(encodable)
            self.statusCode = statusCode
        } catch {
            assertionFailure("Encoding body fails while creating response, the body is \n \(encodable) ")
            self.body = error.localizedDescription.data(using: .utf8) ?? Data()
            self.statusCode = 500
        }
    }
}
