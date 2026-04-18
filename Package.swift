// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StickyImage",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "StickyImage",
            path: "Sources/StickyImage"
        )
    ]
)
