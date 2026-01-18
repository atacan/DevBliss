# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the Swift package
swift build

# Run tests
swift test

# Run a specific test
swift test --filter PrefixSuffixClientTests

# Open the Xcode project (for full app development)
open App/DevBliss.xcodeproj
```

## Architecture

DevBliss is a macOS/iOS developer utility app built with **The Composable Architecture (TCA)** from Point-Free. The architecture follows a modular pattern inspired by [isowords](https://github.com/pointfreeco/isowords).

### Module Structure

Each tool follows a **Client + Feature** pattern:
- **`*Client`**: Dependency wrapper around the core logic (e.g., `HtmlToMarkdownClient`)
- **`*Feature`**: TCA Reducer + SwiftUI View (e.g., `HtmlToMarkdownFeature`)

Key shared modules:
- **`AppFeature`**: Main app reducer with navigation via `Destination` enum
- **`SharedModels`**: `Tool` enum, `ToolIOStorage` for persistence
- **`InputOutput`**: Reusable input/output editor components (`InputOutputEditorsReducer`, `OutputEditorReducer`)
- **`BlissTheme`**: Shared UI components and view modifiers (`.blissTextField()`, `.blissMenuPicker()`, `LoadingButton`, `ConfigLabel`)

### Navigation Pattern

Tools are managed via a `@Reducer public enum Destination` in `AppReducer.swift`. Each tool case maps to its feature reducer. The `currentTool` computed property derives the active tool from the destination state.

### Adding a New Tool

1. Create `Sources/<ToolName>Client/<ToolName>Client.swift` with dependency conformance
2. Create `Sources/<ToolName>Feature/<ToolName>Reducer.swift` with TCA reducer and view
3. Add case to `Tool` enum in `SharedModels/Tool.swift` (include `name` and `isInputtable`)
4. Add storage key in `SharedModels/ToolIOStorage.swift`
5. Update `AppReducer.swift`:
   - Add import
   - Add `Destination` case
   - Add `currentTool` mapping
   - Add destination action handling for output controls
   - Add `handleOtherTool` case
   - Add `handleNavigation` case
   - Add sidebar row and detail view
6. Update `Package.swift` with library products and target definitions

### Persistence

Tool state persists via `@Shared` with `FileStorageKey`:
```swift
@Shared(.urlToMarkdownIO) public var storage = ToolIOStorage()
```

Storage files are in `~/Documents/ToolStorage/`.

### Troubleshooting

If you get "The compiler is unable to type-check this expression in reasonable time", comment out other tools in the reducer to isolate the issue.

## Issue Tracking

This project uses **bd (beads)** for task tracking. Key commands:
```bash
bd ready --json          # See unblocked issues
bd create "Title" -t feature -p 2 --json
bd update <id> --status in_progress --json
bd close <id> --reason "Done" --json
bd sync                  # Run at end of session
```
