// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WebModule", targets: ["WebModule"])
    ],
    dependencies: [
        .package(path: "../../Core/StorageModule")
    ],
    targets: [
        .target(
            name: "WebModule",
            dependencies: ["StorageModule"],
            path: "Sources/WebModule"
        )
    ]
)
