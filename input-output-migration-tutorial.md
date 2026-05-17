# Migrating Tools to the Shared InputOutput Views

This tutorial explains how to migrate a tool from hand-written `TextEditor` and `SplitView` code to the reusable views in `Sources/InputOutput/`.

The goal is not to make every tool generic. The goal is to remove repeated editor layout, paste/drop/copy/save/send actions, and split-view setup while keeping each tool's conversion logic, settings, preview modes, and task lifecycle inside its own feature.

Good examples to copy:

- `Sources/HtmlToSwiftFeature/HtmlToSwiftReducer.swift`
- `Sources/JsonPrettyFeature/JsonPrettyReducer.swift`

## What the Shared Views Do

Use these views from `InputOutput`:

- `TwoPaneToolView`: wraps a configuration area, loading action button, divider, and `SideBySideView`.
- `PlainInputTextPane`: input editor with paste and text-file drop support.
- `PlainOutputTextPane`: plain text output editor with copy, save, and optional send-to-tool.
- `AttributedOutputTextPane`: attributed output editor with copy, save, and optional send-to-tool.
- `TextPane`: lower-level pane wrapper when a tool needs a custom editor body but still wants the standard pane title/footer chrome.

Do not move conversion logic into these views. Keep conversion in the model.

## Choose the Right Migration Type

Use a plain output migration when the tool only stores and displays plain text:

- `HtmlBeautify`
- `CssBeautify`
- `JsBeautify`
- `XmlFormat`
- `LineSortDedupe`
- `AsciiToHex`
- `HexToAscii`
- `BackslashEscape`
- `Base64`
- `TextCaseConverter`
- `PrefixSuffix`

Use an attributed output migration when the output is or should be syntax highlighted:

- `JsonPretty`
- `HtmlToSwift`
- later candidates: `YamlToJson`, `JsonToYaml`, `SwiftPretty`, `HtmlToMarkdown`

Use only `TextPane` when the tool layout is not a normal input/output pair:

- `RegexMatches`: one input and two outputs
- `RegExpTester`: input plus match list plus replacement output
- `StringDiff`: two inputs plus diff result
- `HtmlPreview`: text input plus rendered preview
- `UrlParser`, `JwtDebugger`, `StringInspector`: structured result cards
- `Base64Image`, `QrCodeTool`, certificate/image-specific tools

## Step 1: Add Imports

In the feature reducer file, add `InputOutput`.

Before:

```swift
import BlissTheme
import Dependencies
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI
```

After:

```swift
import BlissTheme
import Dependencies
import InputOutput
import Observation
import SharedModels
import Sharing
import SwiftUI
```

Remove `SplitView` if the feature no longer uses `Split`, `VSplit`, `FractionHolder`, `LayoutHolder`, or `SideHolder` directly.

If the tool uses `NSMutableAttributedString` or `NSAttributedString`, also import `Foundation`.

## Step 2: Expose Send-To-Tool From the View

The reusable output panes can show a Send button, but the app shell still owns routing.

Add this property and initializer argument to the tool view:

```swift
public struct SomeToolModelView: View {
    @Bindable var model: SomeToolModel
    private let onSendOutputToTool: ((String, Tool) -> Void)?

    public init(
        model: SomeToolModel,
        onSendOutputToTool: ((String, Tool) -> Void)? = nil
    ) {
        self.model = model
        self.onSendOutputToTool = onSendOutputToTool
    }
}
```

Then add this adapter in the view:

```swift
private var sendOutputToTool: ((Tool) -> Void)? {
    guard let onSendOutputToTool else {
        return nil
    }

    return { tool in
        onSendOutputToTool(model.outputText, tool)
    }
}
```

Finally, update `Sources/AppFeature/AppModelView.swift` so the feature receives the app routing closure:

```swift
case .someTool(let model):
    SomeToolModelView(model: model, onSendOutputToTool: self.model.sendOutputToOtherTool)
        .padding(.top)
```

If a tool should not send output to other tools, skip this step and omit `onSendToTool`.

## Step 3: Add Binding Helpers

Most tool models store text in `@Shared`, so write explicit `Binding` helpers. Do not rely on magic binding conversion unless you have compiled it.

Input binding:

