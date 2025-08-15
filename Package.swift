// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Phim",
    platforms: [
        .macOS(.v14)  // Changed from v15 for compatibility
    ],
    products: [
        .executable(name: "Phim", targets: ["Phim"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Phim",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "PhimSource",
            resources: [
                .copy("welcome.html")
            ]
        )
    ]
)