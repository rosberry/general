// swift-tools-version:5.2

//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "General",
    platforms: [.macOS(.v10_13)],
    products: [
        .executable(name: "General", targets: ["General"]),
        .executable(name: "GeneralIOs", targets: ["GeneralIOs"]),
        .library(name: "GeneralKit", type: .static, targets: ["GeneralKit"])
    ],
    dependencies: [
        //with bumped PathKit version
        .package(url: "https://github.com/rosberry/StencilSwiftKit.git", .branch("stable")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "4.0.6")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/rosberry/umaler.git", .branch("architecture-parser")),
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
                "ZIPFoundation"
        ]),
        .target(
            name: "General",
            dependencies: [
                .target(name: "GeneralKit")
        ]),
        .target(
            name: "GeneralIOs",
            dependencies: [
                .target(name: "GeneralKit"),
                .product(name: "UmalerKit", package: "umaler"),
                "XcodeProj"
        ])
    ]
)
