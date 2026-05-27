import Dependencies
import SharedModels
import XCTest

@testable import UrlParserFeature

@MainActor
final class UrlParserFeatureTests: XCTestCase {
    func testParseButtonUpdatesResultAndOutputText() async {
        await withDependencies {
            $0.urlParser = .init(
                parse: { input in
                    UrlParseResult(
                        scheme: "https",
                        host: "example.com",
                        port: "",
                        path: "/",
                        fileName: "",
                        fragment: "",
                        queryJSON: "{\"q\":\"value\"}"
                    )
                },
                shouldAutoParse: { _ in false }
            )
        } operation: {
            let model = UrlParserModel()
            model.$inputText.withLock { $0 = "https://example.com/?q=value" }

            model.parseButtonTouched()

            XCTAssertEqual(model.result?.host, "example.com")
            XCTAssertEqual(model.outputText, "{\"q\":\"value\"}")
            XCTAssertNil(model.errorMessage)
        }
    }

    func testParseErrorReportsMessage() {
        withDependencies {
            $0.urlParser = .init(
                parse: { _ in throw UrlParserError.invalidURL },
                shouldAutoParse: { _ in false }
            )
        } operation: {
            let model = UrlParserModel()
            model.$inputText.withLock { $0 = "not a url" }

            model.parseButtonTouched()

            XCTAssertNotNil(model.errorMessage)
            XCTAssertNil(model.result)
        }
    }

    func testAutoDetectParsesWhenInputChanges() {
        let model = UrlParserModel()
        model.autoDetect = true

        withDependencies {
            $0.urlParser = .init(
                parse: { _ in
                    UrlParseResult(
                        scheme: "https",
                        host: "example.com",
                        port: "",
                        path: "/",
                        fileName: "",
                        fragment: "",
                        queryJSON: "{}"
                    )
                },
                shouldAutoParse: { _ in true }
            )
        } operation: {
            model.parseInputChanged("https://example.com?a=1&b=2")
            XCTAssertNotNil(model.result)
            XCTAssertNil(model.errorMessage)
            XCTAssertEqual(model.outputText, "{}")
        }
    }
}
