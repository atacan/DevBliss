import ComposableArchitecture
import Foundation
import XCTest

@testable import HtmlToSwiftFeature

@MainActor
final class HtmlToSwiftFeatureTests: XCTestCase {
    func testGetConvertedCode() async {
        let highlightedResult = NSAttributedString(string: "Binary Birds")

        let store = TestStore(initialState: HtmlToSwiftReducer.State()) {
            HtmlToSwiftReducer()
        } withDependencies: {
            $0.htmlToSwift.binaryBirds = { _, _ in "Binary Birds" }
            $0.syntaxHighlight.highlightSwift = { _ in highlightedResult }
        }

        await store.send(.convertButtonTouched) {
            $0.isConversionRequestInFlight = true
        }

        await store.receive(.conversionResponse(.success(highlightedResult))) {
            $0.inputOutput.output.text = NSMutableAttributedString(attributedString: highlightedResult)
            $0.inputOutput.output.$rawText.withLock { $0 = "Binary Birds" }
            $0.isConversionRequestInFlight = false
        }
    }
}
