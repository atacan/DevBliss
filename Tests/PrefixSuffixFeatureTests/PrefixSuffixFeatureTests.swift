import ComposableArchitecture
import XCTest

@testable import PrefixSuffixFeature
import SharedModels

@MainActor
final class PrefixSuffixFeatureTests: XCTestCase {
    func testInitWithUserDefaults() async {
        let inputPrefixReplace = "prefix to replace"
        let ephemeral = UserDefaults.Dependency.ephemeral()

        // first time the view is created
        let store = TestStore(initialState: PrefixSuffixReducer.State()) {
            PrefixSuffixReducer()
        } withDependencies: {
            $0.userDefaults = ephemeral
        }

        // user changed the text field
        await store.send(.binding(.set(\.$configuration.prefixReplace, inputPrefixReplace))) {
            $0.configuration.prefixReplace = inputPrefixReplace
        }

        // second time the view is created with default init arguments
        let newStore = TestStore(initialState: PrefixSuffixReducer.State()) {
            PrefixSuffixReducer()
        } withDependencies: {
            $0.userDefaults = ephemeral
        }

        // user didn't change anything. the state is restored from the UserDefaults
        XCTAssertEqual(newStore.state.configuration.prefixReplace, inputPrefixReplace)
    }
}
