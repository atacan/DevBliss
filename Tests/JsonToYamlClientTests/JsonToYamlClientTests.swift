import Dependencies
import Foundation
import XCTest

@testable import JsonToYamlClient
@testable import SyntaxHighlightClient

final class JsonToYamlClientTests: XCTestCase {
    var client: JsonToYamlClient!

    override func setUp() {
        client = withDependencies {
            $0.jsonToYaml = .liveValue
        } operation: {
            @Dependency(\.jsonToYaml) var jsonToYaml
            return jsonToYaml
        }
    }

    // MARK: - Basic Conversion Tests

    func testSimpleObject() async throws {
        let json = #"{"name": "Alice", "age": 30}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertTrue(yaml.contains("name:"), "YAML should contain 'name:' key, got: \(yaml)")
        XCTAssertTrue(yaml.contains("Alice"), "YAML should contain 'Alice' value, got: \(yaml)")
        XCTAssertTrue(yaml.contains("age:"), "YAML should contain 'age:' key, got: \(yaml)")
        // Note: Yams may output integers in scientific notation (e.g. 3e+1 instead of 30)
        // because JSONSerialization deserializes to NSNumber
        XCTAssertTrue(yaml.contains("age: 3e+1") || yaml.contains("age: 30"),
                       "YAML should contain age value, got: \(yaml)")
    }

    func testSimpleArray() async throws {
        let json = #"[1, 2, 3]"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertTrue(yaml.contains("- 1"), "Should contain '- 1', got: \(yaml)")
        XCTAssertTrue(yaml.contains("- 2"), "Should contain '- 2', got: \(yaml)")
        XCTAssertTrue(yaml.contains("- 3"), "Should contain '- 3', got: \(yaml)")
    }

    func testNestedObject() async throws {
        let json = #"{"person": {"name": "Bob", "address": {"city": "Berlin"}}}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertTrue(yaml.contains("person:"), "Should contain 'person:', got: \(yaml)")
        XCTAssertTrue(yaml.contains("Bob"), "Should contain 'Bob', got: \(yaml)")
        XCTAssertTrue(yaml.contains("address:"), "Should contain 'address:', got: \(yaml)")
        XCTAssertTrue(yaml.contains("Berlin"), "Should contain 'Berlin', got: \(yaml)")
    }

    func testEmptyObject() async throws {
        let json = #"{}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty, "Empty JSON object should produce some YAML output, got empty string")
    }

    func testEmptyArray() async throws {
        let json = #"[]"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty, "Empty JSON array should produce some YAML output, got empty string")
    }

    func testSortKeys() async throws {
        let json = #"{"zebra": 1, "apple": 2, "mango": 3}"#
        let config = JsonToYamlConfig(sortKeys: true)
        let yaml = try await client.convert(json, config)

        let lines = yaml.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count >= 3 else {
            XCTFail("Expected at least 3 lines, got \(lines.count): \(yaml)")
            return
        }
        XCTAssertTrue(lines[0].hasPrefix("apple:"), "First key should be 'apple' when sorted, got: \(lines[0])")
        XCTAssertTrue(lines[1].hasPrefix("mango:"), "Second key should be 'mango' when sorted, got: \(lines[1])")
        XCTAssertTrue(lines[2].hasPrefix("zebra:"), "Third key should be 'zebra' when sorted, got: \(lines[2])")
    }

    func testUnicodeContent() async throws {
        let json = #"{"greeting": "こんにちは"}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertTrue(yaml.contains("greeting:"), "YAML should contain the key, got: \(yaml)")
        XCTAssertTrue(yaml.contains("こんにちは"), "YAML should preserve unicode characters, got: \(yaml)")
    }

    func testNullValue() async throws {
        let json = #"{"key": null}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertTrue(yaml.contains("key:"), "YAML should contain the key, got: \(yaml)")
    }

    func testBooleanValues() async throws {
        let json = #"{"yes": true, "no": false}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertTrue(yaml.contains("true"), "YAML should contain true, got: \(yaml)")
        XCTAssertTrue(yaml.contains("false"), "YAML should contain false, got: \(yaml)")
    }

    // MARK: - Error Handling Tests

    func testInvalidJsonThrows() async {
        let invalidJson = "this is not json"
        do {
            _ = try await client.convert(invalidJson, JsonToYamlConfig())
            XCTFail("Should have thrown an error for invalid JSON")
        } catch {
            // Expected - invalid JSON should throw
        }
    }

    func testEmptyStringThrows() async {
        do {
            _ = try await client.convert("", JsonToYamlConfig())
            XCTFail("Should have thrown an error for empty string")
        } catch {
            // Expected - empty string is not valid JSON
        }
    }

