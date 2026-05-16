import Dependencies
import XCTest

@testable import TextCaseConverterFeature

@MainActor
final class TextCaseConverterFeatureTests: XCTestCase {
    func testConvertButtonTouchedUpdatesOutputOnSuccess() async {
        await withDependencies {
            $0.textCaseConverter = TextCaseConverterClient(
                convert: { input, textSeperator, sourceCase, targetCase in
                    XCTAssertEqual(input, "foo bar")
                    XCTAssertEqual(textSeperator, .newLine)
                    XCTAssertEqual(sourceCase, .kebab)
                    XCTAssertEqual(targetCase, .snake)
                    return "converted"
                }
            )
        } operation: {
            let model = TextCaseConverterModel()
            model.inputText = "foo bar"
            model.setSourceCase(.kebab)
            model.setTargetCase(.snake)
            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "converted")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testConvertButtonTouchedStoresErrorMessageInOutput() async {
        enum StubError: LocalizedError {
            case conversionFailed

            var errorDescription: String? {
                "conversion failed"
            }
        }

        await withDependencies {
            $0.textCaseConverter = TextCaseConverterClient(
                convert: { _, _, _, _ in
                    throw StubError.conversionFailed
                }
            )
        } operation: {
            let model = TextCaseConverterModel()
            model.inputText = "bad-input"
            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "conversion failed")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testCancelStopsConversion() async {
        await withDependencies {
            $0.textCaseConverter = TextCaseConverterClient(
                convert: { _, _, _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return "late-result"
                }
            )
        } operation: {
            let model = TextCaseConverterModel()
            model.inputText = "foo"
            model.convertButtonTouched()
            model.cancel()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
