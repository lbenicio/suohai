// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Suohai",
    defaultLocalization: "en",
    platforms: [
        .macOS("27.0"),
    ],
    products: [
        .executable(name: "Suohai", targets: ["Suohai"]),
    ],
    targets: [
        .target(
            name: "SuohaiCore",
            path: "src/core"
        ),
        .executableTarget(
            name: "Suohai",
            dependencies: ["SuohaiCore"],
            path: ".",
            exclude: [
                ".gitignore",
                "LICENSE.txt",
                "README.md",
                "CHANGELOG.md",
                "CODE_OF_CONDUCT.md",
                "CONTRIBUTING.md",
                "SECURITY.md",
                "assets/plist/Info.plist",
                "scripts",
                ".github",
                "src/core",
                "tests",
            ],
            sources: ["src"],
            resources: [
                .process("assets/icons/app-assets.xcassets"),
                .copy("assets/icons/StatusItem.pdf"),
                .process("assets/i18n/en.lproj"),
                .process("assets/i18n/zh-Hans.lproj"),
            ]
        ),
        .testTarget(
            name: "SuohaiCoreTests",
            dependencies: ["SuohaiCore"],
            path: "tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
