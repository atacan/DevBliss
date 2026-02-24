import ComposableArchitecture
import FileContentSearchClient
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

        let store = TestStore(
            initialState: FileContentSearchReducer.State(
                searchOptions: .init(),
                output: .init(text: ""),
                foundFiles: [foundFile]
            )
        ) {
            FileContentSearchReducer()
        } withDependencies: {
            $0.filesClient.read = { url in
                XCTAssertEqual(url, fileURL)
                return "let value = 42"
            }
        }

        await store.send(.binding(.set(\.selectedFiles, [foundFile.id]))) {
            $0.selectedFiles = [foundFile.id]
            $0.isReadingFile = true
        }

        await store.receive(.selectedFileContentRead(.success("let value = 42"))) {
            $0.isReadingFile = false
            $0.output.$text.withLock { $0 = "let value = 42" }
        }
    }
}
