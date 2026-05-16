import Dependencies
import Sharing
import SharedModels
import SwiftUI
import Observation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct StringInspectorResult: Equatable, Codable {
    public var characters: Int
    public var unicodeScalars: Int
    public var words: Int
    public var lines: Int
    public var bytesUTF8: Int
    public var whitespace: Int
    public var isASCII: Bool
    public var isEmpty: Bool

    public init(
        characters: Int,
        unicodeScalars: Int,
        words: Int,
        lines: Int,
        bytesUTF8: Int,
        whitespace: Int,
        isASCII: Bool,
        isEmpty: Bool
    ) {
        self.characters = characters
        self.unicodeScalars = unicodeScalars
        self.words = words
        self.lines = lines
        self.bytesUTF8 = bytesUTF8
        self.whitespace = whitespace
        self.isASCII = isASCII
        self.isEmpty = isEmpty
    }
}

public struct StringInspectorClient {
    public var inspect: @Sendable (String) -> StringInspectorResult

    public init(inspect: @escaping @Sendable (String) -> StringInspectorResult) {
        self.inspect = inspect
    }

    public static let liveValue = Self(
        inspect: { input in
            let words = input.split { $0.isWhitespace }.count
            let lines = input.split(omittingEmptySubsequences: false, whereSeparator: \\.isNewline).count
            let whitespace = input.filter { $0.isWhitespace }.count
            let isASCII = input.unicodeScalars.allSatisfy { $0.value <= 0x7F }

            return StringInspectorResult(
                characters: input.count,
                unicodeScalars: input.unicodeScalars.count,
                words: words,
                lines: input.isEmpty ? 0 : lines,
                bytesUTF8: input.utf8.count,
                whitespace: whitespace,
                isASCII: isASCII,
                isEmpty: input.isEmpty
            )
        }
    )
}

extension StringInspectorClient: DependencyKey {}

extension DependencyValues {
    public var stringInspector: StringInspectorClient {
        get { self[StringInspectorClient.self] }
        set { self[StringInspectorClient.self] = newValue }
    }
}

@MainActor
@Observable
public final class StringInspectorModel {
    @ObservationIgnored
    @Shared(.toolInput("stringInspector")) public var inputText = \"\"

    @ObservationIgnored
    @Shared(.toolOutput("stringInspector")) public var outputText = \"\"

    @ObservationIgnored
    @Dependency(\\.stringInspector) private var stringInspector

    public var result: StringInspectorResult

    public init(inputText: String = \"\") {
        let input = Shared(wrappedValue: inputText, .toolInput(\"stringInspector\"))
        let output = Shared(wrappedValue: \"\", .toolOutput(\"stringInspector\"))
        self._inputText = input
        self._outputText = output
        self.result = stringInspector.inspect(inputText)
    }

    public func setInputText(_ text: String) {
        inputText = text
        result = stringInspector.inspect(text)
    }
}

public struct StringInspectorModelView: View {
    @Bindable var model: StringInspectorModel

    public init(model: StringInspectorModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: Binding(get: { model.inputText }, set: { model.setInputText($0) }))
                .font(.system(.body, design: .monospaced))
                .padding(12)

            Divider()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 16)], spacing: 16) {
                    resultCard(title: \"Characters\", value: \"\\(model.result.characters)\", icon: \"textformat\")
                    resultCard(title: \"Unicode Scalars\", value: \"\\(model.result.unicodeScalars)\", icon: \"number\")
                    resultCard(title: \"Words\", value: \"\\(model.result.words)\", icon: \"text.word.spacing\")
                    resultCard(title: \"Lines\", value: \"\\(model.result.lines)\", icon: \"list.bullet\")
                    resultCard(title: \"UTF-8 Bytes\", value: \"\\(model.result.bytesUTF8)\", icon: \"tray.full\")
                    resultCard(title: \"Whitespace\", value: \"\\(model.result.whitespace)\", icon: \"space\")
                    resultCard(title: \"ASCII\", value: model.result.isASCII ? \"Yes\" : \"No\", icon: \"character\")
                    resultCard(title: \"Empty\", value: model.result.isEmpty ? \"Yes\" : \"No\", icon: model.result.isEmpty ? \"circle\" : \"circle.fill\")
                }
                .padding()
            }
        }
    }

    private func resultCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(.accent)
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    #else
                    UIPasteboard.general.string = value
                    #endif
                } label: {
                    Image(systemName: \"doc.on.doc\")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct StringInspectorModelView_Previews: PreviewProvider {
    static var previews: some View {
        StringInspectorModelView(model: .init())
    }
}
