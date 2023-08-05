import Dependencies
import XCTest

@testable import PrefixSuffixClient

class PrefixSuffixClientTests: XCTestCase {
    @Dependency(\.prefixSuffix) var prefixSuffixClient

    func testConversionWithoutWhiteSpaceLiveValue() async throws {
        let config = PrefixSuffixConfig(
            prefixReplace: "let",
            prefixReplaceWith: "var",
            prefixAdd: "@State ",
            suffixReplace: "?",
            suffixReplaceWith: "",
            suffixAdd: " = .init()",
            trimWhiteSpace: false
        )
        let input = """
                let fluentTimeTrigger: FluentTimestampTrigger?
                let childrenKeyPath: String?
              let name: String let fluentDataType: FluentDataType let isOptional: Bool let optionalSuffix: String
            """
        let output = """
                @State var fluentTimeTrigger: FluentTimestampTrigger = .init()
                @State var childrenKeyPath: String = .init()
              @State var name: String let fluentDataType: FluentDataType let isOptional: Bool let optionalSuffix: String = .init()
            """

        try await withDependencies {
            $0.prefixSuffix = .liveValue
        } operation: {
            let result = try await self.prefixSuffixClient.convert(input, config)
            XCTAssertEqual(result, output)
        }
    }

    func testConversionWithWhiteSpaceLiveValue() async throws {
        let config = PrefixSuffixConfig(
            prefixReplace: "let",
            prefixReplaceWith: "var",
            prefixAdd: "@State ",
            suffixReplace: "?",
            suffixReplaceWith: "",
            suffixAdd: " = .init()",
            trimWhiteSpace: true
        )
        let input = """
                let fluentTimeTrigger: FluentTimestampTrigger?
                let childrenKeyPath: String?
              let name: String let fluentDataType: FluentDataType let isOptional: Bool let optionalSuffix: String
            """
        let output = """
            @State var fluentTimeTrigger: FluentTimestampTrigger = .init()
            @State var childrenKeyPath: String = .init()
            @State var name: String let fluentDataType: FluentDataType let isOptional: Bool let optionalSuffix: String = .init()
            """

        try await withDependencies {
            $0.prefixSuffix = .liveValue
        } operation: {
            let result = try await self.prefixSuffixClient.convert(input, config)
            XCTAssertEqual(result, output)
        }
    }
}
