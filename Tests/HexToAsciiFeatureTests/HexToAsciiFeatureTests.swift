import Dependencies
import XCTest

@testable import HexToAsciiFeature

@MainActor
final class HexToAsciiFeatureTests: XCTestCase {
    func testConvertUpdatesOutputOnSuccess() async {
        await withDependencies {
            $0.hexToAscii = HexToAsciiClient(
                convert: { input, _ in
                    "decoded:\(input)"
                }
            )
        } operation: {
            let model = HexToAsciiModel()
            model.inputText = "2a"
            model.setAllowSeparators(true)

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
            XCTAssertEqual(model.outputText, "decoded:2a")
        }
    }

    func testConvertShowsErrorOutputWhenDependencyFails() async {
        enum StubError: Error, LocalizedError {
            case failed
            var errorDescription: String? { "bad data" }
        }

        await withDependencies {
            $0.hexToAscii = HexToAsciiClient(
                convert: { _, _ in
                    throw StubError.failed
                }
            )
        } operation: {
            let model = HexToAsciiModel()
            model.inputText = "zz"

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "bad data")
        }
    }

    func testCancelPreventsCompletion() async {
        await withDependencies {
            $0.hexToAscii = HexToAsciiClient(
                convert: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return "late"
                }
            )
        } operation: {
            let model = HexToAsciiModel()
            model.inputText = "2a"
            model.convertButtonTouched()
            model.cancel()

            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
