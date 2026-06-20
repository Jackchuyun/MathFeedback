// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MathFeedback",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MathFeedback",
            path: "."
        )
    ]
)
