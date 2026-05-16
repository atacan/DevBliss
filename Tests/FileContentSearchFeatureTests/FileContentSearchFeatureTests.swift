import Dependencies
import Foundation
import XCTest

@testable import FileContentSearchFeature

@MainActor
final class FileContentSearchFeatureTests: XCTestCase {
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
