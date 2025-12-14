# @Bindable Macro Investigation Report for TCA 1.23.1

**Issue:** DevBliss-c9a  
**Date:** 2025-12-13  
**Status:** Investigation Complete

## Executive Summary

TCA 1.23.1 already supports `@Bindable` for view binding patterns, but DevBliss' codebase currently uses a mix of older patterns:
- `@Perception.Bindable` (modern pattern, already in use)
- `store.binding()` closures (legacy pattern, still present)
- `$store.property` direct property access (working in macOS views)

The codebase has partially adopted the modern `@Bindable` pattern but has not fully migrated all views.

## What is @Bindable?

`@Bindable` is a property wrapper introduced in iOS 17+ (and provided by Perception for earlier versions) that simplifies state binding in TCA views. It eliminates the need for explicit `ViewStore` binding calls.

### Key Points:

1. **Part of Perception Framework**: Available as `@Perception.Bindable` for all platforms
2. **Native in iOS 17+**: Available as `@Bindable` directly in iOS 17+ and macOS 14+
3. **Works with @ObservableState**: Requires state to be marked with `@ObservableState`
4. **Simpler Syntax**: Allows `$store.property` instead of `store.binding(get: \.property, send: ...)`

## Current DevBliss Binding Patterns

### Pattern 1: Modern @Bindable (Already Used ✅)

**File:** `InputAttributedEditorView.swift` (line 98)

```swift
@Perception.Bindable var store: StoreOf<InputAttributedEditorReducer>
```

This is the **recommended** pattern for TCA 1.23.1. It works on all platforms (macOS 12+, iOS 15+).

### Pattern 2: Legacy store.binding() Closures (Still Present ⚠️)

**File:** `InputAttributedEditorView.swift` (lines 138-145)

```swift
TextEditor(
    text: store.binding(
        get: { state in
            state.text.string
        },
        send: { newValue in
            .binding(.set(\.$text, .init(string: newValue)))
        }
    )
)
```

This pattern is **verbose** and requires manual get/send closures. Can be replaced with `@Bindable`.

### Pattern 3: Direct Property Access (Platform-Specific)

**File:** `InputAttributedEditorView.swift` (line 122)

```swift
MacEditorView(text: $store.text, hasHorizontalScroll: false)
```

This works on macOS due to direct property access but is inconsistent across platforms.

## Migration Path

### Step 1: Ensure @ObservableState (Already Done ✅)

All reducers in DevBliss already use `@ObservableState`:

```swift
@ObservableState
public struct State: Equatable {
    // ... properties
}
```

### Step 2: Replace store.binding() Closures

Replace verbose binding closures with simple property access:

**Before:**
```swift
TextEditor(
    text: store.binding(
        get: { $0.text.string },
        send: { .binding(.set(\.$text, .init(string: $0))) }
    )
)
```

**After:**
```swift
TextEditor(text: $store.text)
```

**Challenge:** This only works for simple String properties. NSAttributedString requires custom binding logic.

### Step 3: Standardize View Store Declarations

Use consistent `@Perception.Bindable` across all views:

```swift
public struct MyView: View {
    @Perception.Bindable var store: StoreOf<MyReducer>
    
    var body: some View {
        TextField("Name", text: $store.name)
    }
}
```

## Inventory of Current Binding Usage

### Views Using @Perception.Bindable (Modern ✅)

- `InputAttributedEditorView` (line 98)

### Views Using Older Patterns (Need Review)

1. **InputAttributedEditorView.swift**
   - Lines 138-145: `store.binding()` closure (iOS TextEditor)
   - Line 122: Direct `$store.text` (macOS)
   - **Status:** Inconsistent iOS/macOS patterns

2. **Files with `store.binding()` references** (mostly commented):
   - `UUIDGeneratorReducer.swift` (lines 89-96): Commented out bindings
   - `FileContentSearchFeature/FileContentSearchReducer.swift` (lines 257, 263): Commented out
   - **Status:** Already identified as needing refactoring

### Reducers with BindableAction (Required ✅)

All reducers properly implement `BindableAction`:
- TextCaseConverterReducer (line 61)
- SwiftPrettyReducer (line 98)
- RegexMatchesReducer (line 69)
- PrefixSuffixReducer (line 76)
- HtmlToSwiftReducer (line 61)
- InputAttributedEditorReducer (line 27)

## Recommendations

### Priority 1: Standardize @Perception.Bindable Usage
- Ensure all views use `@Perception.Bindable` consistently
- This provides foundation for further improvements

### Priority 2: Replace Simple store.binding() Calls
- Identify views where `store.binding()` can be replaced with `$store.property`
- This reduces verbosity and improves readability

### Priority 3: Custom Binding Solutions
- For complex types (NSAttributedString, custom structs), keep custom binding logic
- Document why custom bindings are needed

### Priority 4: iOS/macOS Consistency
- InputAttributedEditorView shows platform-specific patterns
- Consider unifying if possible or documenting intentional differences

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| @ObservableState macro | ✅ Done | All states properly annotated |
| @Bindable adoption | ⚠️ Partial | Some views updated, others need review |
| BindableAction pattern | ✅ Done | All reducers implement correctly |
| store.binding() refactoring | 🔳 Pending | Some commented code, some active |
| iOS/macOS binding consistency | 🔳 Review needed | Different patterns per platform |

## Conclusion

DevBliss has **partially adopted** the modern `@Bindable` pattern in TCA 1.23.1, but there are opportunities for fuller migration:

1. **No Breaking Changes Required** - All current patterns work with TCA 1.23.1
2. **Incremental Refactoring** - Can migrate view by view
3. **Best Practices** - `@Perception.Bindable` + `$store.property` is the recommended approach for new code

## Next Steps

1. Document binding patterns used in each view
2. Identify low-risk refactoring candidates
3. Create pull request to standardize on `@Bindable` pattern
4. Update developer guidelines to recommend `@Bindable` for all new views
