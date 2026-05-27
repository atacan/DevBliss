import Dependencies
import Foundation
import XCTest

@testable import FileContentSearchFeature

@MainActor
final class FileContentSearchFeatureTests: XCTestCase {
    func testSearchDisplaysFoundFileCount() async {
        await withDependencies {
            $0.fileContentSearch.run = { _ in
                [
                    FoundFile(
                        fileURL: URL(fileURLWithPath: "/tmp/first.swift"),
                        lineNumbers: [1],
                        modifiedTime: Date(timeIntervalSince1970: 0),
                        gitUsername: nil
                    ),
                    FoundFile(
                        fileURL: URL(fileURLWithPath: "/tmp/second.swift"),
                        lineNumbers: [2],
                        modifiedTime: Date(timeIntervalSince1970: 0),
                        gitUsername: nil
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
            modifiedTime: Date(timeIntervalSince1970: 0),
            gitUsername: nil
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
