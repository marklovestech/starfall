// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Starfall",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "StarfallCore"),
        .executableTarget(name: "Starfall", dependencies: ["StarfallCore"], path: "Sources/StarfallApp"),
        .testTarget(name: "StarfallCoreTests", dependencies: ["StarfallCore"]),
    ]
)
