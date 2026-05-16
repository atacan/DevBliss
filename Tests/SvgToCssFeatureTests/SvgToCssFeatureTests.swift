import XCTest

import Dependencies
@testable import SvgToCssFeature

@MainActor
final class SvgToCssFeatureTests: XCTestCase {
    func testConvertButtonTouchedWrapsCss() async {
        let model = SvgToCssModel()
        model.inputText = "<svg xmlns=\"x\"/>"
        model.includeDataPrefix = true
        model.wrapWithCss = true

        model.convertButtonTouched()
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(model.outputText.hasPrefix("background-image: url(\"data:image/svg+xml;utf8,"))
        XCTAssertFalse(model.isConversionRequestInFlight)
    }

    func testConvertShowsErrorMessage() async {
        let model = SvgToCssModel()
        model.inputText = "   \n"

        model.convertButtonTouched()
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertFalse(model.isConversionRequestInFlight)
        XCTAssertEqual(model.outputText, "Paste SVG markup to convert")
    }

    func testCancelStopsConversion() async {
        await withDependencies {
            $0.svgToCss = SvgToCssClient(
                convert: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return "background-image: url(\"data:image/svg+xml;utf8,<svg>\");"
                }
            )
        } operation: {
            let model = SvgToCssModel()
            model.inputText = "<svg/>"
            model.convertButtonTouched()
            model.cancel()

            try? await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