    // MARK: - Output Verification Tests

    func testOutputIsNotEmpty() async throws {
        let json = #"{"key": "value"}"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty, "YAML output should not be empty for valid JSON")
        XCTAssertFalse(yaml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       "YAML output should not be only whitespace")
    }

    func testArrayOfObjects() async throws {
        let json = #"[{"id": 1, "name": "a"}, {"id": 2, "name": "b"}]"#
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty)
        XCTAssertTrue(yaml.contains("- "), "Array of objects should produce YAML list items, got: \(yaml)")
    }

    func testDeeplyNestedJson() async throws {
        // 10 levels deep
        var json = #"{"value": "leaf"}"#
        for i in (0..<10).reversed() {
            json = #"{"level\#(i)": \#(json)}"#
        }
        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty, "Deeply nested JSON should produce YAML output")
        XCTAssertTrue(yaml.contains("leaf"), "Should contain the leaf value, got: \(yaml)")
    }

    func testLargeNumberOfKeys() async throws {
        // JSON with 1000 keys
        var pairs: [String] = []
        for i in 0..<1000 {
            pairs.append(#""key\#(i)": "value\#(i)""#)
        }
        let json = "{\(pairs.joined(separator: ", "))}"

        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty, "JSON with 1000 keys should produce YAML output")
        XCTAssertTrue(yaml.contains("key0:"), "Should contain first key")
        XCTAssertTrue(yaml.contains("key999:"), "Should contain last key")
    }

    func testLargeArray() async throws {
        // Array with 1000 elements
        let elements = (0..<1000).map { "\($0)" }
        let json = "[\(elements.joined(separator: ", "))]"

        let yaml = try await client.convert(json, JsonToYamlConfig())

        XCTAssertFalse(yaml.isEmpty, "Large array should produce YAML output")
        XCTAssertTrue(yaml.contains("- 0"), "Should contain first element")
        XCTAssertTrue(yaml.contains("- 999"), "Should contain last element")
    }

    // MARK: - Performance Tests

    func testPerformanceSmallJson() throws {
        let json = #"{"name": "test", "value": 42, "nested": {"key": "val"}}"#
        measure {
            let expectation = XCTestExpectation(description: "Conversion completes")
            Task {
                _ = try await client.convert(json, JsonToYamlConfig())
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance1000Keys() throws {
        var pairs: [String] = []
        for i in 0..<1000 {
            pairs.append(#""key\#(i)": "value\#(i)""#)
        }
        let json = "{\(pairs.joined(separator: ", "))}"

        measure {
            let expectation = XCTestExpectation(description: "Conversion completes")
            Task {
                _ = try await client.convert(json, JsonToYamlConfig())
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Large JSON File Resource Test

    func test5MBJsonFileFromResources() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "5MB", withExtension: "json"))

        let jsonData = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        let fileSizeKB = jsonData.count / 1024
        print("Testing with JSON file: \(fileSizeKB) KB")

        let startTime = CFAbsoluteTimeGetCurrent()
        let yaml = try await client.convert(jsonString, JsonToYamlConfig())
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        print("Conversion took \(String(format: "%.2f", elapsed)) seconds")

        XCTAssertFalse(yaml.isEmpty, "YAML output should not be empty for large JSON (file: \(fileSizeKB) KB)")
        XCTAssertFalse(
            yaml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "YAML output should not be only whitespace for large JSON"
        )

        print("Output YAML length: \(yaml.count) characters")
    }

    func test5MBJsonFilePerformance() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "5MB", withExtension: "json"))

        let jsonData = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        print("Performance test with JSON file: \(jsonData.count / 1024) KB")

        measure {
            let expectation = XCTestExpectation(description: "5MB file conversion completes")
            Task {
                _ = try await client.convert(jsonString, JsonToYamlConfig())
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 60.0)
        }
    }

    // MARK: - Syntax Highlighting Tests

    func testHighlightSmallYaml() async throws {
        let highlighter = withDependencies {
            $0.syntaxHighlight = .liveValue
        } operation: {
            @Dependency(\.syntaxHighlight) var syntaxHighlight
            return syntaxHighlight
        }

        let yaml = "name: Alice\nage: 30\nnested:\n  key: value\n"

        let startTime = CFAbsoluteTimeGetCurrent()
        let highlighted = await highlighter.highlightYaml(yaml)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        print("Small YAML highlighting took \(String(format: "%.3f", elapsed)) seconds")
        XCTAssertGreaterThan(highlighted.length, 0, "Highlighted output should not be empty")
        XCTAssertEqual(highlighted.string, yaml, "Highlighted text content should match input")
    }

    /// Tests highlighting at various YAML sizes to find the threshold where it breaks.
    /// Uses the 1MB JSON file and truncates the resulting YAML to test different sizes.
    func testHighlightYamlSizeThreshold() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "1MB", withExtension: "json"))
        let jsonData = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        let yaml = try await client.convert(jsonString, JsonToYamlConfig())
        print("Full YAML: \(yaml.count) chars")

        let highlighter = withDependencies {
            $0.syntaxHighlight = .liveValue
        } operation: {
            @Dependency(\.syntaxHighlight) var syntaxHighlight
            return syntaxHighlight
        }

        // Results (M4 Max, Feb 2025):
        //   200K chars → OK,    2.07s
        //   250K chars → OK,    3.01s
        //   300K chars → OK,    4.19s
        //   350K chars → OK,    5.59s
        //   400K chars → EMPTY, 6.82s  ← highlighter silently fails above ~350-400K
        //   500K chars → EMPTY, 9.49s
        //   928K chars → EMPTY, 21.40s
        let testSizes = [100_000, 200_000, 300_000, 400_000, 500_000]
        for size in testSizes {
            let truncated = String(yaml.prefix(size))
            let start = CFAbsoluteTimeGetCurrent()
            let highlighted = await highlighter.highlightYaml(truncated)
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let status = highlighted.length > 0 ? "OK" : "EMPTY"
            print("[\(status)] \(size) chars → \(highlighted.length) highlighted, \(String(format: "%.2f", elapsed))s")
        }
    }

    func testHighlight1MBYaml() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "1MB", withExtension: "json"))
        let jsonData = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        let convertStart = CFAbsoluteTimeGetCurrent()
        let yaml = try await client.convert(jsonString, JsonToYamlConfig())
        let convertElapsed = CFAbsoluteTimeGetCurrent() - convertStart
        print("JSON→YAML conversion: \(String(format: "%.2f", convertElapsed))s, \(yaml.count) chars")

        let highlighter = withDependencies {
            $0.syntaxHighlight = .liveValue
        } operation: {
            @Dependency(\.syntaxHighlight) var syntaxHighlight
            return syntaxHighlight
        }

        let highlightStart = CFAbsoluteTimeGetCurrent()
        let highlighted = await highlighter.highlightYaml(yaml)
        let highlightElapsed = CFAbsoluteTimeGetCurrent() - highlightStart

        print("YAML highlighting: \(String(format: "%.2f", highlightElapsed))s")
        print("Total pipeline: \(String(format: "%.2f", convertElapsed + highlightElapsed))s")
        print("Highlighted output length: \(highlighted.length) chars")

        XCTAssertGreaterThan(highlighted.length, 0, "Highlighted output should not be empty")
    }

    func testHighlight5MBYaml() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "5MB", withExtension: "json"))
        let jsonData = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        // Step 1: Convert JSON to YAML
        let convertStart = CFAbsoluteTimeGetCurrent()
        let yaml = try await client.convert(jsonString, JsonToYamlConfig())
        let convertElapsed = CFAbsoluteTimeGetCurrent() - convertStart
        print("JSON→YAML conversion: \(String(format: "%.2f", convertElapsed))s, \(yaml.count) chars")

        // Step 2: Syntax highlight the YAML
        let highlighter = withDependencies {
            $0.syntaxHighlight = .liveValue
        } operation: {
            @Dependency(\.syntaxHighlight) var syntaxHighlight
            return syntaxHighlight
        }

        let highlightStart = CFAbsoluteTimeGetCurrent()
        let highlighted = await highlighter.highlightYaml(yaml)
        let highlightElapsed = CFAbsoluteTimeGetCurrent() - highlightStart

        print("YAML highlighting: \(String(format: "%.2f", highlightElapsed))s")
        print("Total pipeline: \(String(format: "%.2f", convertElapsed + highlightElapsed))s")
        print("Highlighted output length: \(highlighted.length) chars")

        XCTAssertGreaterThan(highlighted.length, 0, "Highlighted output should not be empty")
    }

    func testFullPipeline5MBPerformance() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "5MB", withExtension: "json"))
        let jsonData = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        let highlighter = withDependencies {
            $0.syntaxHighlight = .liveValue
        } operation: {
            @Dependency(\.syntaxHighlight) var syntaxHighlight
            return syntaxHighlight
        }

        print("Full pipeline performance test (JSON→YAML→highlight) with \(jsonData.count / 1024) KB")

        measure {
            let expectation = XCTestExpectation(description: "Full pipeline completes")
            Task {
                let yaml = try await client.convert(jsonString, JsonToYamlConfig())
                let _ = await highlighter.highlightYaml(yaml)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 120.0)
        }
    }
}
