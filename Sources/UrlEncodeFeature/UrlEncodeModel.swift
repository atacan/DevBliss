import Foundation
import Sharing
import Dependencies

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
public final class UrlEncodeModel {
    @ObservationIgnored
    @Shared(.toolInput("urlEncode"))
    public var inputText: String = ""

    @ObservationIgnored
    @Shared(.toolOutput("urlEncode"))
    public var outputText: String = ""

    public var direction: UrlEncodeDirection = .encode
    public var encodeMode: UrlEncodeMode = .rfc3986
    public var autoDetect: Bool = true
    public var decodePlusAsSpace: Bool = true
    public var result: String = ""
    public var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.urlEncode) private var urlEncode

    public init() {}

    public init(
        input: String,
        output: String = ""
    ) {
        self._inputText = Shared(wrappedValue: input, .toolInput("urlEncode"))
        self._outputText = Shared(wrappedValue: output, .toolOutput("urlEncode"))
    }

    public func updateInput(_ newText: String) {
        inputText = newText
        if autoDetect {
            let input = newText.trimmingCharacters(in: .whitespacesAndNewlines)
            if urlEncode.looksEncoded(input) {
                direction = .decode
            } else if !input.isEmpty {
                direction = .encode
            }
        }
    }

    public func updateInputText(_ newText: String) {
        updateInput(newText)
    }

    public func convertButtonTouched() {
        errorMessage = nil
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Please enter a value"
            result = ""
            return
        }

        switch direction {
        case .encode:
            result = urlEncode.encode(input, encodeMode)
        case .decode:
            result = urlEncode.decode(input, decodePlusAsSpace)
        }

        outputText = result
    }

    public func useAsInputButtonTouched() {
        guard !result.isEmpty else { return }
        inputText = result
        result = ""
        direction = direction == .encode ? .decode : .encode
    }

    public func copyResultButtonTouched() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        #else
        UIPasteboard.general.string = result
        #endif
    }

    public func setInputTextFromOtherTool(_ text: String) {
        inputText = text
    }
}
