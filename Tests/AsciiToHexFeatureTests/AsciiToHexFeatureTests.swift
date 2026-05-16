import Dependencies
import XCTest

@testable import AsciiToHexFeature

@MainActor
final class AsciiToHexFeatureTests: XCTestCase {
    func testConvertUppercaseHexSuccess() async {
        await withDependencies {
            $0.asciiToHex = AsciiToHexClient(
                convert: { input, config in
                    return input == "ab" ? "6162" : ""
                }
            )
        } operation: {
            let model = AsciiToHexModel()
            model.setUppercase(true)
            model.setSeparator(.space)
            model.inputText = "ab"

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "6162")
        }
    }

    func testConvertSeparatorAndLowercase() async {
        await withDependencies {
            $0.asciiToHex = AsciiToHexClient(
                convert: { input, _ in
                    return input.split(separator: " ").map { _ in "aa" }.joined(separator: " ")
                }
            )
        } operation: {
            let model = AsciiToHexModel()
            model.setUppercase(false)
            model.setSeparator(.space)
            model.inputText = "a b"

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "aa aa")
        }
    }

    func testConvertShowsErrorOnFailure() async {
        enum StubError: Error, LocalizedError {
            case failed
            var errorDescription: String? { "convert failed" }
        }

        await withDependencies {
            $0.asciiToHex = AsciiToHexClient(
                convert: { _, _ in
                    throw StubError.failed
                }
            )
        } operation: {
            let model = AsciiToHexModel()
            model.inputText = "bad"

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "convert failed")
        }
    }

    func testCancelPreventsCompletion() async {
        await withDependencies {
            $0.asciiToHex = AsciiToHexClient(
                convert: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return "late"
                }
            )
        } operation: {
            let model = AsciiToHexModel()
            model.inputText = "ab"
            model.convertButtonTouched()
            model.cancel()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
