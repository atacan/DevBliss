// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DevBliss",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "BlissTheme", targets: ["BlissTheme"]),
        .library(name: "InputOutput", targets: ["InputOutput"]),
        .library(name: "ClipboardClient", targets: ["ClipboardClient"]),
        .library(name: "FilePanelsClient", targets: ["FilePanelsClient"]),
        .library(name: "HtmlToSwiftClient", targets: ["HtmlToSwiftClient"]),
        .library(name: "HtmlToSwiftFeature", targets: ["HtmlToSwiftFeature"]),
        .library(name: "JsonPrettyClient", targets: ["JsonPrettyClient"]),
        .library(name: "JsonPrettyFeature", targets: ["JsonPrettyFeature"]),
        .library(name: "PrefixSuffixClient", targets: ["PrefixSuffixClient"]),
        .library(name: "PrefixSuffixFeature", targets: ["PrefixSuffixFeature"]),
        .library(name: "RegexMatchesClient", targets: ["RegexMatchesClient"]),
        .library(name: "RegexMatchesFeature", targets: ["RegexMatchesFeature"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "SwiftPrettyClient", targets: ["SwiftPrettyClient"]),
        .library(name: "SwiftPrettyFeature", targets: ["SwiftPrettyFeature"]),
        .library(name: "TextCaseConverterClient", targets: ["TextCaseConverterClient"]),
        .library(name: "TextCaseConverterFeature", targets: ["TextCaseConverterFeature"]),
        .library(name: "UUIDGeneratorClient", targets: ["UUIDGeneratorClient"]),
        .library(name: "UUIDGeneratorFeature", targets: ["UUIDGeneratorFeature"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.49.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.0"),
        .package(url: "https://github.com/stevengharris/SplitView", from: "3.1.0"),
        .package(url: "https://github.com/atacan/html-swift", branch: "main"),
        .package(url: "https://github.com/nkristek/Highlight.git", branch: "master"),
        .package(url: "https://github.com/atacan/MacSwiftUI", branch: "main"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.51.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.

        .target(
            name: "AppFeature",
            dependencies: [
                "SharedModels",
                "HtmlToSwiftFeature",
                "JsonPrettyFeature",
                "TextCaseConverterFeature",
                "UUIDGeneratorFeature",
                "PrefixSuffixFeature",
                "RegexMatchesFeature",
                "SwiftPrettyFeature",
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
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "MacSwiftUI", package: "MacSwiftUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "ClipboardClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "FilePanelsClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
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
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
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
            ]
        ),
        .target(
            name: "PrefixSuffixClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .testTarget(
            name: "PrefixSuffixClientTests",
            dependencies: [
                "PrefixSuffixClient"
            ]
        ),
        .target(
            name: "PrefixSuffixFeature",
            dependencies: [
                "PrefixSuffixClient",
                "InputOutput",
            ]
        ),
        .target(
            name: "RegexMatchesClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .testTarget(
            name: "RegexMatchesClientTests",
            dependencies: [
                "RegexMatchesClient"
            ]
        ),
        .target(
            name: "RegexMatchesFeature",
            dependencies: [
                "RegexMatchesClient",
                "InputOutput",
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
            ]
        ),
        .target(
            name: "TextCaseConverterClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "TextCaseConverterFeature",
            dependencies: [
                "TextCaseConverterClient",
                "InputOutput",
            ]
        ),
        .target(
            name: "UUIDGeneratorClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
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
            dependencies: []
        ),

        .testTarget(
            name: "HtmlToSwiftClientTests",
            dependencies: ["HtmlToSwiftClient"]
        ),
    ]
)
