import Dependencies
import Foundation
import XCTest

@testable import FileContentSearchFeature

@MainActor
final class FileContentSearchFeatureTests: XCTestCase {
    func testLiveSearchFindsMatchesAndRespectsOptions() async throws {
        let root = try makeFixtureTree()
        defer { try? FileManager.default.removeItem(at: root) }
        let client = FileContentSearchClient.liveValue

        func foundPaths(_ options: SearchOptions) async throws -> Set<String> {
            Set(try await client.run(options).map(\.fileURL.lastPathComponent))
        }

        // Defaults: no hidden files, packages and subdirectories included.
        let defaultOptions = SearchOptions(searchTerm: "needle", searchFolder: root.path)
        let defaultPaths = try await foundPaths(defaultOptions)
        XCTAssertEqual(defaultPaths, ["top.txt", "deep.txt", "inside.txt"])
        let topLevelResult = try await client.run(defaultOptions).first { $0.fileURL.lastPathComponent == "top.txt" }
        XCTAssertEqual(topLevelResult?.lineNumbers, [1, 2])

        // Hidden files are searched only when the option is on.
        var withHidden = defaultOptions
        withHidden.searchHiddenFiles = true
        let withHiddenPaths = try await foundPaths(withHidden)
        XCTAssertEqual(withHiddenPaths, ["top.txt", "deep.txt", "inside.txt", ".hidden.txt"])

        // Sub-directories are skipped when the option is off.
        var topOnly = defaultOptions
        topOnly.searchInsideSubdirectories = false
        let topOnlyPaths = try await foundPaths(topOnly)
        XCTAssertEqual(topOnlyPaths, ["top.txt"])

        // Package contents are skipped when the option is off.
        var skipPackages = defaultOptions
        skipPackages.searchInsidePackages = false
        let skipPackagesPaths = try await foundPaths(skipPackages)
        XCTAssertEqual(skipPackagesPaths, ["top.txt", "deep.txt"])
    }

    /// Creates a fixture tree:
    ///
    ///     root/
    ///       top.txt              (matches on lines 1 and 2)
    ///       .hidden.txt
    ///       nested/deep.txt
    ///       MyApp.app/inside.txt
    private func makeFixtureTree() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FileContentSearchFixtures-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for relativePath in ["top.txt", ".hidden.txt", "nested/deep.txt", "MyApp.app/inside.txt"] {
            let url = root.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "needle needle\nneedle again\nnothing here".write(to: url, atomically: true, encoding: .utf8)
        }
        return root
    }

    func testSearchDisplaysFoundFileCount() async {
        await withDependencies {
            $0.fileContentSearch.run = { _ in
                [
                    FoundFile(
                        fileURL: URL(fileURLWithPath: "/tmp/first.swift"),
                        lineNumbers: [1],
                        modifiedTime: Date(timeIntervalSince1970: 0)
                    ),
                    FoundFile(
                        fileURL: URL(fileURLWithPath: "/tmp/second.swift"),
                        lineNumbers: [2],
                        modifiedTime: Date(timeIntervalSince1970: 0)
                    )
                ]
            }
        } operation: {
            let model = FileContentSearchModel()
            model.searchButtonTapped()
            for _ in 0..<50 {
                if !model.isSearching {
                    break
                }
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
            XCTAssertEqual(model.outputText, "2 files found.")
        }
    }

    func testSelectingSingleFoundFileReadsAndDisplaysContent() async {
        let fileURL = URL(fileURLWithPath: "/tmp/sample.swift")
        let foundFile = FoundFile(
            fileURL: fileURL,
            lineNumbers: [3],
            modifiedTime: Date(timeIntervalSince1970: 0)
        )

        await withDependencies {
            $0.filesClient.read = { url in
                XCTAssertEqual(url, fileURL)
                return "let value = 42"
            }
        } operation: {
            let model = FileContentSearchModel(foundFiles: [foundFile])
            model.setSelectedFiles([foundFile.id])
            for _ in 0..<50 {
                if !model.isReadingFile {
                    break
                }
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
            XCTAssertEqual(model.outputText, "let value = 42")
        }
    }
}
