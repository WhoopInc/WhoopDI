// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhoopDIKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(name: "WhoopDIKit", targets: ["WhoopDIKit"]),
        .library(name: "WhoopDIKitStatic", type:.static, targets: ["WhoopDIKit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WhoopDIKit",
            dependencies: []),
        .testTarget(
            name: "WhoopDIKitTests",
            dependencies: ["WhoopDIKit"])
    ]
)
