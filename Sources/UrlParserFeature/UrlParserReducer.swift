import BlissTheme
import ComposableArchitecture
import SharedModels
import SwiftUI
import UrlParserClient

@Reducer
public struct UrlParserReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.urlParserIO) public var storage = ToolIOStorage()
        var result: UrlParseResult?
        var autoDetect: Bool = true
        var errorMessage: String?

        public var input: String {
            get { storage.input }
            set { $storage.withLock { $0.input = newValue } }
        }

        public init() {
        }

        public init(input: String) {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: ""), .urlParserIO)
        }

        public var outputText: String {
            result?.queryJSON ?? ""
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case parseButtonTouched
    }

    @Dependency(\.urlParser) var urlParser

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.input):
                state.errorMessage = nil

                if state.autoDetect, urlParser.shouldAutoParse(state.input) {
                    return parse(state: &state)
                }
                return .none

            case .binding:
                return .none

            case .parseButtonTouched:
                state.errorMessage = nil
                return parse(state: &state)
            }
        }
    }

    private func parse(state: inout State) -> Effect<Action> {
        do {
            state.result = try urlParser.parse(state.input)
            return .none
        } catch {
            state.result = nil
            state.errorMessage = error.localizedDescription
            return .none
        }
    }
}

public struct UrlParserView: View {
    @Bindable var store: StoreOf<UrlParserReducer>

    public init(store: StoreOf<UrlParserReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Enter URL", text: $store.input)
                    .blissTextField()
                    .onSubmit {
                        store.send(.parseButtonTouched)
                    }

                LoadingButton("Parse", isLoading: false) {
                    store.send(.parseButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Parse (⌘ Return)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
//                    ConfigLabel("Options")
                    Toggle("Auto-detect", isOn: $store.autoDetect)
                        .toggleStyle(.checkbox)
                        .help("Automatically parse when URL includes multiple query items")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            if let result = store.result {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 16)], spacing: 16) {
                        ResultCard(title: "Protocol", value: result.scheme, icon: "chevron.left.forwardslash.chevron.right")
                        ResultCard(title: "Host", value: result.host, icon: "globe")
                        ResultCard(title: "Port", value: result.port.isEmpty ? "-" : result.port, icon: "number")
                        ResultCard(title: "Path", value: result.path.isEmpty ? "/" : result.path, icon: "folder")
                        ResultCard(title: "File", value: result.fileName.isEmpty ? "-" : result.fileName, icon: "doc")
                        ResultCard(title: "Fragment", value: result.fragment.isEmpty ? "-" : result.fragment, icon: "number")
                        ResultCard(title: "Query JSON", value: result.queryJSON, icon: "curlybraces")
                    }
                    .padding()
                }
            } else {
                Spacer()
                Text("Enter a URL to see parsed components")
                    .foregroundColor(.secondary)
                Spacer()
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

struct UrlParserView_Previews: PreviewProvider {
    static var previews: some View {
        UrlParserView(store: .init(initialState: .init()) { UrlParserReducer() })
    }
}
