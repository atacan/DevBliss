import BlissTheme
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct UrlEncodeView: View {
    @Bindable var model: UrlEncodeModel

    public init(model: UrlEncodeModel) {
        self.model = model
    }

    private var inputField: some View {
        TextField("Enter text to encode/decode", text: Binding(
            get: { model.inputText },
            set: { model.updateInput($0) }
        ))
        .blissTextField()
        .onSubmit {
            model.convertButtonTouched()
        }
    }

    private var convertButton: some View {
        LoadingButton("Convert", isLoading: false) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (Command Return)")
        .disabled(model.inputText.isEmpty)
    }

    private var directionPicker: some View {
        Picker("Mode", selection: $model.direction) {
            ForEach(UrlEncodeDirection.allCases) { direction in
                Text(direction.rawValue)
                    .tag(direction)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var autoDetectToggle: some View {
        Toggle("Auto-detect", isOn: $model.autoDetect)
            .help("Automatically detect if input looks URL-encoded and switch to Decode mode")
    }

    private var encodeModePicker: some View {
        Picker("Encode Mode", selection: $model.encodeMode) {
            ForEach(UrlEncodeMode.allCases) { mode in
                Text(mode.rawValue)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .disabled(model.direction == .decode)
    }

    private var decodePlusToggle: some View {
        Toggle("+ as space", isOn: $model.decodePlusAsSpace)
            .help("Decode + characters as spaces (for form data)")
            .disabled(model.direction == .encode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            #if os(iOS)
            VStack(spacing: 10) {
                inputField
                HStack(spacing: 12) {
                    convertButton
                }
                directionPicker
                HStack(spacing: 16) {
                    autoDetectToggle
                    Spacer()
                }
                HStack {
                    Text("Encode")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    encodeModePicker
                }
                HStack(spacing: 16) {
                    decodePlusToggle
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #else
            HStack(spacing: 12) {
                inputField
                convertButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    directionPicker
                        .frame(width: 160)

                    autoDetectToggle
                        .toggleStyle(.checkbox)
                        .gridCellColumns(2)
                }

                GridRow {
                    ConfigLabel("Encode")
                    encodeModePicker
                        .frame(width: 160)

                    ConfigLabel("Decode")
                    decodePlusToggle
                        .toggleStyle(.checkbox)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #endif

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Result")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(model.result.isEmpty ? "Result will appear here" : model.result)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(model.result.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        #if os(macOS)
                        .background(ThemeColor.Background.textBackground)
                        #else
                        .background(Color(uiColor: .secondarySystemBackground))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                #if os(macOS)
                                .stroke(ThemeColor.Background.separator, lineWidth: 1)
                                #else
                                .stroke(Color(uiColor: .separator), lineWidth: 1)
                                #endif
                        )

                    Button {
                        model.copyResultButtonTouched()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.result.isEmpty)
                    .help("Copy result to clipboard")

                    Button {
                        model.useAsInputButtonTouched()
                    } label: {
                        Label("Use as Input", systemImage: "arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.result.isEmpty)
                    .help("Use result as new input")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Spacer()
        }
    }
}

public typealias UrlEncodeModelView = UrlEncodeView

struct UrlEncodeView_Previews: PreviewProvider {
    static var previews: some View {
        UrlEncodeView(model: .init())
    }
}

