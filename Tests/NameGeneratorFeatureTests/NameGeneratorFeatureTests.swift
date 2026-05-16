import NameGeneratorFeature
import XCTest

final class NameGeneratorFeatureTests: XCTestCase {
    func testDefaultModelInitializes() {
        let model = NameGeneratorModel()

        XCTAssertEqual(model.isConversionRequestInFlight, false)
        XCTAssertEqual(model.generationType, .alternatingVowelsConsonants)
        XCTAssertEqual(model.prefixSuffix.numberOfNames, 10)
        XCTAssertEqual(model.alternatingVowelsConsonants.minLength, 3)
        XCTAssertEqual(model.probabilistic.minLength, 3)
    }
}

