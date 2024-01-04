// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MetalBuilder",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MetalBuilder",
            targets: ["MetalBuilder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "MetalBuilderMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
                ),
        
        .target(
            name: "MetalBuilder",
            dependencies: [.product(name: "OrderedCollections", package: "swift-collections")]),
        .testTarget(
            name: "MetalBuilderTests",
            dependencies: ["MetalBuilder"]),
        .testTarget(
                    name: "MetalBuilderMacrosTests",
                    dependencies: [
                        "MetalBuilderMacros",
                        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                    ]
                ),
    ]
)
