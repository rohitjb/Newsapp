// Packages/Features/SavedModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SavedModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SavedModule", targets: ["SavedModule"])
    ],
    dependencies: [
        .package(path: "../../Core/StorageModule")
    ],
    targets: [
        .target(
            name: "SavedModule",
            dependencies: ["StorageModule"],
            path: "Sources/SavedModule"
        )
    ]
)
