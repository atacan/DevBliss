import BlissTheme
import ColorConverterClient
import ComposableArchitecture
import InputOutput
import SharedModels
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Reducer
public struct ColorConverterReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.colorConverterIO) public var storage = ToolIOStorage()
        var output: OutputEditorReducer.State
        var uppercaseHex: Bool = true
        var includeAlpha: Bool = false
        var result: ColorConversionResult?
        var errorMessage: String?

        public var input: String {
            get { storage.input }
            set { $storage.withLock { $0.input = newValue } }
        }

        public init() {
            self.output = OutputEditorReducer.State(text: _storage.projectedValue.output)
        }

        public init(input: String, output: String = "") {
            self._storage = Shared(wrappedValue: ToolIOStorage(input: input, output: output), .colorConverterIO)
            self.output = OutputEditorReducer.State(text: _storage.projectedValue.output)
        }

        public var outputText: String {
            output.text
        }

        var config: ColorConverterConfig {
            ColorConverterConfig(uppercaseHex: uppercaseHex, includeAlpha: includeAlpha)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case conversionResponse(TaskResult<ColorConversionResult>)
        case output(OutputEditorReducer.Action)
    }

    @Dependency(\.colorConverter) var colorConverter
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .convertButtonTouched:
                state.errorMessage = nil
                let input = state.input
                let config = state.config
                return .run { [colorConverter] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try colorConverter.convert(input, config)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(result)):
                state.result = result
                return state.output.updateText(result.summary)
                    .map { Action.output($0) }

            case let .conversionResponse(.failure(error)):
                state.result = nil
                state.errorMessage = error.localizedDescription
                return state.output.updateText(error.localizedDescription)
                    .map { Action.output($0) }

            case .output:
                return .none
            }
        }

        Scope(state: \.output, action: \.output) {
            OutputEditorReducer()
        }
    }
}

public struct ColorConverterView: View {
    @Bindable var store: StoreOf<ColorConverterReducer>

    public init(store: StoreOf<ColorConverterReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Enter a color value (hex or rgb)", text: $store.input)
                    .blissTextField()
                    .onSubmit {
                        store.send(.convertButtonTouched)
                    }

                LoadingButton("Convert", isLoading: false) {
                    store.send(.convertButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Convert (⌘ Return)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Options")
                    Toggle("Uppercase hex", isOn: $store.uppercaseHex)
                        .toggleStyle(.checkbox)

                    Toggle("Include alpha", isOn: $store.includeAlpha)
                        .toggleStyle(.checkbox)

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            Divider()

            ScrollView {
                if let result = store.result {
                    VStack(spacing: 16) {
                        ColorPreviewCard(result: result)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 16)], spacing: 16) {
                            ResultCard(title: "HEX", value: result.hex, icon: "number")
                            ResultCard(title: "RGB", value: result.rgb, icon: "circle.grid.3x3")
                            ResultCard(title: "RGBA", value: result.rgba, icon: "circle.grid.3x3.fill")
                            ResultCard(title: "HSL", value: result.hsl, icon: "circle.lefthalf.filled")
                            ResultCard(title: "HSLA", value: result.hsla, icon: "circle.lefthalf.filled.righthalf.striped.horizontal")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                } else {
                    Text("Enter a color to convert")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                }
            }

            Divider()

            OutputEditorView(
                store: store.scope(state: \.output, action: \.output),
                title: "Summary"
            )
            .frame(minHeight: 180)
        }
    }
}

private struct ColorPreviewCard: View {
    let result: ColorConversionResult

    var body: some View {
        let color = Color(.sRGB, red: result.red, green: result.green, blue: result.blue, opacity: result.alpha)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal)
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

struct ColorConverterView_Previews: PreviewProvider {
    static var previews: some View {
        ColorConverterView(store: .init(initialState: .init()) { ColorConverterReducer() })
    }
}
