import ComposableArchitecture
import XCTest

import SharedModels
@testable import SwiftPrettyFeature

@MainActor
final class SwiftPrettyFeatureTests: XCTestCase {
    func testInitWithUserDefaults() async {
        let config = "some config"
        let ephemeral = UserDefaults.Dependency.ephemeral()

        // first time the view is created
        let store = TestStore(initialState: SwiftPrettyReducer.State()) {
            SwiftPrettyReducer()
        } withDependencies: {
            $0.userDefaults = ephemeral
        }

        // user changed the text field
        await store.send(.lockwoodConfig(.binding(.set(\.$text, config)))) {
            $0.lockwoodConfig.text = config
        }

        // second time the view is created with default init arguments
        let newStore = TestStore(initialState: SwiftPrettyReducer.State()) {
            SwiftPrettyReducer()
        } withDependencies: {
            $0.userDefaults = ephemeral
        }

        // user didn't change anything. the state is restored from the UserDefaults
        XCTAssertEqual(newStore.state.lockwoodConfig.text, config)
    }
}
