// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhoopDI",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "WhoopDI",
            targets: ["WhoopDI"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WhoopDI",
            dependencies: []),
        .testTarget(
            name: "WhoopDITests",
            dependencies: ["WhoopDI"])
    ]
)
