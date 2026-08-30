// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DevBliss",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "AsciiToHexFeature", targets: ["AsciiToHexFeature"]),
        .library(name: "BackslashEscapeFeature", targets: ["BackslashEscapeFeature"]),
        .library(name: "Base64Feature", targets: ["Base64Feature"]),
        .library(name: "Base64ImageFeature", targets: ["Base64ImageFeature"]),
        .library(name: "BlissTheme", targets: ["BlissTheme"]),
        .library(name: "CertificateDecoderFeature", targets: ["CertificateDecoderFeature"]),
        .library(name: "ClipboardClient", targets: ["ClipboardClient"]),
        .library(name: "ColorConverterFeature", targets: ["ColorConverterFeature"]),
        .library(name: "CommandLineClient", targets: ["CommandLineClient"]),
        .library(name: "CssBeautifyFeature", targets: ["CssBeautifyFeature"]),
        .library(name: "FileContentSearchFeature", targets: ["FileContentSearchFeature"]),
        .library(name: "FilePanelsClient", targets: ["FilePanelsClient"]),
        .library(name: "FilesClient", targets: ["FilesClient"]),
        .library(name: "FilesToMarkdownFeature", targets: ["FilesToMarkdownFeature"]),
        .library(name: "HashGeneratorFeature", targets: ["HashGeneratorFeature"]),
        .library(name: "HexToAsciiFeature", targets: ["HexToAsciiFeature"]),
        .library(name: "HtmlBeautifyFeature", targets: ["HtmlBeautifyFeature"]),
        .library(name: "HtmlPreviewFeature", targets: ["HtmlPreviewFeature"]),
        .library(name: "HtmlToMarkdownFeature", targets: ["HtmlToMarkdownFeature"]),
        .library(name: "HtmlToSwiftFeature", targets: ["HtmlToSwiftFeature"]),
        .library(name: "InputOutput", targets: ["InputOutput"]),
        .library(name: "JsBeautifyFeature", targets: ["JsBeautifyFeature"]),
        .library(name: "JsonPrettyFeature", targets: ["JsonPrettyFeature"]),
        .library(name: "JsonToYamlFeature", targets: ["JsonToYamlFeature"]),
        .library(name: "JwtDebuggerFeature", targets: ["JwtDebuggerFeature"]),
        .library(name: "LineSortDedupeFeature", targets: ["LineSortDedupeFeature"]),
        .library(name: "MarkdownPreviewFeature", targets: ["MarkdownPreviewFeature"]),
        .library(name: "NameGeneratorFeature", targets: ["NameGeneratorFeature"]),
        .library(name: "NumberBaseConverterFeature", targets: ["NumberBaseConverterFeature"]),
        .library(name: "PrefixSuffixFeature", targets: ["PrefixSuffixFeature"]),
        .library(name: "QrCodeToolFeature", targets: ["QrCodeToolFeature"]),
        .library(name: "RandomStringGeneratorFeature", targets: ["RandomStringGeneratorFeature"]),
        .library(name: "RegexMatchesFeature", targets: ["RegexMatchesFeature"]),
        .library(name: "RegExpTesterFeature", targets: ["RegExpTesterFeature"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "StringDiffFeature", targets: ["StringDiffFeature"]),
        .library(name: "StringInspectorFeature", targets: ["StringInspectorFeature"]),
        .library(name: "SvgToCssFeature", targets: ["SvgToCssFeature"]),
        .library(name: "SwiftPrettyFeature", targets: ["SwiftPrettyFeature"]),
        .library(name: "SyntaxHighlightClient", targets: ["SyntaxHighlightClient"]),
        .library(name: "TextCaseConverterFeature", targets: ["TextCaseConverterFeature"]),
        .library(name: "UnixTimeFeature", targets: ["UnixTimeFeature"]),
        .library(name: "UrlEncodeFeature", targets: ["UrlEncodeFeature"]),
        .library(name: "UrlParserFeature", targets: ["UrlParserFeature"]),
        .library(name: "UrlToMarkdownFeature", targets: ["UrlToMarkdownFeature"]),
        .library(name: "UUIDGeneratorFeature", targets: ["UUIDGeneratorFeature"]),
        .library(name: "UuidUlidFeature", targets: ["UuidUlidFeature"]),
        .library(name: "XmlFormatFeature", targets: ["XmlFormatFeature"]),
        .library(name: "YamlToJsonFeature", targets: ["YamlToJsonFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/atacan/JSBeautify.git", revision: "dd73e2ed6553e9240c1239efadb14898b07ea5d5"),
        .package(url: "https://github.com/atacan/swift-jsdiff.git", revision: "ad68d189b35ea9b57ed02c8aa7ebe0a0d138193a"),
        .package(url: "https://github.com/atacan/swift-highlight.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-asn1", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-certificates", from: "1.11.0"),
        .package(url: "https://github.com/atacan/demark", branch: "convert-url"),
        .package(url: "https://github.com/atacan/html-swift", branch: "main"),
        .package(url: "https://github.com/atacan/MacSwiftUI", branch: "main"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.0.0"),
        .package(url: "https://github.com/dagronf/DSFQuickActionBar", branch: "main"),
        .package(url: "https://github.com/dagronf/QRCode", from: "11.0.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.0"),
        .package(url: "https://github.com/gonzalezreal/textual", from: "0.1.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.0.1"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.51.0"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", from: "1.0.0"),
        .package(url: "https://github.com/nkristek/Highlight.git", branch: "master"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
        .package(url: "https://github.com/stevengharris/SplitView", from: "3.1.0"),
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions", branch: "xcode26"),
        .package(url: "https://github.com/yaslab/ULID.swift", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.

        .target(
            name: "AppFeature",
            dependencies: [
                .product(name: "DSFQuickActionBar", package: "DSFQuickActionBar", condition: .when(platforms: [.macOS])),
                "AsciiToHexFeature",
                "BackslashEscapeFeature",
                "Base64Feature",
                "Base64ImageFeature",
                "CertificateDecoderFeature",
                "ColorConverterFeature",
                "CssBeautifyFeature",
                "FileContentSearchFeature",
                "FilesToMarkdownFeature",
                "HashGeneratorFeature",
                "HexToAsciiFeature",
                "HtmlBeautifyFeature",
                "HtmlPreviewFeature",
                "HtmlToMarkdownFeature",
                "HtmlToSwiftFeature",
                "JsBeautifyFeature",
                "JsonPrettyFeature",
                "JsonToYamlFeature",
                "JwtDebuggerFeature",
                "LineSortDedupeFeature",
                "MarkdownPreviewFeature",
                "NameGeneratorFeature",
                "NumberBaseConverterFeature",
                "PrefixSuffixFeature",
                "QrCodeToolFeature",
                "RandomStringGeneratorFeature",
                "RegexMatchesFeature",
                "RegExpTesterFeature",
                "SharedModels",
                "StringDiffFeature",
                "StringInspectorFeature",
                "SvgToCssFeature",
                "SwiftPrettyFeature",
                "TextCaseConverterFeature",
                "UnixTimeFeature",
                "UrlEncodeFeature",
                "UrlParserFeature",
                "UrlToMarkdownFeature",
                "UUIDGeneratorFeature",
                "UuidUlidFeature",
                "XmlFormatFeature",
                "YamlToJsonFeature",
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                "SharedModels",
            ]
        ),
        .target(
            name: "AsciiToHexFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "MarkdownPreviewFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "Textual", package: "textual"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "ColorConverterFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "Base64Feature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "Base64ImageFeature",
            dependencies: [
                "BlissTheme",
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "HashGeneratorFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "SvgToCssFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "SvgToCssFeatureTests",
            dependencies: [
                "SvgToCssFeature",
            ]
        ),
        .target(
            name: "BackslashEscapeFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "BackslashEscapeFeatureTests",
            dependencies: [
                "BackslashEscapeFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "Base64FeatureTests",
            dependencies: [
                "Base64Feature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "CertificateDecoderFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "X509", package: "swift-certificates"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
            ]
        ),
        .target(
            name: "QrCodeToolFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "QRCode", package: "QRCode"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "JsonToYamlFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                "SyntaxHighlightClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .target(
            name: "YamlToJsonFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .target(
            name: "UuidUlidFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "ULID", package: "ULID.swift"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "SplitView", package: "SplitView"),
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
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "MacSwiftUI", package: "MacSwiftUI"),
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
            name: "FileContentSearchFeature",
            dependencies: [
                "FilePanelsClient",
                "InputOutput",
                "FilesClient",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "FileContentSearchFeatureTests",
            dependencies: [
                "FileContentSearchFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "FilesToMarkdownFeature",
            dependencies: [
                "FilePanelsClient",
                "CommandLineClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "FilesToMarkdownFeatureTests",
            dependencies: [
                "FilesToMarkdownFeature",
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
            name: "SyntaxHighlightClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftHighlight", package: "swift-highlight"),
            ]
        ),
        .target(
            name: "HtmlToSwiftFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                "SyntaxHighlightClient",
                .product(name: "HtmlSwift", package: "html-swift"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .testTarget(
            name: "HtmlToSwiftFeatureTests",
            dependencies: [
                "HtmlToSwiftFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HtmlToMarkdownFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                "SyntaxHighlightClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Demark", package: "demark"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]
        ),
        .target(
            name: "HtmlPreviewFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "UrlParserFeature",
            dependencies: [
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "UrlParserFeatureTests",
            dependencies: [
                "UrlParserFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UrlToMarkdownFeature",
            dependencies: [
                "HtmlToMarkdownFeature",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                "SyntaxHighlightClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Demark", package: "demark"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]
        ),
        .target(
            name: "JsonPrettyFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Highlight", package: "Highlight"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "JsonPrettyFeatureTests",
            dependencies: [
                "JsonPrettyFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HtmlBeautifyFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSBeautify", package: "JSBeautify"),
                .product(name: "Sharing", package: "swift-sharing"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "CssBeautifyFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSBeautify", package: "JSBeautify"),
                .product(name: "Sharing", package: "swift-sharing"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "JsBeautifyFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSBeautify", package: "JSBeautify"),
                .product(name: "Sharing", package: "swift-sharing"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "LineSortDedupeFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "HexToAsciiFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .testTarget(
            name: "HexToAsciiFeatureTests",
            dependencies: [
                "HexToAsciiFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "HashGeneratorFeatureTests",
            dependencies: [
                "HashGeneratorFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "NumberBaseConverterFeatureTests",
            dependencies: [
                "NumberBaseConverterFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "AsciiToHexFeatureTests",
            dependencies: [
                "AsciiToHexFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "XmlFormatFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "NameGeneratorFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "NameGeneratorFeatureTests",
            dependencies: [
                "NameGeneratorFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "RandomStringGeneratorFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "PrefixSuffixFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .testTarget(
            name: "PrefixSuffixFeatureTests",
            dependencies: [
                "PrefixSuffixFeature",
            ]
        ),
        .target(
            name: "RegexMatchesFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "RegexMatchesFeatureTests",
            dependencies: [
                "RegexMatchesFeature",
            ]
        ),
        .target(
            name: "RegExpTesterFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "SplitView", package: "SplitView"),
            ]
        ),
        .target(
            name: "StringDiffFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSDiff", package: "swift-jsdiff"),
                .product(name: "JSDiffUI", package: "swift-jsdiff"),
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "StringDiffFeatureTests",
            dependencies: [
                "StringDiffFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "StringInspectorFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "NumberBaseConverterFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "SwiftPrettyFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "SwiftFormat", package: "SwiftFormat"),
            ]
        ),
        .testTarget(
            name: "SwiftPrettyFeatureTests",
            dependencies: [
                "SwiftPrettyFeature",
            ]
        ),
        .target(
            name: "TextCaseConverterFeature",
            dependencies: [
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        ),
        .testTarget(
            name: "TextCaseConverterFeatureTests",
            dependencies: [
                "TextCaseConverterFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UnixTimeFeature",
            dependencies: [
                "BlissTheme",
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "UrlEncodeFeature",
            dependencies: [
                "BlissTheme",
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "UrlEncodeFeatureTests",
            dependencies: [
                "UrlEncodeFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "XmlFormatFeatureTests",
            dependencies: [
                "XmlFormatFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "JwtDebuggerFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .testTarget(
            name: "JwtDebuggerFeatureTests",
            dependencies: [
                "JwtDebuggerFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UUIDGeneratorFeature",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Sharing", package: "swift-sharing"),
                "BlissTheme",
            ]
        ),
        .target(
            name: "SharedModels",
            dependencies: [
                .product(name: "Sharing", package: "swift-sharing"),
            ],
            resources: [.process("Resources")]
        ),

    ],
    swiftLanguageModes: [.v5]
)
