// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MKey",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "MKey", targets: ["MKey"])
    ],
    targets: [
        .executableTarget(
            name: "MKey",
            path: "Sources/MKey"
        )
    ]
)
