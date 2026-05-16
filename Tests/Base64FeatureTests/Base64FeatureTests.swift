import Dependencies
import XCTest

@testable import Base64Feature

@MainActor
final class Base64FeatureTests: XCTestCase {
    func testEncodeModeUsesDependencyAndUpdatesOutput() async {
        let model = Base64Model()
        model.inputText = "hello"
        model.mode = .encode

        model.convertButtonTouched()
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertFalse(model.isConversionRequestInFlight)
        XCTAssertEqual(model.outputText, "aGVsbG8=")
    }

    func testDecodeModeShowsErrorForInvalidBase64() async {
        await withDependencies {
            $0.base64 = Base64Client(
                encode: { input in
                    input.data(using: .utf8).flatMap { $0.base64EncodedString() } ?? ""
                },
                decode: { _, _ in
                    throw Base64Error.invalidBase64
                },
                isValidBase64: { _ in false }
            )
        } operation: {
            let model = Base64Model()
            model.inputText = "not base64"
            model.mode = .decode

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
            XCTAssertEqual(model.outputText, "The input is not valid Base64")
        }
    }

    func testCancelPreventsCompletion() async {
        await withDependencies {
            $0.base64 = Base64Client(
                encode: { input in
                    try await Task.sleep(for: .milliseconds(100))
                    return input
                },
                decode: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return ""
                },
                isValidBase64: { _ in false }
            )
        } operation: {
            let model = Base64Model()
            model.inputText = "hello"

            model.convertButtonTouched()
            model.cancel()

            try? await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
