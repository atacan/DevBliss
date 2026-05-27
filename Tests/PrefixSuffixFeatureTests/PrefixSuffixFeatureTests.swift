import XCTest
import Dependencies
@testable import PrefixSuffixFeature

@MainActor
final class PrefixSuffixFeatureTests: XCTestCase {
    func testPrefixSuffixModelConvertsUsingCurrentConfiguration() async {
        await withDependencies {
            $0.prefixSuffix = .liveValue
        } operation: {
            let model = PrefixSuffixModel()
            model.$inputText.withLock { $0 = "foobar" }
            model.$prefixReplace.withLock { $0 = "foo" }
            model.$prefixReplaceWith.withLock { $0 = "bar" }
            model.$suffixAdd.withLock { $0 = "!" }
            model.$trimWhiteSpace.withLock { $0 = true }

            model.convertButtonTouched()

            while model.isConversionRequestInFlight {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }

            XCTAssertEqual(model.outputText, "barbar!")
        }
    }

    func testPrefixSuffixToggleCanBeChangedFromViewState() {
        let model = PrefixSuffixModel()
        XCTAssertEqual(model.trimWhiteSpace, true)
        model.$trimWhiteSpace.withLock { $0 = false }
        XCTAssertEqual(model.trimWhiteSpace, false)
    }
}
