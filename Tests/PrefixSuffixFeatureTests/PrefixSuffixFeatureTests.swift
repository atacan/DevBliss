import XCTest
@testable import PrefixSuffixFeature

@MainActor
final class PrefixSuffixFeatureTests: XCTestCase {
    func testPrefixSuffixModelConvertsUsingCurrentConfiguration() async {
        let model = PrefixSuffixModel()
        model.inputText = "foobar"
        model.prefixReplace = "foo"
        model.prefixReplaceWith = "bar"
        model.suffixAdd = "!"
        model.trimWhiteSpace = true

        model.convertButtonTouched()

        while model.isConversionRequestInFlight {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(model.outputText, "barbar!")
    }

    func testPrefixSuffixToggleCanBeChangedFromViewState() {
        let model = PrefixSuffixModel()
        XCTAssertEqual(model.trimWhiteSpace, true)
        model.trimWhiteSpace = false
        XCTAssertEqual(model.trimWhiteSpace, false)
    }
}
