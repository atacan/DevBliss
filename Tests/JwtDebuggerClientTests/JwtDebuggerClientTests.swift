import XCTest

@testable import JwtDebuggerClient

final class JwtDebuggerClientTests: XCTestCase {
    func testInspectRejectsTwoPartToken() async throws {
        do {
            _ = try await JwtDebuggerClient.liveValue.inspect("header.payload", nil)
            XCTFail("Expected a two-part token to be rejected")
        } catch let error as JwtDebuggerError {
            XCTAssertEqual(error, .invalidPartCount(2))
            XCTAssertEqual(error.localizedDescription, "JWT must have 3 parts, got 2")
        }
    }
}
