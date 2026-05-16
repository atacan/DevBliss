import Dependencies
import SharedModels
import XCTest

@testable import UrlEncodeFeature

@MainActor
final class UrlEncodeFeatureTests: XCTestCase {
    func testEncodeFlowPersistsOutputAndUpdatesResult() async {
        await withDependencies {
            $0.urlEncode = UrlEncodeClient.testValue
        } operation: {
            let model = UrlEncodeModel()
            model.autoDetect = true
            model.encodeMode = .formData
            model.updateInput("hello")

            model.convertButtonTouched()

            XCTAssertEqual(model.direction, .encode)
            XCTAssertEqual(model.result, "encoded_hello")
            XCTAssertEqual(model.outputText, "encoded_hello")
            XCTAssertNil(model.errorMessage)
        }
    }

    func testDecodeFlowProducesExpectedText() {
        withDependencies {
            $0.urlEncode = UrlEncodeClient(
                encode: { _, _ in "ignore" },
                decode: { input, _ in "decoded_\(input)" },
                looksEncoded: { input in input.contains("%") }
            )
        } operation: {
            let model = UrlEncodeModel()
            model.direction = .decode
            model.updateInput("abc%20")

            model.convertButtonTouched()

            XCTAssertEqual(model.result, "decoded_abc%20")
            XCTAssertEqual(model.outputText, "decoded_abc%20")
            XCTAssertNil(model.errorMessage)
        }
    }

    func testUseAsInputSwapsDirection() {
        let model = UrlEncodeModel()
        model.result = "result"
        model.direction = .encode

        model.useAsInputButtonTouched()

        XCTAssertEqual(model.inputText, "result")
        XCTAssertEqual(model.result, "")
        XCTAssertEqual(model.direction, .decode)
    }

    func testAutoDetectSwitchesDirection() {
        let model = UrlEncodeModel()
        model.autoDetect = true

        model.updateInput("https%3A%2F%2Fexample.com")

        XCTAssertEqual(model.direction, .encode)
        XCTAssertEqual(model.inputText, "https%3A%2F%2Fexample.com")
    }

    func testEmptyInputShowsError() {
        let model = UrlEncodeModel()
        model.updateInput("   ")

        model.convertButtonTouched()

        XCTAssertEqual(model.errorMessage, "Please enter a value")
        XCTAssertEqual(model.result, "")
    }
}
