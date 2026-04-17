// Packages/Core/StorageModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StorageModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "StorageModule", targets: ["StorageModule"])
    ],
    targets: [
        .target(
            name: "StorageModule",
            path: "Sources/StorageModule"
        )
    ]
)
