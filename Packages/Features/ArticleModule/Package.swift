// Packages/Features/ArticleModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArticleModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ArticleModule", targets: ["ArticleModule"])
    ],
    dependencies: [
        .package(path: "../../Core/NetworkModule"),
        .package(path: "../../Core/StorageModule")
    ],
    targets: [
        .target(
            name: "ArticleModule",
            dependencies: ["NetworkModule", "StorageModule"],
            path: "Sources/ArticleModule"
        )
    ]
)
