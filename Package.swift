// swift-tools-version: 6.0

import Foundation
import PackageDescription

// store selects the Mac App Store flavor, which leaves out the stills renderer.
let store = ProcessInfo.processInfo.environment["FUGINAUT_STORE"] != nil
let settings: [SwiftSetting] = store ? [.define("FUGINAUT_STORE")] : []

let package = Package(
    name: "Fuginaut",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "FuginautCore",
            swiftSettings: settings
        ),
        .executableTarget(
            name: "Fuginaut",
            dependencies: ["FuginautCore"],
            exclude: ["Info.plist"] + (store ? ["Stills.swift"] : []),
            swiftSettings: settings
        ),
        .testTarget(
            name: "FuginautCoreTests",
            dependencies: ["FuginautCore"],
            swiftSettings: settings
        ),
    ]
)
