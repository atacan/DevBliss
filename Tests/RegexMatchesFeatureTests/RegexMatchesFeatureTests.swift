import RegexMatchesFeature
import XCTest

@MainActor
final class RegexMatchesFeatureTests: XCTestCase {
    func testDefaultModelInitializes() {
        let model = RegexMatchesModel()
        XCTAssertEqual(model.regexPattern, "")
        XCTAssertFalse(model.isConversionRequestInFlight)
    }
}
