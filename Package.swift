// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Suohai",
    defaultLocalization: "en",
    platforms: [
        .macOS("27.0")
    ],
    products: [
        .executable(name: "Suohai", targets: ["Suohai"])
    ],
    targets: [
        .target(
            name: "SuohaiDomain",
            path: "src/domain"
        ),
        .target(
            name: "SuohaiApplication",
            dependencies: ["SuohaiDomain"],
            path: "src/application"
        ),
        .target(
            name: "SuohaiAdapters",
            dependencies: ["SuohaiApplication", "SuohaiDomain"],
            path: "src/adapters/macos"
        ),
        .executableTarget(
            name: "Suohai",
            dependencies: ["SuohaiApplication", "SuohaiAdapters", "SuohaiDomain"],
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
                "src/domain",
                "src/application",
                "src/adapters/macos",
                "tests"
            ],
            sources: ["src/app", "src/adapters/presentation"],
            resources: [
                .process("assets/icons/app-assets.xcassets"),
                .copy("assets/icons/StatusItem.pdf"),
                .process("assets/i18n/en.lproj"),
                .process("assets/i18n/zh-Hans.lproj")
            ]
        ),
        .testTarget(
            name: "SuohaiDomainTests",
            dependencies: ["SuohaiDomain"],
            path: "tests/domain"
        ),
        .testTarget(
            name: "SuohaiApplicationTests",
            dependencies: ["SuohaiApplication", "SuohaiDomain"],
            path: "tests/application"
        ),
        .testTarget(
            name: "SuohaiAdaptersTests",
            dependencies: ["SuohaiAdapters", "SuohaiApplication", "SuohaiDomain"],
            path: "tests/adapters"
        )
    ],
    swiftLanguageModes: [.v6]
)
