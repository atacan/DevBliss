import BlissTheme
import ComposableArchitecture
import InputOutput
import SharedModels
import StringInspectorClient
import SwiftUI

@Reducer
public struct StringInspectorReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.stringInspectorIO) public var storage = ToolIOStorage()
        var input: InputEditorReducer.State
        var result: StringInspectorResult

        public init() {
            let sharedStorage = Shared(wrappedValue: ToolIOStorage(), .stringInspectorIO)
            self._storage = sharedStorage
            self.input = InputEditorReducer.State(text: sharedStorage.input)
            self.result = StringInspectorClient.liveValue.inspect(sharedStorage.wrappedValue.input)
        }

        public init(inputText: String) {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: inputText, output: ""), .stringInspectorIO)
            self.input = InputEditorReducer.State(text: _storage.projectedValue.input)
            self.result = StringInspectorClient.liveValue.inspect(inputText)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case input(InputEditorReducer.Action)
    }

    @Dependency(\.stringInspector) var stringInspector

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .input:
                state.result = stringInspector.inspect(state.input.text)
                return .none
            }
        }

        Scope(state: \.input, action: \.input) {
            InputEditorReducer()
        }
    }
}

public struct StringInspectorView: View {
    @Bindable var store: StoreOf<StringInspectorReducer>

    public init(store: StoreOf<StringInspectorReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            InputEditorView(store: store.scope(state: \.input, action: \.input))

            Divider()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 16)], spacing: 16) {
                    ResultCard(title: "Characters", value: "\(store.result.characters)", icon: "textformat")
                    ResultCard(title: "Unicode Scalars", value: "\(store.result.unicodeScalars)", icon: "number")
                    ResultCard(title: "Words", value: "\(store.result.words)", icon: "text.word.spacing")
                    ResultCard(title: "Lines", value: "\(store.result.lines)", icon: "list.bullet")
                    ResultCard(title: "UTF-8 Bytes", value: "\(store.result.bytesUTF8)", icon: "tray.full")
                    ResultCard(title: "Whitespace", value: "\(store.result.whitespace)", icon: "space")
                    ResultCard(title: "ASCII", value: store.result.isASCII ? "Yes" : "No", icon: "character")
                    ResultCard(title: "Empty", value: store.result.isEmpty ? "Yes" : "No", icon: store.result.isEmpty ? "circle" : "circle.fill")
                }
                .padding()
            }
        }
    }
}

private struct ResultCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    #else
                    UIPasteboard.general.string = value
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
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

struct StringInspectorView_Previews: PreviewProvider {
    static var previews: some View {
        StringInspectorView(store: .init(initialState: .init()) { StringInspectorReducer() })
    }
}
