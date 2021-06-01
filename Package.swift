// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "nio-simple-server",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "nio-simple-server",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ]),
        .testTarget(
            name: "nio-simple-serverTests",
            dependencies: [
                "nio-simple-server"
            ]),
    ]
)
