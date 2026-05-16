# DevBliss TCA Removal And Target Flattening Plan

## Summary
Migrate DevBliss from TCA reducers/stores to SwiftUI Observation models while keeping `swift-dependencies` and `@Shared` persistence. Collapse each `*Client` target into its matching `*Feature` target, but keep existing `*Feature` module/product names during this migration to avoid a large public module rename in the same pass. After the last TCA usage is gone, remove `swift-composable-architecture`.

## Key Changes
- Add `swift-sharing` as a direct package dependency and use its `Sharing` product anywhere `@Shared`, `Shared`, `SharedReaderKey`, or `FileStorageKey` is used.
- Keep `swift-dependencies`; annotate dependency properties in observable models with `@ObservationIgnored`.
- Convert feature reducers into `@MainActor @Observable final class` models:
  ```swift
  @MainActor
  @Observable
  public final class JsonPrettyModel {
      @ObservationIgnored
      @Shared(.toolInput("jsonPretty")) public var inputText = ""

      @ObservationIgnored
      @Shared(.toolOutput("jsonPretty")) public var outputText = ""

      public var isConversionRequestInFlight = false

      @ObservationIgnored
      @Dependency(\.jsonPretty) private var jsonPretty

      @ObservationIgnored
      private var conversionTask: Task<Void, Never>?

      public func convertButtonTouched() { ... }
      public func cancel() { conversionTask?.cancel() }
  }
  ```
- Replace TCA actions with model methods. Replace `.run`, `.cancellable`, and `TaskResult` with `Task`, stored cancellation handles, `do/catch`, and `@MainActor` state updates.
- Keep `@Shared` storage keys and current persisted file paths exactly unchanged so existing user tool input/output survives the migration.
- Collapse target pairs by moving each `Sources/*Client` implementation into the matching `Sources/*Feature` target and deleting the `*Client` target/product. Example: `JsonPrettyClient` files move into `JsonPrettyFeature`; `JsonPrettyFeature` depends directly on `Dependencies`.
- Keep shared infrastructure targets separate: `InputOutput`, `SharedModels`, `BlissTheme`, `ClipboardClient`, `FilePanelsClient`, `FilesClient`, `SyntaxHighlightClient`, and other genuinely shared/platform clients.

## Migration Sequence
1. **Foundation**
   - Add direct `swift-sharing` dependency.
   - Change `SharedModels/ToolIOStorage.swift` from `import ComposableArchitecture` to `import Sharing`.
   - Do not remove TCA yet.

2. **Hybrid App Shell**
   - Replace `AppReducer`/`AppView(store:)` with `AppModel`/`AppView(model:)`.
   - Use a plain `Destination` enum owned by `AppModel`.
   - During migration, allow legacy destination cases to hold `StoreOf<OldReducer>` and migrated cases to hold new observable models. This keeps the app buildable feature-by-feature.
   - Move navigation, current-tool derivation, quick action bar visibility, and output-to-other-tool transfer logic into `AppModel` methods.

3. **Observation-Based InputOutput V2**
   - Add new observable editor models/views beside the existing TCA reducers in `InputOutput`.
   - Do not delete the old TCA editor reducers until all legacy feature reducers are gone.
   - New feature models should use the V2 editor APIs directly via `@Shared` values or bindings.

4. **Pilot Tool**
   - Migrate `JsonPrettyFeature` first because it has representative async conversion, persisted input/output, attributed output, and existing tests.
   - Move `JsonPrettyClient` into `JsonPrettyFeature`.
   - Convert `JsonPrettyReducer.State` to `JsonPrettyModel`, actions to methods, and `JsonPrettyView(store:)` to `JsonPrettyView(model:)`.
   - Update `AppModel.Destination.jsonPretty` to store `JsonPrettyModel`, not a TCA store.
   - Rewrite `JsonPretty` tests as direct model/client tests.

5. **Simple Tool Batch**
   - Apply the same pattern to straightforward input/output tools: `Base64`, `AsciiToHex`, `HexToAscii`, `CssBeautify`, `HtmlBeautify`, `JsBeautify`, `XmlFormat`, `LineSortDedupe`, `HashGenerator`, `NumberBaseConverter`, `UrlEncode`, `YamlToJson`, `JsonToYaml`, `SwiftPretty`, `BackslashEscape`, `SvgToCss`, `TextCaseConverter`, `PrefixSuffix`.
   - For each tool: merge client target, convert reducer to model, update destination case, rewrite tests, verify package build.

6. **Complex Tool Batch**
   - Migrate complex or special-state tools last: `HtmlToSwift`, `HtmlToMarkdown`, `UrlToMarkdown`, `RegexMatches`, `RegExpTester`, `JwtDebugger`, `Base64Image`, `FileContentSearch`, `NameGenerator`, `RandomStringGenerator`, `UuidUlid`, `QrCodeTool`, `CertificateDecoder`, `HtmlPreview`, `UrlParser`, `UnixTime`, `StringDiff`, `StringInspector`, `ColorConverter`, `UUIDGenerator`.
   - Preserve platform conditionals, especially macOS-only `FileContentSearch`.
   - Preserve current multi-output behavior for `RegexMatches` and old/new input behavior for `StringDiff`.

7. **Final Cleanup**
   - Delete legacy TCA editor reducers and any remaining `StoreOf`, `Store`, `Scope`, `BindingReducer`, `Effect`, `TaskResult`, `TestStore`, `@Reducer`, `@ObservableState`, `BindableAction`, `BindingAction`, `@Presents`, and `PresentationAction` usage.
   - Remove `swift-composable-architecture` from `Package.swift` and `Package.resolved`.
   - Remove obsolete `*Client` products/targets and update tests to depend on the merged `*Feature` modules.
   - Update docs that describe TCA architecture.

## Test Plan
- Before migration, run baseline `swift test` and an app build to capture current failures, if any.
- After each migrated batch, run:
  - `swift test` from `DevBliss`
  - app build for macOS
  - iOS package/app build if supported by existing project setup
- For each migrated tool, cover:
  - default model initialization
  - persisted `@Shared` input/output wiring
  - successful conversion/generation
  - error output behavior
  - cancellation or repeated-button behavior where the old reducer used `.cancellable`
  - output-to-other-tool transfer through `AppModel`
- Manually smoke test the app navigation, quick action bar, copy/save controls, paste/drop behavior, and at least one migrated and one legacy tool during hybrid phases.

## Assumptions And Defaults
- Keep `swift-dependencies` for now.
- Keep `@Shared` and add `@ObservationIgnored` to every `@Shared` property inside `@Observable` models.
- Keep existing `*Feature` module names during the migration; do not rename to suffixless modules until a later optional cleanup.
- Preserve persisted storage paths and settings keys exactly.
- Prefer incremental, compiling checkpoints over a single large rewrite.
