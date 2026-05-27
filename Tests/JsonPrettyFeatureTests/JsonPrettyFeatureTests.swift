import Dependencies
import Foundation
import XCTest

@testable import JsonPrettyFeature

@MainActor
final class JsonPrettyFeatureTests: XCTestCase {
    func testConvertStoresRawAndAttributedOutput() async {
        await withDependencies {
            $0.jsonPretty = JsonPrettyClient { input in
                NSAttributedString(string: "formatted \(input)")
            }
        } operation: {
            let model = JsonPrettyModel()
            model.$inputText.withLock { $0 = "{}" }

            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertEqual(model.outputText, "formatted {}")
            XCTAssertEqual(model.outputAttributedText.string, "formatted {}")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testEditingAttributedOutputSyncsRawOutputText() {
        let model = JsonPrettyModel(input: "", output: "initial")

        model.setOutputAttributedText(NSMutableAttributedString(string: "edited output"))

        XCTAssertEqual(model.outputText, "edited output")
        XCTAssertEqual(model.outputAttributedText.string, "edited output")
    }
}
