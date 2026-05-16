import RegexMatchesFeature
import XCTest

final class RegexMatchesFeatureTests: XCTestCase {
    func testDefaultModelInitializes() {
        let model = RegexMatchesModel()
        XCTAssertEqual(model.regexPattern, "")
        XCTAssertFalse(model.isConversionRequestInFlight)
    }
}
