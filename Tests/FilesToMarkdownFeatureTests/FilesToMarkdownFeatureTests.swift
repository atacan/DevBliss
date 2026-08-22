import XCTest

@testable import FilesToMarkdownFeature

final class LanguageMapTests: XCTestCase {
    func testKnownExtensionsMapToLanguageIdentifiers() {
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "swift"), "swift")
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "js"), "javascript")
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "py"), "python")
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "md"), "markdown")
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "yml"), "yaml")
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "h"), "c")
    }

    func testLookupIsCaseInsensitive() {
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "SWIFT"), "swift")
        XCTAssertEqual(LanguageMap.languageIdentifier(forExtension: "JSON"), "json")
    }

    func testUnknownExtensionReturnsNil() {
        XCTAssertNil(LanguageMap.languageIdentifier(forExtension: "xyz"))
        XCTAssertNil(LanguageMap.languageIdentifier(forExtension: ""))
    }
}

final class MarkdownAssemblerTests: XCTestCase {
    private let options = CombineOptions(folderPath: "/tmp/DemoProject")

    func testAssemblesFencedBlocksWithLanguageAndRelativePath() {
        let files = [
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/Sources/App.swift"), relativePath: "Sources/App.swift"),
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/README.md"), relativePath: "README.md"),
        ]

        let result = MarkdownAssembler.assemble(
            files: files,
            contentProvider: { file in
                file.relativePath == "README.md" ? "# Hello" : "let x = 1"
            },
            options: options
        )

        XCTAssertEqual(result.skippedCount, 0)
        XCTAssertTrue(result.markdown.contains("```swift:Sources/App.swift\nlet x = 1\n```"))
        XCTAssertTrue(result.markdown.contains("```markdown:README.md\n# Hello\n```"))
    }

    func testUnknownExtensionOmitsLanguageTag() {
        let files = [DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/data.xyz"), relativePath: "data.xyz")]

        let result = MarkdownAssembler.assemble(
            files: files,
            contentProvider: { _ in "raw" },
            options: options
        )

        XCTAssertTrue(result.markdown.contains("```data.xyz\nraw\n```"))
    }

    func testContentWithBackticksEscalatesFenceLength() {
        let files = [
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/doc.md"), relativePath: "doc.md"),
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/code.swift"), relativePath: "code.swift"),
        ]

        let result = MarkdownAssembler.assemble(
            files: files,
            contentProvider: { file in
                file.relativePath == "doc.md" ? "```\ninner fence\n```" : "let y = 2"
            },
            options: options
        )

        XCTAssertTrue(result.markdown.contains("````markdown:doc.md\n```\ninner fence\n```\n````"))
        XCTAssertTrue(result.markdown.contains("````swift:code.swift\nlet y = 2\n````"))
    }

    func testUnreadableFilesAreCountedAsSkipped() {
        let files = [
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/a.swift"), relativePath: "a.swift"),
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/b.bin"), relativePath: "b.bin"),
        ]

        let result = MarkdownAssembler.assemble(
            files: files,
            contentProvider: { file in
                file.relativePath == "a.swift" ? "let a = 0" : nil
            },
            options: options
        )

        XCTAssertEqual(result.skippedCount, 1)
        XCTAssertFalse(result.markdown.contains("b.bin"))
    }

    func testFileListSectionListsRelativePathsInOrder() {
        let files = [
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/z.swift"), relativePath: "z.swift"),
            DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/a/b.swift"), relativePath: "a/b.swift"),
        ]
        var listOptions = options
        listOptions.includeFileList = true

        let result = MarkdownAssembler.assemble(
            files: files.sorted { $0.relativePath < $1.relativePath },
            contentProvider: { _ in "" },
            options: listOptions
        )

        XCTAssertTrue(result.markdown.contains("## Files\n\n- a/b.swift\n- z.swift"))
    }

    func testPrefixAndSuffixSupportPlaceholders() {
        var decoratedOptions = options
        decoratedOptions.prefix = "# {folderName}\n{fileCount} files, generated {date}"
        decoratedOptions.suffix = "End of {folderName}"

        let files = [DiscoveredFile(url: URL(fileURLWithPath: "/tmp/DemoProject/x.swift"), relativePath: "x.swift")]
        let fixedDate = Date(timeIntervalSince1970: 1_704_067_200)

        let result = MarkdownAssembler.assemble(
            files: files,
            contentProvider: { _ in "x" },
            options: decoratedOptions,
            now: fixedDate
        )

        XCTAssertTrue(result.markdown.hasPrefix("# DemoProject\n1 files, generated 2024-01-01"))
        XCTAssertTrue(result.markdown.hasSuffix("End of DemoProject"))
    }

    func testEmptyPrefixSuffixAndNoFilesProduceEmptyOutput() {
        let result = MarkdownAssembler.assemble(files: [], contentProvider: { _ in nil }, options: options)
        XCTAssertEqual(result.markdown, "")
        XCTAssertEqual(result.skippedCount, 0)
    }

    func testLongestRunOfBackticks() {
        XCTAssertEqual(MarkdownAssembler.longestRunOfBackticks("no ticks"), 0)
        XCTAssertEqual(MarkdownAssembler.longestRunOfBackticks("a ` b `` c ``` d"), 3)
        XCTAssertEqual(MarkdownAssembler.longestRunOfBackticks("````"), 4)
    }

    func testSubstitutePlaceholdersReplacesAllTokens() {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let output = MarkdownAssembler.substitutePlaceholders(
            in: "{folderName}: {fileCount} on {date}",
            folderName: "MyApp",
            fileCount: 12,
            date: date
        )

        XCTAssertEqual(output, "MyApp: 12 on 2024-01-01")
    }
}
