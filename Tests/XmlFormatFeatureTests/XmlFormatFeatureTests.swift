import Dependencies
import XCTest

@testable import XmlFormatFeature

@MainActor
final class XmlFormatFeatureTests: XCTestCase {
    func testBeautifySuccessUsesDependencyAndUpdatesOutput() async {
        await withDependencies {
            $0.xmlFormat = XmlFormatClient(
                format: { input, mode in
                    if mode == .beautify {
                        return "<beautified>\(input)</beautified>"
                    }
                    return "unexpected:\(input)"
                }
            )
        } operation: {
            let model = XmlFormatModel()
            model.$inputText.withLock { $0 = "<x/>" }
            model.mode = .beautify

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.isConversionRequestInFlight, false)
            XCTAssertEqual(model.outputText, "<beautified><x/></beautified>")
        }
    }

    func testMinifySuccessUpdatesModeOutput() async {
        await withDependencies {
            $0.xmlFormat = XmlFormatClient(
                format: { input, mode in
                    if mode == .minify {
                        return "<minified>\(input.replacingOccurrences(of: " ", with: ""))</minified>"
                    }
                    return "unexpected:\(input)"
                }
            )
        } operation: {
            let model = XmlFormatModel()
            model.$inputText.withLock { $0 = "<x> 1 </x>" }
            model.mode = .minify

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "<minified><x>1</x></minified>")
        }
    }

    func testFailureShowsErrorOutputText() async {
        enum StubError: LocalizedError {
            case failed
            var errorDescription: String? { "format failed" }
        }

        await withDependencies {
            $0.xmlFormat = XmlFormatClient(
                format: { _, _ in
                    throw StubError.failed
                }
            )
        } operation: {
            let model = XmlFormatModel()
            model.$inputText.withLock { $0 = "<x/>" }

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
            XCTAssertEqual(model.outputText, "format failed")
        }
    }

    func testCancelStopsInFlightTask() async {
        await withDependencies {
            $0.xmlFormat = XmlFormatClient(
                format: { _input, _mode in
                    try await Task.sleep(for: .milliseconds(100))
                    return ""
                }
            )
        } operation: {
            let model = XmlFormatModel()
            model.$inputText.withLock { $0 = "<x/>" }

            model.convertButtonTouched()
            model.cancel()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