```swift
private var inputTextBinding: Binding<String> {
    Binding(
        get: { model.inputText },
        set: { newValue in model.$inputText.withLock { $0 = newValue } }
    )
}
```

Plain output binding:

```swift
private var outputTextBinding: Binding<String> {
    Binding(
        get: { model.outputText },
        set: { newValue in model.$outputText.withLock { $0 = newValue } }
    )
}
```

Attributed output binding:

```swift
private var outputAttributedTextBinding: Binding<NSMutableAttributedString> {
    Binding(
        get: { model.outputAttributedText },
        set: { model.setOutputAttributedText($0) }
    )
}
```

## Step 4A: Migrate a Plain Text Tool

Use this pattern when both panes are plain text.

Before, most tools have something like this:

```swift
VStack(spacing: 0) {
    LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
        model.convertButtonTouched()
    }
    .keyboardShortcut(.return, modifiers: [.command])

    Divider()

    Split(primary: { inputEditor }, secondary: { outputEditor })
        .fraction(FractionHolder.usingUserDefaults(0.5, key: SettingsKey.SomeTool.splitViewFraction))
        .layout(LayoutHolder.usingUserDefaults(.horizontal, key: SettingsKey.SomeTool.splitViewLayout))
        .styling(visibleThickness: 2)
}
```

Replace it with:

```swift
public var body: some View {
    TwoPaneToolView(
        actionTitle: "Convert",
        actionHelp: "Convert (Cmd Return)",
        isLoading: model.isConversionRequestInFlight,
        performAction: model.convertButtonTouched,
        splitSettings: .init(
            fractionKey: SettingsKey.SomeTool.splitViewFraction,
            layoutKey: SettingsKey.SomeTool.splitViewLayout,
            primaryLabel: "Input",
            secondaryLabel: "Output"
        )
    ) {
        PlainInputTextPane(
            title: "Input",
            text: inputTextBinding
        )
    } secondary: {
        PlainOutputTextPane(
            title: "Output",
            text: outputTextBinding,
            onSendToTool: sendOutputToTool
        )
    }
}
```

If the tool has settings above the button, use the `configuration` closure:

```swift
public var body: some View {
    TwoPaneToolView(
        actionTitle: "Process",
        actionHelp: "Process (Cmd Return)",
        isLoading: model.isConversionRequestInFlight,
        performAction: model.convertButtonTouched,
        splitSettings: .init(
            fractionKey: SettingsKey.LineSortDedupe.splitViewFraction,
            layoutKey: SettingsKey.LineSortDedupe.splitViewLayout,
            primaryLabel: "Input",
            secondaryLabel: "Output"
        )
    ) {
        settingsView
    } primary: {
        PlainInputTextPane(title: "Input", text: inputTextBinding)
    } secondary: {
        PlainOutputTextPane(
            title: "Output",
            text: outputTextBinding,
            onSendToTool: sendOutputToTool
        )
    }
}
```

Keep `settingsView` local to the feature. Do not move settings into `InputOutput`.

## Step 4B: Migrate an Attributed Output Tool

Use this when the output should preserve syntax highlighting or rich text.

Add this model property:

```swift
public var outputAttributedText = NSMutableAttributedString()
```

Initialize it in every initializer after `_outputText` is assigned:

```swift
self.outputAttributedText = .init(
    attributedString: EditorAttributedStrings.regular(outputText.wrappedValue)
)
```

Add a setter that keeps attributed output and persisted plain output in sync:

```swift
public func setOutputAttributedText(_ value: NSMutableAttributedString) {
    outputAttributedText = value
    $outputText.withLock { $0 = value.string }
}
```

Add a private helper for conversion results:

```swift
private func updateOutput(_ text: String, attributedText: NSAttributedString? = nil) {
    $outputText.withLock { $0 = text }
    outputAttributedText = .init(
        attributedString: attributedText ?? EditorAttributedStrings.regular(text)
    )
}
```

In `convertButtonTouched`, update both values on success:

```swift
let result = try await client.convert(input)
await MainActor.run {
    self.isConversionRequestInFlight = false
    self.updateOutput(result.string, attributedText: result)
}
```

And update both values on failure:

```swift
await MainActor.run {
    self.isConversionRequestInFlight = false
    self.updateOutput(
        error.localizedDescription,
        attributedText: EditorAttributedStrings.error(error.localizedDescription)
    )
}
```

