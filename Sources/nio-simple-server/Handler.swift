import Foundation
import NIO
import NIOHTTP1

private var todoState = ToDoState() // TODO: This should be stored into DB

final class Handler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    private let baseURL: URL
    private let port: Int
    private let router: Router<TodoAction>
    private let middleware: Middleware<ToDoState, TodoAction, ToDoEnvironment>
    private var request: URLRequest?
    
    init(
        baseURL: URL,
        port: Int,
        router: Router<TodoAction>,
        middleware: Middleware<ToDoState, TodoAction, ToDoEnvironment>
    ) {
        self.baseURL = baseURL
        self.port = port
        self.router = router
        self.middleware = middleware
    }
    
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
            guard let request = self.request,
                  let action = self.router.route(request) else {
                let head = HTTPResponseHead(
                    version: .init(major: 1, minor: 1),
                    status: .init(statusCode: 200), // TODO: Should return proper status code or even an error
                    headers: .init([("location", "\(baseURL.absoluteString):\(port)")])
                )
                context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
                _ = context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap {
                  context.channel.close()
                }
                return
            }
            
            let response = self.middleware.run(&todoState, action, .live)
            let head = HTTPResponseHead(
                version: .init(major: 1, minor: 1),
                status: .init(statusCode: response.statusCode),
                headers: .init(response.headers.map { ($0.key, $0.value) })
            )
            context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
            
            var buffer = context.channel.allocator.buffer(capacity: response.body.count)
            buffer.writeBytes(response.body)
            context.channel.write(HTTPServerResponsePart.body(.byteBuffer(buffer)), promise: nil)
            
            _ = context.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).flatMap {
              context.channel.close()
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

private extension ToDoEnvironment {
    static let live = Self.init(
        jsonEncoder: {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            
            return encoder
        },
        now: Date.init
        )
}
