// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SwiftPulser",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftPulser",
            targets: ["SwiftPulser"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftPulser",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "SwiftPulserTests",
            dependencies: ["SwiftPulser"],
            path: "Tests"),
    ]
) 