// swift-tools-version:5.2

//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "General",
    platforms: [.macOS(.v10_12)],
    dependencies: [
        //with bumped PathKit version
        .package(url: "https://github.com/rosberry/StencilSwiftKit.git", .branch("stable")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "0.0.0")),
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "GeneralKit",
            dependencies: [
                "StencilSwiftKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Yams",
                "XcodeProj",
                "ZIPFoundation"
        ]),
        .testTarget(
            name: "GeneralTests",
            dependencies: ["General"])
    ]
)
