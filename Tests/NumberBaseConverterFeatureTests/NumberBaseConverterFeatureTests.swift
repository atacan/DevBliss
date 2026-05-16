import Dependencies
import XCTest

@testable import NumberBaseConverterFeature

@MainActor
final class NumberBaseConverterFeatureTests: XCTestCase {
    func testConvertSuccessProducesAllBases() async {
        await withDependencies {
            $0.numberBaseConverter = NumberBaseConverterClient(
                convert: { input, _ in
                    XCTAssertEqual(input, "10")
                    return NumberBaseResult(
                        binary: "1010",
                        octal: "12",
                        decimal: "10",
                        hex: "a"
                    )
                }
            )
        } operation: {
            let model = NumberBaseConverterModel()
            model.$inputText.withLock { $0 = "10" }
            model.setFromBase(.decimal)

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "Binary: 1010\nOctal: 12\nDecimal: 10\nHex: a")
            XCTAssertNil(model.errorMessage)
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testConvertShowsErrorAndStoresErrorMessage() async {
        enum StubError: LocalizedError {
            case failed
            var errorDescription: String? { "bad number" }
        }

        await withDependencies {
            $0.numberBaseConverter = NumberBaseConverterClient(
                convert: { _, _ in
                    throw StubError.failed
                }
            )
        } operation: {
            let model = NumberBaseConverterModel()
            model.$inputText.withLock { $0 = "zzz" }

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.errorMessage, "bad number")
            XCTAssertEqual(model.outputText, "bad number")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testCancelStopsConversion() async {
        await withDependencies {
            $0.numberBaseConverter = NumberBaseConverterClient(
                convert: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return NumberBaseResult(
                        binary: "1010",
                        octal: "12",
                        decimal: "10",
                        hex: "a"
                    )
                }
            )
        } operation: {
            let model = NumberBaseConverterModel()
            model.$inputText.withLock { $0 = "10" }
            model.convertButtonTouched()
            model.cancel()

            try? await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
