import Foundation
import NIO
import NIOHTTP1

final class Handler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    private var request: URLRequest?
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case let .head(header):
            request = makeRequest(with: header)
            
        case var .body(bodyPart):
            var body = request?.httpBody ?? Data()
            bodyPart.readBytes(length: bodyPart.readableBytes).map { body.append(Data($0)) }
            request?.httpBody = body
            
        case .end:
            guard let request = self.request else {
                let head = HTTPResponseHead(
                    version: .init(major: 1, minor: 1),
                    status: .init(statusCode: 200),
                    headers: .init([("location", "127.0.0.1:5567")]) // TODO: Pass base url from outside
                )
                context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
                _ = context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap {
                  context.channel.close()
                }
                return
            }
            
            do {
                let action = try route(request)
                let head = HTTPResponseHead(
                    version: .init(major: 1, minor: 1),
                    status: .init(statusCode: 200),
                    headers: .init([("location", "127.0.0.1:5567")]) // TODO: Pass base url from outside
                )
                context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
                
                let buffer = ByteBuffer(string: "\(action)")
                context.channel.write(HTTPServerResponsePart.body(.byteBuffer(buffer)), promise: nil)
                
                _ = context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap {
                  context.channel.close()
                }
            } catch let error as RouteError {
                switch error {
                case .notFound:
                    let head = HTTPResponseHead(
                        version: .init(major: 1, minor: 1),
                        status: .init(statusCode: 403),
                        headers: .init([("location", "127.0.0.1:5567")]) // TODO: Pass base url from outside
                    )
                    context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
                case .missingParameter:
                    let head = HTTPResponseHead(
                        version: .init(major: 1, minor: 1),
                        status: .init(statusCode: 400),
                        headers: .init([("location", "127.0.0.1:5567")]) // TODO: Pass base url from outside
                    )
                    context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
                }
                
                _ = context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap {
                  context.channel.close()
                }
            } catch {
                let head = HTTPResponseHead(
                    version: .init(major: 1, minor: 1),
                    status: .init(statusCode: 500),
                    headers: .init([("location", "127.0.0.1:5567")]) // TODO: Pass base url from outside
                )
                context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
                _ = context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap {
                  context.channel.close()
                }
            }
        }
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }
}

// MARK: - Private
private func method(from method: HTTPMethod) -> String {
  switch method {
  case .GET: return "GET"
  case .PUT: return "PUT"
  case .ACL: return "ACL"
  case .HEAD: return "HEAD"
  case .POST: return "POST"
  case .COPY: return "COPY"
  case .LOCK: return "LOCK"
  case .MOVE: return "MOVE"
  case .BIND: return "BIND"
  case .LINK: return "LINK"
  case .PATCH: return "PATCH"
  case .TRACE: return "TRACE"
  case .MKCOL: return "MKCOL"
  case .MERGE: return "MERGE"
  case .PURGE: return "PURGE"
  case .NOTIFY: return "NOTIFY"
  case .SEARCH: return "SEARCH"
  case .UNLOCK: return "UNLOCK"
  case .REBIND: return "REBIND"
  case .UNBIND: return "UNBIND"
  case .REPORT: return "REPORT"
  case .DELETE: return "DELETE"
  case .UNLINK: return "UNLINK"
  case .CONNECT: return "CONNECT"
  case .MSEARCH: return "MSEARCH"
  case .OPTIONS: return "OPTIONS"
  case .PROPFIND: return "PROPFIND"
  case .CHECKOUT: return "CHECKOUT"
  case .PROPPATCH: return "PROPPATCH"
  case .SUBSCRIBE: return "SUBSCRIBE"
  case .MKCALENDAR: return "MKCALENDAR"
  case .MKACTIVITY: return "MKACTIVITY"
  case .UNSUBSCRIBE: return "UNSUBSCRIBE"
  case .SOURCE: return "SOURCE"
  case let .RAW(value): return value
  }
}

private func makeRequest(with header: HTTPRequestHead) -> URLRequest? {
    URL(string: header.uri).map { url in
        var req = URLRequest(url: url)
        req.httpMethod = method(from: header.method)
        req.allHTTPHeaderFields = header.headers.reduce(into: [:]) { $0[$1.name] = $1.value }
        let proto = req.value(forHTTPHeaderField: "X-Forwarded-Proto") ?? "http"
        req.url = req.value(forHTTPHeaderField: "Host").flatMap {
          URL(string: proto + "://" + $0 + header.uri)
        }
        
        return req
    }
}

// Sheng: Move to another file
enum Action {
    case getToDo(id: String)
    case getAllToDos
    case createToDo
    case updateToDo
    case deleteToDo(id: String)
}

enum RouteError: Error {
    case notFound
    case missingParameter
}

private func route(_ request: URLRequest) throws -> Action {
    guard let url = request.url, let components = URLComponents(string: url.absoluteString) else {
        throw RouteError.notFound
    }
    
    let pathComponents = components.path.split(separator: "/").map(String.init)
    guard pathComponents.contains("todos") else {
        throw RouteError.notFound
    }
    
    let method = request.httpMethod.map(HTTPMethod.init(rawValue:)) ?? .GET
    switch method {
    case .GET:
        if let indexOfTodos = pathComponents.firstIndex(of: "todos"),
           let indexOfId = pathComponents.index(indexOfTodos, offsetBy: 1, limitedBy: pathComponents.endIndex - 1) {
            return .getToDo(id: pathComponents[indexOfId])
        } else {
            return .getAllToDos
        }
        
    case .POST:
        return .createToDo
        
    case .PUT:
        return .updateToDo
        
    case .DELETE:
        guard let indexOfTodos = pathComponents.firstIndex(of: "todos"),
              let indexOfId = pathComponents.index(indexOfTodos, offsetBy: 1, limitedBy: pathComponents.endIndex) else {
            throw RouteError.missingParameter
        }
        
        return .deleteToDo(id: pathComponents[indexOfId])
        
    default:
        throw RouteError.notFound
    }
}
