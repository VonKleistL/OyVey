// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OyVey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OyVey", targets: ["OyVey"]),
    ],
    dependencies: [
        // Example dependencies:
        // Whisper/Whisper.cpp or an SPM-compatible wrapper
        // https://github.com/openai/whisper.cpp (local integration)
        // Any translation API Swift wrapper (Google, DeepL, OpenAI)
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "OyVey",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "OyVeyTests",
            dependencies: ["OyVey"],
            path: "Tests"
        )
    ]
)