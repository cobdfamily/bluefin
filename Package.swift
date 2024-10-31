// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Taylor",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "Taylor",
            targets: ["Taylor"]
        ),
        .library(
            name: "Module",
            type: .dynamic,
            targets: ["Taylor"]
        )
    ],
    dependencies: [
        .package(path: "node_modules/node-swift")
    ],
    targets: [
        .target(
            name: "Taylor",
            dependencies: [
                .product(name: "NodeAPI", package: "node-swift"),
                .product(name: "NodeModuleSupport", package: "node-swift"),
            ]
        )
    ]
)
