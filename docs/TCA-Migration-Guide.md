# The Composable Architecture Migration Guide

A practical guide covering the major API migrations used in this codebase when migrating from TCA 0.x/1.x to modern TCA (1.7+).

## Overview

This guide covers the key migration patterns actually used in the DevBliss codebase. For comprehensive migration information, refer to the official guides in `history/TCA-MigrationGuides/`.

## Quick Reference

| Old Pattern | New Pattern | Version |
|------------|-------------|---------|
| `ReducerProtocol` | `@Reducer` macro | 1.4+ |
| `/Action.case` | `\.case` | 1.4+ |
| `EffectTask` | `Effect` | 1.7+ |
| `Store(initialState:, reducer:)` | `Store(initialState:) { Reducer() }` | 1.7+ |
| `WithViewStore` | Direct store access | 1.7+ |
| `@PresentationState` | `@Presents` | 1.7+ |

## Migration Patterns

### 1. @Reducer Macro (TCA 1.4+)

The `@Reducer` macro automates boilerplate and enables case key paths.

**Before:**
```swift
struct Feature: Reducer {
    struct State { }
    enum Action { }
    var body: some ReducerOf<Self> { }
}
```

**After:**
```swift
@Reducer
struct Feature {
    struct State { }
    enum Action { }
    var body: some Reducer<State, Action> { }
}
```

**What the macro does:**
- Applies `@CasePathable` to `Action` enum (enables key path syntax)
- Applies `@CasePathable` and `@dynamicMemberLookup` to `State` enum (if State is an enum)
- Adds `Reducer` protocol conformance

### 2. Case Key Paths (TCA 1.4+)

Replace the `/` prefix operator with key path syntax for case paths.

**Before:**
```swift
Reduce { state, action in
    // ...
}
.ifLet(\.child, action: /Action.child) {
    ChildFeature()
}
```

**After:**
```swift
Reduce { state, action in
    // ...
}
.ifLet(\.child, action: \.child) {
    ChildFeature()
}
```

**Scoping stores:**

**Before:**
```swift
store.scope(
    state: \.child,
    action: { .child($0) }
)
```

**After:**
```swift
store.scope(
    state: \.child,
    action: \.child
)
```

### 3. Store Initialization (TCA 1.7+)

Use trailing closure syntax for the reducer.

**Before:**
```swift
Store(
    initialState: Feature.State(),
    reducer: Feature()
)
```

**After:**
```swift
Store(initialState: Feature.State()) {
    Feature()
}
```

**In tests:**
```swift
let store = TestStore(initialState: Feature.State()) {
    Feature()
}
```

### 4. @ObservableState and ViewStore Removal (TCA 1.7+)

Replace `WithViewStore` pattern with direct store access using `@ObservableState`.

**Before:**
```swift
struct Feature: Reducer {
    struct State {
        var count = 0
    }
    // ...
}

struct FeatureView: View {
    let store: StoreOf<Feature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text("\(viewStore.count)")
            Button("+") {
                viewStore.send(.incrementTapped)
            }
        }
    }
}
```

**After:**
```swift
@Reducer
struct Feature {
    @ObservableState
    struct State {
        var count = 0
    }
    // ...
}

struct FeatureView: View {
    let store: StoreOf<Feature>

    var body: some View {
        Text("\(store.count)")
        Button("+") {
            store.send(.incrementTapped)
        }
    }
}
```

**Key changes:**
- Mark `State` with `@ObservableState` macro
- Remove `WithViewStore` wrapper
- Access state directly: `store.count` instead of `viewStore.count`
- Send actions directly: `store.send(.action)` instead of `viewStore.send(.action)`

**Note:** On iOS 16 and earlier, wrap the view body with `WithPerceptionTracking { }` if not using native SwiftUI observation.

### 5. @Perception.Bindable (TCA 1.7+)

For two-way bindings, use `@Perception.Bindable` (or `@Bindable` on iOS 17+).

**Before:**
```swift
struct FeatureView: View {
    let store: StoreOf<Feature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TextField("Name", text: viewStore.$name)
        }
    }
}
```

**After:**
```swift
struct FeatureView: View {
    @Perception.Bindable var store: StoreOf<Feature>

    var body: some View {
        TextField("Name", text: $store.name)
    }
}
```

**Requirements:**
- Mark `State` with `@ObservableState`
- Remove `@BindingState` from individual properties
- Keep `BindableAction` conformance and `BindingReducer()` in reducer

### 6. @Presents Macro (TCA 1.7+)

Replace `@PresentationState` property wrapper with `@Presents` macro.

**Before:**
```swift
@ObservableState
struct State {
    @PresentationState var child: Child.State?  // Error with @ObservableState
}
```

**After:**
```swift
@ObservableState
struct State {
    @Presents var child: Child.State?
}
```

**In the reducer:**
```swift
@Reducer
struct Feature {
    @ObservableState
    struct State {
        @Presents var child: Child.State?
    }

    enum Action {
        case child(PresentationAction<Child.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            // ...
        }
        .ifLet(\.$child, action: \.child) {
            Child()
        }
    }
}
```

