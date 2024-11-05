// swift-tools-version: 5.10
// Package.swift
import PackageDescription

let package = Package(
    name: "smux",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.0"))
    ],
    targets: [
        .executableTarget(
            name: "smux",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/smux")
    ]
)