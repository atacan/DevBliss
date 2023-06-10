import Dependencies

public struct TextCaseConverterClient {
    public var convert: @Sendable (String, WordGroupSeperator, WordGroupCase, WordGroupCase) async throws -> String
}

extension TextCaseConverterClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            convert: { text, textSeperator, sourceCase, targetCase in
                text
                    .split(separator: textSeperator.rawValue)
                    .map { wordGroup -> String in
                        targetCase.textStyleType.init(
                            components:
                            sourceCase.textStyleType
                                .init(content: String(wordGroup).trimmingCharacters(in: .whitespaces))
                                .split()
                        )
                        .content
                    }
                    .joined(separator: String(textSeperator.rawValue))
            }
        )
    }
}

extension DependencyValues {
    public var textCaseConverter: TextCaseConverterClient.Value {
        get { self[TextCaseConverterClient.self] }
        set { self[TextCaseConverterClient.self] = newValue }
    }
}
