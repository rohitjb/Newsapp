// Packages/Features/SourceModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SourceModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SourceModule", targets: ["SourceModule"])
    ],
    dependencies: [
        .package(path: "../../Core/NetworkModule")
    ],
    targets: [
        .target(
            name: "SourceModule",
            dependencies: ["NetworkModule"],
            path: "Sources/SourceModule"
        )
    ]
)
