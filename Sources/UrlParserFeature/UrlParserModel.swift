import Foundation
import Sharing
import Dependencies
import SharedModels

@MainActor
@Observable
public final class UrlParserModel {
    @ObservationIgnored
    @Shared(.toolInput("urlParser"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("urlParser"))
    public var outputText = ""

    public var result: UrlParseResult?
    public var autoDetect: Bool = true
    public var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.urlParser) private var urlParser

    public var input: String {
        get { inputText }
        set { inputText = newValue }
    }

    public init() {}

    public init(input: String) {
        self._inputText = Shared(wrappedValue: input, .toolInput("urlParser"))
    }

    public func parseInputChanged(_ newValue: String) {
        inputText = newValue
        guard autoDetect, shouldAutoParse else { return }
        parseButtonTouched()
    }

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldAutoParse: Bool {
        urlParser.shouldAutoParse(trimmedInput)
    }

    public func parseButtonTouched() {
        errorMessage = nil
        do {
            result = try urlParser.parse(trimmedInput)
            if let result {
                outputText = result.queryJSON
            } else {
                outputText = ""
            }
        } catch {
            result = nil
            errorMessage = error.localizedDescription
            outputText = ""
        }
    }

    public func setInputTextFromOtherTool(_ text: String) {
        inputText = text
        if autoDetect, shouldAutoParse {
            parseButtonTouched()
        }
    }
}
