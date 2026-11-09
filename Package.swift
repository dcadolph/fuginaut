// swift-tools-version: 6.0

import Foundation
import PackageDescription

// store selects the Mac App Store flavor, which leaves out the update checker and the stills renderer.
let store = ProcessInfo.processInfo.environment["FUGINAUT_STORE"] != nil
let settings: [SwiftSetting] = store ? [.define("FUGINAUT_STORE")] : []

let package = Package(
    name: "Fuginaut",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "FuginautCore",
            exclude: store ? ["Update.swift"] : [],
            swiftSettings: settings
        ),
        .executableTarget(
            name: "Fuginaut",
            dependencies: ["FuginautCore"],
            exclude: ["Info.plist"] + (store ? ["UpdateMonitor.swift", "Stills.swift"] : []),
            swiftSettings: settings
        ),
        .testTarget(
            name: "FuginautCoreTests",
            dependencies: ["FuginautCore"],
            exclude: store ? ["UpdateTests.swift"] : [],
            swiftSettings: settings
        ),
    ]
)
