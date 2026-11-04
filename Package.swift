// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Fuginaut",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "FuginautCore"),
        .executableTarget(
            name: "Fuginaut",
            dependencies: ["FuginautCore"],
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "FuginautCoreTests",
            dependencies: ["FuginautCore"]
        ),
    ]
)
