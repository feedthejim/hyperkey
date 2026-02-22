// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "hyperkey",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "hyperkey",
            path: "Sources/hyperkey",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
