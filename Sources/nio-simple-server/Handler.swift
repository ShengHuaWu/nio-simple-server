import NIO
import NIOHTTP1

final class Handler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case let .head(header):
            print("Header:\n")
            print(header)
            
        case let .body(bodyPart):
            print("Body:\n")
            print(bodyPart)
            
        case .end:
            print("End:\n")
            let head = HTTPResponseHead(
                version: .init(major: 1, minor: 1),
                status: .init(statusCode: 200),
                headers: .init([("location", "127.0.0.1:5566")])
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