### 7. Navigation View Modifiers (TCA 1.7+)

Use vanilla SwiftUI navigation modifiers with store scoping.

**Before:**
```swift
.sheet(store: store.scope(state: \.$child, action: \.child)) { store in
    ChildView(store: store)
}
```

**After:**
```swift
struct FeatureView: View {
    @Perception.Bindable var store: StoreOf<Feature>

    var body: some View {
        // ...
        .sheet(item: $store.scope(state: \.child, action: \.child)) { store in
            ChildView(store: store)
        }
    }
}
```

**Key changes:**
- Use `@Perception.Bindable` (or `@Bindable` on iOS 17+)
- Replace `.sheet(store:)` with `.sheet(item:)`
- Use `$store.scope()` with `$` prefix for binding
- State key path is `\.child`, not `\.$child`

**Applies to:**
- `.sheet(item:)`
- `.popover(item:)`
- `.fullScreenCover(item:)`
- `.navigationDestination(item:)`

### 8. Enum-Driven Navigation (TCA 1.5+)

For navigation driven by enum state destinations.

**Before:**
```swift
.sheet(
    store: store.scope(state: \.$destination, action: { .destination($0) }),
    state: \.editForm,
    action: { .editForm($0) }
)
```

**After:**
```swift
.sheet(
    item: $store.scope(
        state: \.destination?.editForm,
        action: \.destination.editForm
    )
) { store in
    EditFormView(store: store)
}
```

### 9. EffectTask to Effect

The type alias changed but usage remains similar.

**Before:**
```swift
return .run { send in
    await send(.response(await apiCall()))
}
```

**After:**
```swift
// Same syntax, just different type name internally
return .run { send in
    await send(.response(await apiCall()))
}
```

## Common Patterns in This Codebase

### Basic Feature Structure

```swift
@Reducer
public struct MyFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        var count = 0
        // No @BindingState needed
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case incrementTapped
    }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .incrementTapped:
                state.count += 1
                return .none
            }
        }
    }
}
```

### View with Bindings

```swift
public struct MyFeatureView: View {
    @Perception.Bindable var store: StoreOf<MyFeature>

    public init(store: StoreOf<MyFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            Text("\(store.count)")
            Button("Increment") {
                store.send(.incrementTapped)
            }
        }
    }
}
```

### Feature with Child Features

```swift
@Reducer
public struct ParentFeature {
    @ObservableState
    public struct State {
        @Presents var child: ChildFeature.State?
        var value = ""
    }

    public enum Action {
        case child(PresentationAction<ChildFeature.Action>)
        case showChildTapped
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .showChildTapped:
                state.child = ChildFeature.State()
                return .none
            case .child:
                return .none
            }
        }
        .ifLet(\.$child, action: \.child) {
            ChildFeature()
        }
    }
}
```

## Migration Strategy

1. **Update dependencies**: Ensure you're on TCA 1.7+
2. **Add @Reducer macro**: Apply to all reducers
3. **Add @ObservableState**: Mark all State types
4. **Replace @PresentationState**: Use `@Presents` instead
5. **Update case paths**: Replace `/` with `\.` syntax
6. **Remove ViewStore**: Update views to access store directly
7. **Update bindings**: Use `@Perception.Bindable` where needed
8. **Update Store initialization**: Use trailing closure syntax
9. **Update navigation**: Use vanilla SwiftUI modifiers with `$store.scope()`

## Testing Updates

**Before:**
```swift
let store = TestStore(
    initialState: Feature.State(),
    reducer: Feature()
)

store.send(.increment) {
    $0.count = 1
}

store.receive(.response(.success("data"))) {
    $0.data = "data"
}
```

**After:**
```swift
let store = TestStore(initialState: Feature.State()) {
    Feature()
}

store.send(.increment) {
    $0.count = 1
}

// Can use key path syntax for receiving actions
store.receive(\.response.success) {
    $0.data = "data"
}
```

## Gotchas

1. **Xcode autocomplete**: May break if you drop the explicit `Reducer` conformance. Keep it for better IDE support.

2. **Mixed observation**: Mixing old (`WithViewStore`) and new (`@ObservableState`) patterns can cause extra view re-renders. Migrate from the root feature down to child features for best results.

3. **iOS 16 and earlier**: Use `@Perception.Bindable` instead of `@Bindable`, and wrap view bodies with `WithPerceptionTracking { }` if needed.

4. **Property wrappers and macros**: Swift macros cannot be used with property wrappers, which is why `@PresentationState` became `@Presents`.

## Resources

- Official migration guides: `history/TCA-MigrationGuides/`
- TCA Documentation: https://pointfreeco.github.io/swift-composable-architecture/
- Case Paths Library: https://github.com/pointfreeco/swift-case-paths

## Summary

The modern TCA API emphasizes:
- **Less boilerplate**: Macros handle repetitive code
- **Key path syntax**: More familiar and concise
- **Direct observation**: No ViewStore wrapper needed
- **SwiftUI integration**: Use vanilla SwiftUI patterns

These changes make TCA code more readable and maintainable while preserving its powerful architecture.
