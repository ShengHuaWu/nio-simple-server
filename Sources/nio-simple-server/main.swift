import Foundation
import NIO
import NIOHTTP1

#if DEBUG
  let numberOfThreads = 1
#else
  let numberOfThreads = System.coreCount
#endif

func run() {
    do {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: numberOfThreads)
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    return channel.pipeline.addHandler(Handler())
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(reuseAddrOpt, value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
        
        let host = "127.0.0.1"
        let port = 5566
        let serverChannel = try bootstrap.bind(host: host, port: port).wait()
        print("Listening on \(host):\(port)...")
        try serverChannel.closeFuture.wait()
        try eventLoopGroup.syncShutdownGracefully()
    } catch {
        fatalError(error.localizedDescription)
    }
}

run()
