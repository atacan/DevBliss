import Dependencies
import XCTest

@testable import BackslashEscapeFeature

@MainActor
final class BackslashEscapeFeatureTests: XCTestCase {
    func testEscapeModeConvertsInput() async {
        let model = BackslashEscapeModel()
        model.inputText = "a\nb\\\""
        model.setMode(.escape)

        model.convertButtonTouched()
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertEqual(model.outputText, "a\\nb\\\\\"")
        XCTAssertFalse(model.isConversionRequestInFlight)
    }

    func testUnescapeModeConvertsInput() async {
        let model = BackslashEscapeModel()
        model.inputText = "line1\\nline2"
        model.setMode(.unescape)

        model.convertButtonTouched()
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertEqual(model.outputText, "line1\nline2")
        XCTAssertFalse(model.isConversionRequestInFlight)
    }

    func testCancelStopsConversion() async {
        await withDependencies {
            $0.backslashEscape = BackslashEscapeClient(
                convert: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return "late-result"
                }
            )
        } operation: {
            let model = BackslashEscapeModel()
            model.inputText = "a"
            model.convertButtonTouched()
            model.cancel()

            try? await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
