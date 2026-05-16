import Dependencies
import Foundation
import XCTest

@testable import HtmlToSwiftFeature

@MainActor
final class HtmlToSwiftFeatureTests: XCTestCase {
    func testGetConvertedCode() async {
        await withDependencies {
            $0.htmlToSwift = HtmlToSwiftClient(
                binaryBirds: { _, _ in "Binary Birds" },
                pointfreeco: { _, _ in "should not be used" }
            )
        } operation: {
            let model = HtmlToSwiftModel()
            model.$inputText.withLock { $0 = "<html><body></body></html>" }
            model.dsl = .binaryBirds
            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertEqual(model.outputText, "Binary Birds")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testUsesPointFreeOutput() async {
        await withDependencies {
            $0.htmlToSwift = HtmlToSwiftClient(
                binaryBirds: { _, _ in "wrong" },
                pointfreeco: { _, _ in "Point-Free Swift" }
            )
        } operation: {
            let model = HtmlToSwiftModel()
            model.$inputText.withLock { $0 = "<html><body></body></html>" }
            model.dsl = .pointFree
            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertEqual(model.outputText, "Point-Free Swift")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