Then use `AttributedOutputTextPane`:

```swift
public var body: some View {
    TwoPaneToolView(
        actionTitle: "Format",
        actionHelp: "Format code (Cmd Return)",
        isLoading: model.isConversionRequestInFlight,
        performAction: model.convertButtonTouched,
        splitSettings: .init(
            fractionKey: SettingsKey.JsonPretty.splitViewFraction,
            layoutKey: SettingsKey.JsonPretty.splitViewLayout,
            primaryLabel: "Raw",
            secondaryLabel: "Pretty"
        )
    ) {
        PlainInputTextPane(
            title: "Raw",
            text: inputTextBinding
        )
    } secondary: {
        AttributedOutputTextPane(
            title: "Pretty",
            attributedText: outputAttributedTextBinding,
            plainText: { model.outputText },
            onSendToTool: sendOutputToTool
        )
    }
}
```

## Step 5: Keep Custom Layouts Custom

Do not force every feature into `TwoPaneToolView`.

For example, if a tool has a custom result area but still needs a standard input editor, use only `TextPane` or `PlainInputTextPane`:

```swift
private var inputEditor: some View {
    PlainInputTextPane(
        title: "Test Text",
        text: inputTextBinding,
        minHeight: 140
    )
}
```

For a custom body with standard title/footer:

```swift
TextPane(title: "Matches", minHeight: 140) {
    ScrollView {
        matchesList
    }
} trailingActions: {
    CopyToClipboardButton {
        model.outputText
    }
}
```

This is the right approach for tools like regex, diff, previews, and structured cards.

## Step 6: Update Tests

If the tool already has tests, add one test for any new attributed-output behavior.

For attributed output:

```swift
func testEditingAttributedOutputSyncsRawOutputText() {
    let model = SomeToolModel(input: "", output: "initial")

    model.setOutputAttributedText(NSMutableAttributedString(string: "edited output"))

    XCTAssertEqual(model.outputText, "edited output")
    XCTAssertEqual(model.outputAttributedText.string, "edited output")
}
```

If you add a new test target, register it in `Package.swift`:

```swift
.testTarget(
    name: "SomeToolFeatureTests",
    dependencies: [
        "SomeToolFeature",
        .product(name: "Dependencies", package: "swift-dependencies"),
    ]
),
```

When testing models that use `@Shared`, prefer writing through the shared binding:

```swift
let model = SomeToolModel()
model.$inputText.withLock { $0 = "input" }
```

This avoids surprises from persisted shared storage.

## Step 7: Build and Test

Run:

```bash
swift build
swift test
```

If build fails, check these common problems:

- Missing `import InputOutput`.
- Still importing `SplitView` when no longer needed.
- Missing `Foundation` for `NSMutableAttributedString`.
- Forgot to add `onSendOutputToTool` to the view initializer but passed it from `AppModelView`.
- Forgot to add `outputAttributedText` initialization in every model initializer.
- The output pane uses `AttributedOutputTextPane`, but the model only exposes `Binding<String>`.

## Migration Checklist

Use this checklist for every tool:

- Decide plain output, attributed output, or custom layout.
- Add `import InputOutput`.
- Remove direct `SplitView` usage if fully replaced by `TwoPaneToolView`.
- Add `onSendOutputToTool` to the view if the tool has text output worth sending.
- Pass `self.model.sendOutputToOtherTool` from `AppModelView`.
- Add `inputTextBinding`.
- Add `outputTextBinding` for plain output, or `outputAttributedTextBinding` for attributed output.
- Replace hand-written `LoadingButton` plus `Split` with `TwoPaneToolView` when the layout is a normal two-pane tool.
- Keep feature-specific settings in the feature view.
- For attributed output, keep `outputText` and `outputAttributedText` synchronized.
- Add or update tests.
- Run `swift build`.
- Run `swift test`.

## When Not To Migrate Yet

Pause and ask for a design decision if:

- The tool output is not text.
- The tool has more than two primary panes.
- The output is a rendered preview, image, chart, table, card grid, or diff UI.
- The migration would require changing conversion behavior.
- The reusable view needs many new options for one tool.

In those cases, migrate only the repeated pane pieces or leave the tool custom.
