// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DevBliss",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "Base64Client", targets: ["Base64Client"]),
        .library(name: "Base64Feature", targets: ["Base64Feature"]),
        .library(name: "Base64ImageClient", targets: ["Base64ImageClient"]),
        .library(name: "Base64ImageFeature", targets: ["Base64ImageFeature"]),
        .library(name: "BlissTheme", targets: ["BlissTheme"]),
        .library(name: "InputOutput", targets: ["InputOutput"]),
        .library(name: "ClipboardClient", targets: ["ClipboardClient"]),
        .library(name: "CommandLineClient", targets: ["CommandLineClient"]),
        .library(name: "FileContentSearchClient", targets: ["FileContentSearchClient"]),
        .library(name: "FileContentSearchFeature", targets: ["FileContentSearchFeature"]),
        .library(name: "FilesClient", targets: ["FilesClient"]),
        .library(name: "FilePanelsClient", targets: ["FilePanelsClient"]),
        .library(name: "HtmlToSwiftClient", targets: ["HtmlToSwiftClient"]),
        .library(name: "HtmlToSwiftFeature", targets: ["HtmlToSwiftFeature"]),
        .library(name: "HtmlToMarkdownClient", targets: ["HtmlToMarkdownClient"]),
        .library(name: "HtmlToMarkdownFeature", targets: ["HtmlToMarkdownFeature"]),
        .library(name: "UrlToMarkdownClient", targets: ["UrlToMarkdownClient"]),
        .library(name: "UrlToMarkdownFeature", targets: ["UrlToMarkdownFeature"]),
        .library(name: "JsonPrettyClient", targets: ["JsonPrettyClient"]),
        .library(name: "JsonPrettyFeature", targets: ["JsonPrettyFeature"]),
        .library(name: "NameGeneratorClient", targets: ["NameGeneratorClient"]),
        .library(name: "NameGeneratorFeature", targets: ["NameGeneratorFeature"]),
        .library(name: "PrefixSuffixClient", targets: ["PrefixSuffixClient"]),
        .library(name: "PrefixSuffixFeature", targets: ["PrefixSuffixFeature"]),
        .library(name: "RegexMatchesClient", targets: ["RegexMatchesClient"]),
        .library(name: "RegexMatchesFeature", targets: ["RegexMatchesFeature"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "SwiftPrettyClient", targets: ["SwiftPrettyClient"]),
        .library(name: "SwiftPrettyFeature", targets: ["SwiftPrettyFeature"]),
        .library(name: "TextCaseConverterClient", targets: ["TextCaseConverterClient"]),
        .library(name: "TextCaseConverterFeature", targets: ["TextCaseConverterFeature"]),
        .library(name: "UnixTimeClient", targets: ["UnixTimeClient"]),
        .library(name: "UnixTimeFeature", targets: ["UnixTimeFeature"]),
        .library(name: "UrlEncodeClient", targets: ["UrlEncodeClient"]),
        .library(name: "UrlEncodeFeature", targets: ["UrlEncodeFeature"]),
        .library(name: "UUIDGeneratorClient", targets: ["UUIDGeneratorClient"]),
        .library(name: "UUIDGeneratorFeature", targets: ["UUIDGeneratorFeature"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
        .package(url: "https://github.com/stevengharris/SplitView", from: "3.1.0"),
        .package(url: "https://github.com/atacan/html-swift", branch: "main"),
        .package(url: "https://github.com/nkristek/Highlight.git", branch: "master"),
        .package(url: "https://github.com/atacan/MacSwiftUI", branch: "main"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.51.0"),
        .package(url: "https://github.com/atacan/TCAEnchancements", from: "1.0.0"),
        .package(url: "https://github.com/atacan/PillPickerView", branch: "develop"),
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions", branch: "xcode26"),
        .package(url: "https://github.com/atacan/demark", branch: "convert-url"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.

        .target(
            name: "AppFeature",
            dependencies: [
                "SharedModels",
                "Base64Feature",
                "Base64ImageFeature",
                "HtmlToSwiftFeature",
                "HtmlToMarkdownFeature",
                "UrlToMarkdownFeature",
                "JsonPrettyFeature",
                "TextCaseConverterFeature",
                "UUIDGeneratorFeature",
                "PrefixSuffixFeature",
                "RegexMatchesFeature",
                "SwiftPrettyFeature",
                "FileContentSearchFeature",
                "NameGeneratorFeature",
                "UnixTimeFeature",
                "UrlEncodeFeature",
            ]
        ),
        .target(
            name: "Base64Client",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "Base64Feature",
            dependencies: [
                "Base64Client",
                "InputOutput",
                "SharedModels",
            ]
        ),
        .target(
            name: "Base64ImageClient",
            dependencies: [
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "Base64ImageFeature",
            dependencies: [
                "Base64ImageClient",
                "BlissTheme",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "BlissTheme",
            dependencies: []
        ),
        .target(
            name: "InputOutput",
            dependencies: [
                "ClipboardClient",
                "BlissTheme",
                "SharedModels",
                "FilePanelsClient",
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "MacSwiftUI", package: "MacSwiftUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "ClipboardClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "CommandLineClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "FileContentSearchClient",
            dependencies: [
                "CommandLineClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "FileContentSearchFeature",
            dependencies: [
                "FileContentSearchClient",
                "FilePanelsClient",
                "InputOutput",
                "FilesClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "TCAEnchance", package: "TCAEnchancements"),
            ]
        ),
        .target(
            name: "FilesClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "FilePanelsClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HtmlToSwiftClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "HtmlSwift", package: "html-swift"),
            ]
        ),
        .target(
            name: "HtmlToSwiftFeature",
            dependencies: [
                "HtmlToSwiftClient",
                "InputOutput",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .testTarget(
            name: "HtmlToSwiftFeatureTests",
            dependencies: [
                "HtmlToSwiftFeature",
            ]
        ),
        .target(
            name: "HtmlToMarkdownClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Demark", package: "demark"),
            ]
        ),
        .target(
            name: "HtmlToMarkdownFeature",
            dependencies: [
                "HtmlToMarkdownClient",
                "InputOutput",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .target(
            name: "UrlToMarkdownClient",
            dependencies: [
                "HtmlToMarkdownClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Demark", package: "demark"),
            ]
        ),
        .target(
            name: "UrlToMarkdownFeature",
            dependencies: [
                "UrlToMarkdownClient",
                "HtmlToMarkdownClient",
                "InputOutput",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .target(
            name: "JsonPrettyClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Highlight", package: "Highlight"),
            ]
        ),
        .target(
            name: "JsonPrettyFeature",
            dependencies: [
                "JsonPrettyClient",
                "InputOutput",
                "SharedModels",
            ]
        ),
        .target(
            name: "NameGeneratorClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "NameGeneratorFeature",
            dependencies: [
                "NameGeneratorClient",
                "InputOutput",
                "PillPickerView",
            ]
        ),
        .target(
            name: "PrefixSuffixClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                "SharedModels",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .testTarget(
            name: "PrefixSuffixClientTests",
            dependencies: [
                "PrefixSuffixClient",
            ]
        ),
        .target(
            name: "PrefixSuffixFeature",
            dependencies: [
                "PrefixSuffixClient",
                "InputOutput",
                "SharedModels",
            ]
        ),
        .testTarget(
            name: "PrefixSuffixFeatureTests",
            dependencies: [
                "PrefixSuffixFeature",
            ]
        ),
        .target(
            name: "RegexMatchesClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "RegexMatchesClientTests",
            dependencies: [
                "RegexMatchesClient",
            ]
        ),
        .target(
            name: "RegexMatchesFeature",
            dependencies: [
                "RegexMatchesClient",
                "InputOutput",
                "SharedModels",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .target(
            name: "SwiftPrettyClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftFormat", package: "SwiftFormat"),
            ]
        ),
        .target(
            name: "SwiftPrettyFeature",
            dependencies: [
                "SwiftPrettyClient",
                "InputOutput",
                "SharedModels",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .testTarget(
            name: "SwiftPrettyFeatureTests",
            dependencies: [
                "SwiftPrettyFeature",
            ]
        ),
        .target(
            name: "TextCaseConverterClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "TextCaseConverterFeature",
            dependencies: [
                "TextCaseConverterClient",
                "InputOutput",
                "SharedModels",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .target(
            name: "UnixTimeClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UnixTimeFeature",
            dependencies: [
                "UnixTimeClient",
                "BlissTheme",
                "SharedModels",
            ]
        ),
        .target(
            name: "UrlEncodeClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UrlEncodeFeature",
            dependencies: [
                "UrlEncodeClient",
                "BlissTheme",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "UUIDGeneratorClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UUIDGeneratorFeature",
            dependencies: [
                "UUIDGeneratorClient",
                "InputOutput",
            ]
        ),
        .target(
            name: "SharedModels",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            resources: [.process("Resources")]
        ),

        .testTarget(
            name: "HtmlToSwiftClientTests",
            dependencies: ["HtmlToSwiftClient"]
        ),
    ]
)
