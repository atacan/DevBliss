import Dependencies
import XCTest

@testable import StringDiffFeature

@MainActor
final class StringDiffFeatureTests: XCTestCase {
    func testDiffComputationUpdatesChangesWhenInputsChange() async {
        await withDependencies {
            $0.stringDiff = .liveValue
        } operation: {
            let model = StringDiffModel()
            model.convertButtonTouched()

            model.setOldText("hello")
            model.setNewText("world")

            while model.isComputing {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }

            XCTAssertFalse(model.changes.isEmpty)
        }
    }

    func testChangeDiffTypeCancelsAndRecomputes() async {
        await withDependencies {
            $0.stringDiff = .liveValue
        } operation: {
            let model = StringDiffModel(oldText: "hello world", newText: "hello swift world")
            model.convertButtonTouched()
            model.setDiffType(.words)

            while model.isComputing {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }

            XCTAssertEqual(model.diffType, .words)
            XCTAssertFalse(model.isComputing)
        }
    }

    func testDefaultInitKeepsStoredTextKeys() {
        let model = StringDiffModel()
        XCTAssertEqual(model.oldText, "")
        XCTAssertEqual(model.newText, "")
        XCTAssertEqual(model.diffType, .lines)
        XCTAssertFalse(model.isComputing)
    }
}
