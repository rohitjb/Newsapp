// Packages/Core/FeatureFlagModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureFlagModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FeatureFlagModule", targets: ["FeatureFlagModule"])
    ],
    targets: [
        .target(
            name: "FeatureFlagModule",
            path: "Sources/FeatureFlagModule"
        )
    ]
)
