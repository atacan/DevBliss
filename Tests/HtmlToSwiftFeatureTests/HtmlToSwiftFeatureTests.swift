import Dependencies
import Foundation
import XCTest

@testable import HtmlToSwiftFeature

@MainActor
final class HtmlToSwiftFeatureTests: XCTestCase {
    func testGetConvertedCode() async {
        await withDependencies {
            $0.htmlToSwift = HtmlToSwiftClient(
                binaryBirds: { _, _ in "Binary Birds" },
                pointfreeco: { _, _ in "should not be used" }
            )
            $0.userDefaults = .standard
        } operation: {
            let model = HtmlToSwiftModel()
            model.$inputText.withLock { $0 = "<html><body></body></html>" }
            model.dsl = .binaryBirds
            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertEqual(model.outputText, "Binary Birds")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testUsesPointFreeOutput() async {
        await withDependencies {
            $0.htmlToSwift = HtmlToSwiftClient(
                binaryBirds: { _, _ in "wrong" },
                pointfreeco: { _, _ in "Point-Free Swift" }
            )
            $0.userDefaults = .standard
        } operation: {
            let model = HtmlToSwiftModel()
            model.$inputText.withLock { $0 = "<html><body></body></html>" }
            model.dsl = .pointFree
            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertEqual(model.outputText, "Point-Free Swift")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testHighlightsConvertedSwiftOutput() async {
        await withDependencies {
            $0.htmlToSwift = HtmlToSwiftClient(
                binaryBirds: { _, _ in "Text(\"Hello\")" },
                pointfreeco: { _, _ in "wrong" }
            )
            $0.syntaxHighlight.highlightSwift = { swiftCode in
                NSAttributedString(string: "highlighted: \(swiftCode)")
            }
            $0.userDefaults = .standard
        } operation: {
            let model = HtmlToSwiftModel()
            model.dsl = .binaryBirds
            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(50))
            XCTAssertEqual(model.outputText, "Text(\"Hello\")")
            XCTAssertEqual(model.outputAttributedText.string, "highlighted: Text(\"Hello\")")
        }
    }

    func testLargeConvertedSwiftOutputSkipsHighlighting() async {
        let largeOutput = String(repeating: "a", count: 100_001)

        await withDependencies {
            $0.htmlToSwift = HtmlToSwiftClient(
                binaryBirds: { _, _ in largeOutput },
                pointfreeco: { _, _ in "wrong" }
            )
            $0.syntaxHighlight.highlightSwift = { swiftCode in
                NSAttributedString(string: "highlighted: \(swiftCode)")
            }
            $0.userDefaults = .standard
        } operation: {
            let model = HtmlToSwiftModel()
            model.dsl = .binaryBirds
            model.convertButtonTouched()

            try? await Task.sleep(for: .milliseconds(50))
            XCTAssertEqual(model.outputText, largeOutput)
            XCTAssertEqual(model.outputAttributedText.string, largeOutput)
        }
    }

    func testEditingAttributedOutputSyncsRawOutputText() {
        withDependencies {
            $0.userDefaults = .standard
        } operation: {
            let model = HtmlToSwiftModel(input: "", output: "initial")

            model.setOutputAttributedText(NSMutableAttributedString(string: "edited output"))

            XCTAssertEqual(model.outputText, "edited output")
            XCTAssertEqual(model.outputAttributedText.string, "edited output")
        }
    }
}
