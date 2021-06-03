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
            request = URL(string: header.uri).map { URLRequest(url: $0) }
            request?.httpMethod = method(from: header.method)
            print(request ?? "Unable to construct a request")
            
        case let .body(bodyPart):
            print("Body:\n")
            print(bodyPart)
            
        case .end:
            // TODO: dispatch different requests
            print("End:\n")
            let head = HTTPResponseHead(
                version: .init(major: 1, minor: 1),
                status: .init(statusCode: 200),
                headers: .init([("location", "127.0.0.1:5566")]) // TODO: Pass base url from outside
            )
            context.channel.write(HTTPServerResponsePart.head(head), promise: nil)
            
            let buffer = ByteBuffer(string: "Hello World!!!")
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
