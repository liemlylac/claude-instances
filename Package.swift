// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeInstances",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClaudeInstances",
            path: "Sources/ClaudeInstances"
        )
    ]
)
