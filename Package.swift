// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MetalBuilder",
    platforms: [.macOS(.v11), .iOS(.v17), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13), .visionOS(.v2)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MetalBuilder",
            targets: ["MetalBuilder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        //.package(path: "MetalBuilderMacros"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-syntax", from: "510.0.0"),
    ],
    targets: [
        .macro(
            name: "MetalBuilderMacros",
            dependencies: [
                //.product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
                ),
        
        .target(
            name: "MetalBuilder",
            dependencies: [.product(name: "OrderedCollections", package: "swift-collections"),
                           "MetalBuilderMacros",
                          ]),
        
        
        
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
