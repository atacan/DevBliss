import ComposableArchitecture
import SharedModels
import XCTest

@testable import SwiftPrettyFeature

@MainActor
final class SwiftPrettyFeatureTests: XCTestCase {
    func testLockwoodConfigBinding() async {
        let config = "some config"

        let store = TestStore(initialState: SwiftPrettyReducer.State()) {
            SwiftPrettyReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        // user changed the lockwood config text field
        await store.send(.lockwoodConfig(.binding(.set(\.text, config)))) {
            $0.lockwoodConfig.text = config
        }

        // verify the state was updated
        XCTAssertEqual(store.state.lockwoodConfig.text, config)
    }
}
