import Dependencies
import XCTest

@testable import HashGeneratorFeature

@MainActor
final class HashGeneratorFeatureTests: XCTestCase {
    func testConvertUpdatesOutputTextOnSuccess() async {
        await withDependencies {
            $0.hashGenerator = HashGeneratorClient(
                hashes: { input, _ in
                    XCTAssertEqual(input, "dev")
                    return HashGeneratorResult(
                        md5: "abc",
                        sha1: "def",
                        sha256: "123",
                        sha384: "456",
                        sha512: "789"
                    )
                }
            )
        } operation: {
            let model = HashGeneratorModel()
            model.$inputText.withLock { $0 = "dev" }
            model.setUppercase(false)

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "MD5: abc\nSHA1: def\nSHA256: 123\nSHA384: 456\nSHA512: 789")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testConvertRespectsUppercaseConfig() async {
        await withDependencies {
            $0.hashGenerator = HashGeneratorClient(
                hashes: { _, config in
                    XCTAssertTrue(config.uppercase)
                    return HashGeneratorResult(
                        md5: "a",
                        sha1: "b",
                        sha256: "c",
                        sha384: "d",
                        sha512: "e"
                    )
                }
            )
        } operation: {
            let model = HashGeneratorModel()
            model.$inputText.withLock { $0 = "abc" }
            model.setUppercase(true)

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "MD5: a\nSHA1: b\nSHA256: c\nSHA384: d\nSHA512: e")
        }
    }

    func testConvertShowsDependencyErrorMessageInOutput() async {
        enum StubError: LocalizedError {
            case failed
            var errorDescription: String? { "hash failed" }
        }

        await withDependencies {
            $0.hashGenerator = HashGeneratorClient(
                hashes: { _, _ in
                    throw StubError.failed
                }
            )
        } operation: {
            let model = HashGeneratorModel()
            model.$inputText.withLock { $0 = "abc" }

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "hash failed")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testCancelPreventsInFlightCompletion() async {
        await withDependencies {
            $0.hashGenerator = HashGeneratorClient(
                hashes: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return HashGeneratorResult(
                        md5: "x",
                        sha1: "y",
                        sha256: "z",
                        sha384: "w",
                        sha512: "v"
                    )
                }
            )
        } operation: {
            let model = HashGeneratorModel()
            model.$inputText.withLock { $0 = "abc" }

            model.convertButtonTouched()
            model.cancel()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
