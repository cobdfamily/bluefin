// swift-tools-version: 5.9
//
// bluefin-swift -- experimental Tuna accessibility
// server for macOS. Binds AX (ApplicationServices)
// to the Bluefin protocol (JSON-RPC over WebSocket).
//
// Intentionally zero third-party Swift dependencies:
// Network.framework provides WebSocket, Foundation
// provides Codable, ApplicationServices provides AX.

import PackageDescription

let package = Package(
    name: "bluefin-swift",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "bluefin-server",
                    targets: ["BluefinServer"]),
        .library(name: "BluefinCore",
                 targets: ["BluefinCore"]),
    ],
    dependencies: [],
    targets: [
        // BluefinCore: protocol types + normalisation
        // tables + AX bindings + cache. Library so
        // tests can link against the same code.
        .target(
            name: "BluefinCore",
            path: "Sources/BluefinCore"
        ),
        // BluefinServer: the executable. Wires
        // BluefinCore up to Network.framework's
        // WebSocket implementation.
        .executableTarget(
            name: "BluefinServer",
            dependencies: ["BluefinCore"],
            path: "Sources/BluefinServer"
        ),
        .testTarget(
            name: "BluefinCoreTests",
            dependencies: ["BluefinCore"],
            path: "Tests/BluefinCoreTests"
        ),
    ]
)
