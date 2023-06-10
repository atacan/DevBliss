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
        .library(name: "Theme", targets: ["Theme"]),
        .library(name: "InputOutput", targets: ["InputOutput"]),
        .library(name: "ClipboardClient", targets: ["ClipboardClient"]),
        .library(name: "HtmlToSwiftClient", targets: ["HtmlToSwiftClient"]),
        .library(name: "HtmlToSwiftFeature", targets: ["HtmlToSwiftFeature"]),
        .library(name: "JsonPrettyClient", targets: ["JsonPrettyClient"]),
        .library(name: "JsonPrettyFeature", targets: ["JsonPrettyFeature"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.49.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.0"),
        .package(url: "https://github.com/stevengharris/SplitView", from: "3.1.0"),
        .package(url: "https://github.com/atacan/html-swift", branch: "main"),
        .package(url: "https://github.com/nkristek/Highlight.git", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Theme",
            dependencies: []
        ),
        .target(
            name: "InputOutput",
            dependencies: [
                "ClipboardClient",
                "Theme",
                .product(name: "SplitView", package: "SplitView"),
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
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "HtmlToSwiftClientTests",
            dependencies: ["HtmlToSwiftClient"]
        ),
    ]
)
