import Dependencies
import XCTest

@testable import JwtDebuggerFeature

@MainActor
final class JwtDebuggerFeatureTests: XCTestCase {
    func testEditingTwoPartTokenAfterDecodeErrorDoesNotCrashOrDecode() async {
        await withDependencies {
            $0.jwtDebugger.inspect = { token, _ in
                XCTAssertEqual(token, "header.payload")
                throw JwtDebuggerError.invalidPartCount(2)
            }
        } operation: {
            let model = JwtDebuggerModel()
            model.$inputText.withLock { $0 = "header.payload" }
            model.onInputChanged()

            XCTAssertEqual(model.inputText, "header.payload")

            model.decodeButtonTouched()

            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isDecoding)
            XCTAssertNil(model.inspection)
            XCTAssertEqual(model.errorMessage, "JWT must have 3 parts, got 2")

            model.$inputText.withLock { $0 = "header." }
            model.onInputChanged()

            XCTAssertNil(model.errorMessage)
            XCTAssertNil(model.inspection)
            XCTAssertEqual(model.inputText, "header.")
        }
    }
    
    func testDecodeSuccessfulUpdatesInspectionAndOutput() async {
        await withDependencies {
            $0.jwtDebugger.inspect = { token, _ in
                XCTAssertEqual(token, "header.payload.signature")
                return JwtDebugInspection(
                    headerJSON: "{\"alg\":\"HS256\"}",
                    payloadJSON: "{\"sub\":\"me\"}",
                    signature: "signature",
                    algorithm: "HS256",
                    claims: [JwtClaimItem(title: "sub", value: "me")],
                    verification: .invalid
                )
            }
        } operation: {
            let model = JwtDebuggerModel()
            model.$inputText.withLock { $0 = "header.payload.signature" }

            model.decodeButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.isDecoding, false)
            XCTAssertNil(model.errorMessage)
            XCTAssertNotNil(model.inspection)
            XCTAssertEqual(model.outputText, "{\"sub\":\"me\"}")
        }
    }
    
    func testAutoDetectSkipsDecodeForInvalidJwtAndClearsState() async {
        await withDependencies {
            $0.jwtDebugger.inspect = { _, _ in
                XCTFail("Auto-detect should not run for non-jwt text")
                throw JwtDebuggerError.invalidJSON
            }
        } operation: {
            let model = JwtDebuggerModel()
            model.autoDetect = true
            model.$inputText.withLock { $0 = "hello" }
            model.onInputChanged()

            XCTAssertNil(model.inspection)
            XCTAssertNil(model.errorMessage)
        }
    }
    
    func testInspectRejectsTwoPartToken() async {
        do {
            _ = try await JwtDebuggerClient.liveValue.inspect("header.payload", nil)
            XCTFail("Expected a two-part token to be rejected")
        } catch let error as JwtDebuggerError {
            XCTAssertEqual(error, .invalidPartCount(2))
            XCTAssertEqual(error.localizedDescription, "JWT must have 3 parts, got 2")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
