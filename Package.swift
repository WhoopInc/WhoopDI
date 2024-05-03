// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "WhoopDIKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "WhoopDIKit",
            type: .static,
            targets: ["WhoopDIKit", "WhoopDIKitMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .target(
            name: "WhoopDIKit",
            dependencies: ["WhoopDIKitMacros"]),
        .testTarget(
            name: "WhoopDIKitTests",
            dependencies: [
                "WhoopDIKit",
                "WhoopDIKitMacros",
               .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")]),
        .macro(name: "WhoopDIKitMacros",
               dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
               ])
    ]
)
