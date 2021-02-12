// swift-tools-version:5.2

//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "General",
    platforms: [.macOS(.v10_12)],
    products: [
        .executable(
            name: "General",
            targets: ["General"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rosberry/GeneralKit.git", .branch("feature/xcode-independent")),
        .package(url: "https://github.com/rosberry/GeneralIOs.git", .branch("feature/general-ios"))
        // {% PackageDependency %}
    ],
    targets: [
        .target(
            name: "General",
            dependencies: [
                "GeneralKit",
                "GeneralIOs"
                // {% TargetDependency %}
        ])
    ]
)
