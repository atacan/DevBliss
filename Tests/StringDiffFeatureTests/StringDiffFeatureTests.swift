import Dependencies
import XCTest

@testable import StringDiffFeature

@MainActor
final class StringDiffFeatureTests: XCTestCase {
    func testDiffComputationUpdatesChangesWhenInputsChange() async {
        await withDependencies {
            $0.stringDiff = StringDiffClient(
                diff: { type, old, new in
                    guard type == .lines else { return [] }
                    if old.isEmpty || new.isEmpty { return [] }
                    if old == new { return [] }
                    return [
                        Change(
                            type: .insert,
                            value: new,
                            oldLine: nil,
                            newLine: 1
                        )
                    ]
                }
            )
        } operation: {
            let model = StringDiffModel()
            model.convertButtonTouched()

            model.setOldText("hello")
            model.setNewText("world")

            while model.isComputing {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }

            XCTAssertEqual(model.changes.count, 1)
            XCTAssertEqual(model.changes.first?.value, "world")
        }
    }

    func testChangeDiffTypeCancelsAndRecomputes() async {
        await withDependencies {
            $0.stringDiff = StringDiffClient(
                diff: { type, _, _ in
                    if type == .words {
                        [
                            Change(type: .equal, value: "word-level", oldLine: 1, newLine: 1)
                        ]
                    } else {
                        []
                    }
                }
            )
        } operation: {
            let model = StringDiffModel(oldText: "a", newText: "a")
            model.convertButtonTouched()
            model.setDiffType(.words)

            while model.isComputing {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }

            XCTAssertEqual(model.changes.count, 1)
            XCTAssertEqual(model.changes.first?.type, .equal)
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
