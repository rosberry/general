// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "General",
    dependencies: [
        .package(url: "https://github.com/stencilproject/Stencil.git", .upToNextMajor(from: "0.0.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "0.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "General",
            dependencies: [
                "Stencil",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Yams",
        ]),
        .testTarget(
            name: "GeneralTests",
            dependencies: ["General"]),
    ]
)
