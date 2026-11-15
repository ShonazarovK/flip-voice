// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlipVoice",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FlipVoice",
            targets: ["FlipVoice"]
        )
    ],
    targets: [
        .target(
            name: "FlipVoice",
            path: "FlipVoice",
            exclude: [
                "Resources/Info.plist",
                "Resources/PrivacyInfo.xcprivacy"
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "FlipVoiceTests",
            dependencies: ["FlipVoice"],
            path: "FlipVoiceTests"
        )
    ]
)

