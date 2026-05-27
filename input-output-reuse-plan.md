# InputOutput Reuse Plan

## Summary

Use binding-driven reusable views before adding model protocols.

`Binding(model.$sharedProperty)` materially improves the plan because tools can pass their `@Shared` input/output storage directly into reusable UI without writing `setInputText` / `setOutputText` protocol boilerplate. That removes the biggest argument against abstraction, but it points toward a generic view API rather than a protocol-first model hierarchy.

## Recommendation

Build a reusable `StandardTextInputOutputView` in `InputOutput` that composes the primitives we already added:

- `SideBySideView`
- `PaneView`
- `PlainTextEditorView`
- `DroppedTextFileOverlay`
- `PasteFromClipboardButton`
- `CopyToClipboardButton`
- `SaveTextButton`
- `SendToToolButton`

Keep each tool model responsible for conversion, dependencies, settings, and task lifecycle. The reusable view should only own repeated UI layout and editor actions.

## Proposed API Shape

```swift
public struct TextEditorPaneConfiguration {
    public var title: String
    public var text: Binding<String>
    public var allowsPaste: Bool
    public var allowsTextFileDrop: Bool
    public var allowsCopy: Bool
    public var allowsSave: Bool
    public var onSendToTool: ((String, Tool) -> Void)?
}

public struct SplitSettings {
    public var fractionKey: String
    public var layoutKey: String
    public var defaultLayout: SideBySideLayout
}

public struct StandardTextInputOutputView<Configuration: View>: View {
    public init(
        actionTitle: String,
        actionHelp: String,
        isLoading: Bool,
        performAction: @escaping () -> Void,
        splitSettings: SplitSettings,
        input: TextEditorPaneConfiguration,
        output: TextEditorPaneConfiguration,
        @ViewBuilder configuration: () -> Configuration
    )
}
```

For simple tools, call sites become mostly declarative:

```swift
StandardTextInputOutputView(
    actionTitle: "Format",
    actionHelp: "Format code (Cmd Return)",
    isLoading: model.isConversionRequestInFlight,
    performAction: model.convertButtonTouched,
    splitSettings: .init(
        fractionKey: SettingsKey.JsonPretty.splitViewFraction,
        layoutKey: SettingsKey.JsonPretty.splitViewLayout,
        defaultLayout: .horizontal
    ),
    input: .input(
        title: "Raw",
        text: Binding(model.$inputText)
    ),
    output: .output(
        title: "Pretty",
        text: Binding(model.$outputText),
        onSendToTool: onSendOutputToTool
    )
) {
    EmptyView()
}
```

Provide convenience factories:

```swift
extension TextEditorPaneConfiguration {
    static func input(title: String, text: Binding<String>) -> Self
    static func output(
        title: String,
        text: Binding<String>,
        onSendToTool: ((String, Tool) -> Void)? = nil
    ) -> Self
}
```

Those defaults should encode the normal behavior:

- input: paste enabled, text-file drop enabled, copy/save/send disabled
- output: paste/drop disabled, copy/save enabled, send enabled only when a closure is provided

## Protocol Position

Do not add a model protocol in the first pass.

`Binding(model.$inputText)` solves the worst boilerplate problem without introducing protocol requirements. A protocol would still have weak value initially because conversion logic, config state, syntax highlighting, and special routing differ across tools.

Reconsider protocols only after migrating several simple tools. If the same parameters are still repeated, consider a tiny protocol for metadata only:

```swift
protocol StandardTextToolMetadata {
    static var inputTitle: String { get }
    static var outputTitle: String { get }
    static var splitFractionKey: String { get }
    static var splitLayoutKey: String { get }
}
```

Even then, prefer static metadata over model behavior protocols.

## Migration Order

Start with one low-risk tool:

1. `JsonPretty`
2. `HtmlBeautify`
3. `CssBeautify`
4. `JsBeautify`
5. `YamlToJson`
6. `JsonToYaml`
7. `AsciiToHex` / `HexToAscii`
8. `BackslashEscape`
9. `XmlFormat`

Keep custom for now:

- `HtmlToSwift`: attributed output and syntax highlighting
- `RegexMatches`: one input and two outputs
- `StringDiff`: two inputs and diff behavior
- `HtmlPreview`: rendered preview output
- `Base64Image`: image-specific UI
- `UrlParser`: semantic parsed output
- certificate/QR tools where output is not just editable text

## Testing

For the first migrated tool:

- `swift build`
- existing feature tests for that tool
- add or update one UI-independent model test only if behavior changes
- manually verify paste, drop, copy, save, send-to-tool, and split layout

After the first tool proves the API, migrate the next simple tools in small batches.

## Risks

- A generic SwiftUI view with too many options can become harder to read than the duplicated code. Keep pane configuration small and use defaults.
- Do not abstract conversion task lifecycle yet. Tool conversion behavior differs enough that hiding it would be brittle.
- Keep send-to-tool routing in `AppFeature`; `InputOutput` should only expose a button that calls `onSelect(Tool)`.
- Avoid model protocols until they remove code rather than relocate it.
