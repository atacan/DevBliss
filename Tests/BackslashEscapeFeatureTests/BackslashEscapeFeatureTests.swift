import Dependencies
import XCTest

@testable import BackslashEscapeFeature

@MainActor
final class BackslashEscapeFeatureTests: XCTestCase {
    func testEscapeModeConvertsInput() async {
        await withDependencies {
            $0.backslashEscape = .liveValue
        } operation: {
            let model = BackslashEscapeModel()
            model.$inputText.withLock { $0 = "a\nb\\\"" }
            model.setMode(.escape)

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "a\\nb\\\\\\\"")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testUnescapeModeConvertsInput() async {
        await withDependencies {
            $0.backslashEscape = .liveValue
        } operation: {
            let model = BackslashEscapeModel()
            model.$inputText.withLock { $0 = "line1\\nline2" }
            model.setMode(.unescape)

            model.convertButtonTouched()
            try? await Task.sleep(nanoseconds: 10_000_000)

            XCTAssertEqual(model.outputText, "line1\nline2")
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }

    func testUnescapeJSONSingleCharacterEscapes() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert(
            "a\\\"b\\\\c\\/d\\be\\ff\\tg\\nh\\ri\\0j",
            .unescape
        )
        XCTAssertEqual(output, "a\"b\\c/d\u{08}e\u{0C}f\tg\nh\ri\0j")
    }

    func testUnescapeBMPUnicodeEscape() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("\\u00e9", .unescape)
        XCTAssertEqual(output, "é")
    }

    func testUnescapeSurrogatePair() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("\\ud83d\\ude00", .unescape)
        XCTAssertEqual(output, "\u{1F600}")
    }

    func testUnescapeLoneSurrogateIsKeptLiteral() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("x\\ud83dy", .unescape)
        XCTAssertEqual(output, "x\\ud83dy")
    }

    func testUnescapeMalformedUnicodeIsKeptLiteral() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("\\u12g4 \\u12", .unescape)
        XCTAssertEqual(output, "\\u12g4 \\u12")
    }

    func testUnescapeUnknownEscapeIsPreserved() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("a\\qb", .unescape)
        XCTAssertEqual(output, "a\\qb")
    }

    func testUnescapeTrailingBackslashIsKept() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("abc\\", .unescape)
        XCTAssertEqual(output, "abc\\")
    }

    func testUnescapeHexByte() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("\\x41", .unescape)
        XCTAssertEqual(output, "A")
    }

    func testEscapeControlCharactersUseUnicodeEscapes() async throws {
        let output = try await BackslashEscapeClient.liveValue.convert("a\u{01}b\u{08}c\u{0C}d", .escape)
        XCTAssertEqual(output, "a\\u0001b\\bc\\fd")
    }

    func testEscapeThenUnescapeRoundTrips() async throws {
        let original = "quote:\" backslash:\\ newline:\n tab:\t emoji:\u{1F600} accent:é nul:\0"
        let escaped = try await BackslashEscapeClient.liveValue.convert(original, .escape)
        let unescaped = try await BackslashEscapeClient.liveValue.convert(escaped, .unescape)
        XCTAssertEqual(unescaped, original)
    }

    func testCancelStopsConversion() async {
        await withDependencies {
            $0.backslashEscape = BackslashEscapeClient(
                convert: { _, _ in
                    try await Task.sleep(for: .milliseconds(100))
                    return "late-result"
                }
            )
        } operation: {
            let model = BackslashEscapeModel()
            model.$inputText.withLock { $0 = "a" }
            model.convertButtonTouched()
            model.cancel()

            try? await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertFalse(model.isConversionRequestInFlight)
        }
    }
}
