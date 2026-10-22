// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "CodexResetRadar",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "RadarCore", path: "Sources/RadarCore"),
        .executableTarget(
            name: "CodexResetRadar",
            dependencies: ["RadarCore"],
            path: "Sources/CodexResetRadar"
        ),
        .testTarget(
            name: "RadarCoreTests",
            dependencies: ["RadarCore"],
            path: "Tests/RadarCoreTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
