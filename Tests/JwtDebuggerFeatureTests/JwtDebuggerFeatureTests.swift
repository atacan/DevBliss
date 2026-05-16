import ComposableArchitecture
import Foundation
import JwtDebuggerClient
import XCTest

@testable import JwtDebuggerFeature

@MainActor
final class JwtDebuggerFeatureTests: XCTestCase {
    func testEditingTwoPartTokenAfterDecodeErrorDoesNotCrashOrDecode() async {
        let store = TestStore(initialState: JwtDebuggerReducer.State()) {
            JwtDebuggerReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
            $0.jwtDebugger.inspect = { token, _ in
                XCTAssertEqual(token, "header.payload")
                throw JwtDebuggerError.invalidPartCount(2)
            }
        }
        store.exhaustivity = .off

        await store.send(.input(.binding(.set(\.text, NSMutableAttributedString(string: "header.payload")))))
        XCTAssertEqual(store.state.input.rawText, "header.payload")
        XCTAssertEqual(store.state.input.text.string, "header.payload")

        await store.send(.decodeButtonTouched) {
            $0.isDecoding = true
        }

        await store.receive(.decodeResponse(.failure(JwtDebuggerError.invalidPartCount(2)))) {
            $0.isDecoding = false
            $0.inspection = nil
            $0.errorMessage = "JWT must have 3 parts, got 2"
        }

        await store.send(.input(.binding(.set(\.text, NSMutableAttributedString(string: "header.")))))
        XCTAssertNil(store.state.errorMessage)
        XCTAssertNil(store.state.inspection)
        XCTAssertEqual(store.state.input.rawText, "header.")
        XCTAssertEqual(store.state.input.text.string, "header.")
    }
}
