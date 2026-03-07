// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DevBliss",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "AsciiToHexClient", targets: ["AsciiToHexClient"]),
        .library(name: "AsciiToHexFeature", targets: ["AsciiToHexFeature"]),
        .library(name: "BackslashEscapeClient", targets: ["BackslashEscapeClient"]),
        .library(name: "BackslashEscapeFeature", targets: ["BackslashEscapeFeature"]),
        .library(name: "Base64Client", targets: ["Base64Client"]),
        .library(name: "Base64Feature", targets: ["Base64Feature"]),
        .library(name: "Base64ImageClient", targets: ["Base64ImageClient"]),
        .library(name: "Base64ImageFeature", targets: ["Base64ImageFeature"]),
        .library(name: "BlissTheme", targets: ["BlissTheme"]),
        .library(name: "CertificateDecoderClient", targets: ["CertificateDecoderClient"]),
        .library(name: "CertificateDecoderFeature", targets: ["CertificateDecoderFeature"]),
        .library(name: "ClipboardClient", targets: ["ClipboardClient"]),
        .library(name: "ColorConverterClient", targets: ["ColorConverterClient"]),
        .library(name: "ColorConverterFeature", targets: ["ColorConverterFeature"]),
        .library(name: "CommandLineClient", targets: ["CommandLineClient"]),
        .library(name: "CssBeautifyClient", targets: ["CssBeautifyClient"]),
        .library(name: "CssBeautifyFeature", targets: ["CssBeautifyFeature"]),
        .library(name: "FileContentSearchClient", targets: ["FileContentSearchClient"]),
        .library(name: "FileContentSearchFeature", targets: ["FileContentSearchFeature"]),
        .library(name: "FilePanelsClient", targets: ["FilePanelsClient"]),
        .library(name: "FilesClient", targets: ["FilesClient"]),
        .library(name: "HashGeneratorClient", targets: ["HashGeneratorClient"]),
        .library(name: "HashGeneratorFeature", targets: ["HashGeneratorFeature"]),
        .library(name: "HexToAsciiClient", targets: ["HexToAsciiClient"]),
        .library(name: "HexToAsciiFeature", targets: ["HexToAsciiFeature"]),
        .library(name: "HtmlBeautifyClient", targets: ["HtmlBeautifyClient"]),
        .library(name: "HtmlBeautifyFeature", targets: ["HtmlBeautifyFeature"]),
        .library(name: "HtmlPreviewClient", targets: ["HtmlPreviewClient"]),
        .library(name: "HtmlPreviewFeature", targets: ["HtmlPreviewFeature"]),
        .library(name: "HtmlToMarkdownClient", targets: ["HtmlToMarkdownClient"]),
        .library(name: "HtmlToMarkdownFeature", targets: ["HtmlToMarkdownFeature"]),
        .library(name: "HtmlToSwiftClient", targets: ["HtmlToSwiftClient"]),
        .library(name: "HtmlToSwiftFeature", targets: ["HtmlToSwiftFeature"]),
        .library(name: "InputOutput", targets: ["InputOutput"]),
        .library(name: "JsBeautifyClient", targets: ["JsBeautifyClient"]),
        .library(name: "JsBeautifyFeature", targets: ["JsBeautifyFeature"]),
        .library(name: "JsonPrettyClient", targets: ["JsonPrettyClient"]),
        .library(name: "JsonPrettyFeature", targets: ["JsonPrettyFeature"]),
        .library(name: "JsonToYamlClient", targets: ["JsonToYamlClient"]),
        .library(name: "JsonToYamlFeature", targets: ["JsonToYamlFeature"]),
        .library(name: "JwtDebuggerClient", targets: ["JwtDebuggerClient"]),
        .library(name: "JwtDebuggerFeature", targets: ["JwtDebuggerFeature"]),
        .library(name: "LineSortDedupeClient", targets: ["LineSortDedupeClient"]),
        .library(name: "LineSortDedupeFeature", targets: ["LineSortDedupeFeature"]),
        .library(name: "NameGeneratorClient", targets: ["NameGeneratorClient"]),
        .library(name: "NameGeneratorFeature", targets: ["NameGeneratorFeature"]),
        .library(name: "NumberBaseConverterClient", targets: ["NumberBaseConverterClient"]),
        .library(name: "NumberBaseConverterFeature", targets: ["NumberBaseConverterFeature"]),
        .library(name: "PrefixSuffixClient", targets: ["PrefixSuffixClient"]),
        .library(name: "PrefixSuffixFeature", targets: ["PrefixSuffixFeature"]),
        .library(name: "QrCodeToolClient", targets: ["QrCodeToolClient"]),
        .library(name: "QrCodeToolFeature", targets: ["QrCodeToolFeature"]),
        .library(name: "RandomStringGeneratorClient", targets: ["RandomStringGeneratorClient"]),
        .library(name: "RandomStringGeneratorFeature", targets: ["RandomStringGeneratorFeature"]),
        .library(name: "RegexMatchesClient", targets: ["RegexMatchesClient"]),
        .library(name: "RegexMatchesFeature", targets: ["RegexMatchesFeature"]),
        .library(name: "RegExpTesterClient", targets: ["RegExpTesterClient"]),
        .library(name: "RegExpTesterFeature", targets: ["RegExpTesterFeature"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "StringDiffClient", targets: ["StringDiffClient"]),
        .library(name: "StringDiffFeature", targets: ["StringDiffFeature"]),
        .library(name: "StringInspectorClient", targets: ["StringInspectorClient"]),
        .library(name: "StringInspectorFeature", targets: ["StringInspectorFeature"]),
        .library(name: "SvgToCssClient", targets: ["SvgToCssClient"]),
        .library(name: "SvgToCssFeature", targets: ["SvgToCssFeature"]),
        .library(name: "SwiftPrettyClient", targets: ["SwiftPrettyClient"]),
        .library(name: "SwiftPrettyFeature", targets: ["SwiftPrettyFeature"]),
        .library(name: "SyntaxHighlightClient", targets: ["SyntaxHighlightClient"]),
        .library(name: "TextCaseConverterClient", targets: ["TextCaseConverterClient"]),
        .library(name: "TextCaseConverterFeature", targets: ["TextCaseConverterFeature"]),
        .library(name: "UnixTimeClient", targets: ["UnixTimeClient"]),
        .library(name: "UnixTimeFeature", targets: ["UnixTimeFeature"]),
        .library(name: "UrlEncodeClient", targets: ["UrlEncodeClient"]),
        .library(name: "UrlEncodeFeature", targets: ["UrlEncodeFeature"]),
        .library(name: "UrlParserClient", targets: ["UrlParserClient"]),
        .library(name: "UrlParserFeature", targets: ["UrlParserFeature"]),
        .library(name: "UrlToMarkdownClient", targets: ["UrlToMarkdownClient"]),
        .library(name: "UrlToMarkdownFeature", targets: ["UrlToMarkdownFeature"]),
        .library(name: "UUIDGeneratorClient", targets: ["UUIDGeneratorClient"]),
        .library(name: "UUIDGeneratorFeature", targets: ["UUIDGeneratorFeature"]),
        .library(name: "UuidUlidClient", targets: ["UuidUlidClient"]),
        .library(name: "UuidUlidFeature", targets: ["UuidUlidFeature"]),
        .library(name: "XmlFormatClient", targets: ["XmlFormatClient"]),
        .library(name: "XmlFormatFeature", targets: ["XmlFormatFeature"]),
        .library(name: "YamlToJsonClient", targets: ["YamlToJsonClient"]),
        .library(name: "YamlToJsonFeature", targets: ["YamlToJsonFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/atacan/JSBeautify.git", branch: "main"),
        .package(url: "https://github.com/atacan/swift-jsdiff", branch: "main"),
        .package(url: "https://github.com/atacan/swift-highlight.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-asn1", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-certificates", from: "1.11.0"),
        .package(url: "https://github.com/atacan/demark", branch: "convert-url"),
        .package(url: "https://github.com/atacan/html-swift", branch: "main"),
        .package(url: "https://github.com/atacan/MacSwiftUI", branch: "main"),
        .package(url: "https://github.com/atacan/PillPickerView", branch: "develop"),
        .package(url: "https://github.com/atacan/TCAEnchancements", from: "1.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.0.0"),
        .package(url: "https://github.com/dagronf/DSFQuickActionBar", branch: "main"),
        .package(url: "https://github.com/dagronf/QRCode", from: "11.0.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.0.1"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.51.0"),
        .package(url: "https://github.com/nkristek/Highlight.git", branch: "master"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
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
        .target(
            name: "AsciiToHexClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "AsciiToHexFeature",
            dependencies: [
                "AsciiToHexClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "ColorConverterClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "ColorConverterFeature",
            dependencies: [
                "ColorConverterClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
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
            name: "HashGeneratorClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HashGeneratorFeature",
            dependencies: [
                "HashGeneratorClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "SvgToCssClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "SvgToCssFeature",
            dependencies: [
                "SvgToCssClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "BackslashEscapeClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "BackslashEscapeFeature",
            dependencies: [
                "BackslashEscapeClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "CertificateDecoderClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "X509", package: "swift-certificates"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
            ]
        ),
        .target(
            name: "CertificateDecoderFeature",
            dependencies: [
                "CertificateDecoderClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "SplitView", package: "SplitView"),
            ]
        ),
        .target(
            name: "QrCodeToolClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "QRCode", package: "QRCode"),
            ]
        ),
        .target(
            name: "QrCodeToolFeature",
            dependencies: [
                "QrCodeToolClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "SplitView", package: "SplitView"),
                .product(name: "QRCode", package: "QRCode"),
            ]
        ),
        .target(
            name: "JsonToYamlClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .target(
            name: "JsonToYamlFeature",
            dependencies: [
                "JsonToYamlClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                "SyntaxHighlightClient",
            ]
        ),
        .target(
            name: "YamlToJsonClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .target(
            name: "YamlToJsonFeature",
            dependencies: [
                "YamlToJsonClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "UuidUlidClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "ULID", package: "ULID.swift"),
            ]
        ),
        .target(
            name: "UuidUlidFeature",
            dependencies: [
                "UuidUlidClient",
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
        .testTarget(
            name: "FileContentSearchFeatureTests",
            dependencies: [
                "FileContentSearchFeature",
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
                "SyntaxHighlightClient",
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
                "SyntaxHighlightClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]
        ),
        .target(
            name: "HtmlPreviewClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HtmlPreviewFeature",
            dependencies: [
                "HtmlPreviewClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "SplitView", package: "SplitView"),
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
            name: "UrlParserClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "UrlParserFeature",
            dependencies: [
                "UrlParserClient",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "UrlToMarkdownFeature",
            dependencies: [
                "UrlToMarkdownClient",
                "HtmlToMarkdownClient",
                "InputOutput",
                "SharedModels",
                "SyntaxHighlightClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
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
            name: "HtmlBeautifyClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSBeautify", package: "JSBeautify"),
            ]
        ),
        .target(
            name: "HtmlBeautifyFeature",
            dependencies: [
                "HtmlBeautifyClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "CssBeautifyClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSBeautify", package: "JSBeautify"),
            ]
        ),
        .target(
            name: "CssBeautifyFeature",
            dependencies: [
                "CssBeautifyClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "JsBeautifyClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSBeautify", package: "JSBeautify"),
            ]
        ),
        .target(
            name: "JsBeautifyFeature",
            dependencies: [
                "JsBeautifyClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "LineSortDedupeClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "LineSortDedupeFeature",
            dependencies: [
                "LineSortDedupeClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "HexToAsciiClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HexToAsciiFeature",
            dependencies: [
                "HexToAsciiClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "XmlFormatClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "XmlFormatFeature",
            dependencies: [
                "XmlFormatClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
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
            name: "RandomStringGeneratorClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "RandomStringGeneratorFeature",
            dependencies: [
                "RandomStringGeneratorClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
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
            name: "RegExpTesterClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "RegExpTesterFeature",
            dependencies: [
                "RegExpTesterClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "SplitView", package: "SplitView"),
            ]
        ),
        .target(
            name: "StringDiffClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JSDiff", package: "swift-jsdiff"),
            ]
        ),
        .target(
            name: "StringDiffFeature",
            dependencies: [
                "StringDiffClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
                .product(name: "JSDiff", package: "swift-jsdiff"),
                .product(name: "JSDiffUI", package: "swift-jsdiff"),
            ]
        ),
        .target(
            name: "StringInspectorClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "StringInspectorFeature",
            dependencies: [
                "StringInspectorClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
            ]
        ),
        .target(
            name: "NumberBaseConverterClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "NumberBaseConverterFeature",
            dependencies: [
                "NumberBaseConverterClient",
                "InputOutput",
                "SharedModels",
                "BlissTheme",
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
            name: "JwtDebuggerClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
            ]
        ),
        .target(
            name: "JwtDebuggerFeature",
            dependencies: [
                "JwtDebuggerClient",
                "InputOutput",
                "SharedModels",
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
            name: "JsonToYamlClientTests",
            dependencies: [
                "JsonToYamlClient",
                "SyntaxHighlightClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "HtmlToSwiftClientTests",
            dependencies: ["HtmlToSwiftClient"]
        ),
    ]
)
