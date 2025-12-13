import ComposableArchitecture
import SharedModels
import XCTest

@testable import PrefixSuffixFeature

@MainActor
final class PrefixSuffixFeatureTests: XCTestCase {
    func testPrefixConfigBinding() async {
        let inputPrefixReplace = "prefix to replace"

        let store = TestStore(initialState: PrefixSuffixReducer.State()) {
            PrefixSuffixReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        // user changed the prefix replacement text field
        await store.send(.binding(.set(\.configuration.prefixReplace, inputPrefixReplace))) {
            $0.configuration.prefixReplace = inputPrefixReplace
        }

        // verify the state was updated
        XCTAssertEqual(store.state.configuration.prefixReplace, inputPrefixReplace)
    }
}
