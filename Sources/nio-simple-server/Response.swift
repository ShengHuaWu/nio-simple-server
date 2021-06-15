import Foundation

struct Response {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}
