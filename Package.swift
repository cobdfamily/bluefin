// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "BlueFin",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "BlueFin",
            targets: ["BllueFin"]
        ),
        .library(
            name: "Module",
            type: .dynamic,
            targets: ["BlueFin"]
        )
    ],
    dependencies: [
        .package(path: "node_modules/node-swift")
    ],
    targets: [
        .target(
            name: "BlueFin",
            dependencies: [
                .product(name: "NodeAPI", package: "node-swift"),
                .product(name: "NodeModuleSupport", package: "node-swift"),
            ]
        )
    ]
)