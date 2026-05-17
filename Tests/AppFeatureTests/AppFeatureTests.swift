import XCTest

@testable import AppFeature
import SharedModels

@MainActor
final class AppFeatureTests: XCTestCase {
    func testSendOutputToOtherToolSwitchesToSelectedToolAndInjectsInput() {
        let model = AppModel()

        model.sendOutputToOtherTool("let view = Text(\"Hi\")", .jsonPretty)

        XCTAssertEqual(model.currentTool, .jsonPretty)
        guard case let .jsonPretty(jsonPrettyModel) = model.destination else {
            XCTFail("Expected JSON formatter destination")
            return
        }
        XCTAssertEqual(jsonPrettyModel.inputText, "let view = Text(\"Hi\")")
    }
}
