# Reducer Migration Strategy: Manual Protocol → @Reducer Macro

**Status:** Planning Phase (DevBliss-elo)  
**Date:** December 13, 2025  
**Migration Scope:** 23 custom Reducer implementations  
**Target:** TCA 1.23.1+ @Reducer Macro Pattern

---

## Context & Constraints

### Current State (As of TCA API Audit)
- **23 Reducer implementations** using manual `Reducer` protocol conformance
- All are TCA 1.23.1+ compatible
- Code is production-ready with zero breaking changes

### TCA 1.23.1+ @Reducer Macro
The macro requires:
1. Add `@Reducer` attribute to struct
2. Remove `: Reducer` conformance (macro adds it)
3. Add `@ObservableState` to the State struct
4. Keep State, Action, and body implementation unchanged

---

## Key Risk: Nested Reducers & State

### Issue: Breaking Change with Nested State

The critical problem is **nested reducer state**. When using `@Reducer` macro:
- Parent reducer's State must be `@ObservableState`
- Child reducer's State must ALSO be `@ObservableState`
- This creates a cascading requirement across the entire hierarchy

### Example of the Problem

**Current (Works Fine):**
```swift
public struct AppReducer: Reducer {
    public struct State: Equatable {
        var childState: ChildReducer.State  // Regular struct
    }
}

public struct ChildReducer: Reducer {
    public struct State: Equatable { ... }
}
```

**With @Reducer (Breaks Bindings):**
```swift
@Reducer
public struct AppReducer {
    @ObservableState
    public struct State: Equatable {
        var childState: ChildReducer.State  // ERROR: ChildReducer.State not observable
    }
}

@Reducer
public struct ChildReducer {
    @ObservableState  // Conflicts with parent usage
    public struct State: Equatable { ... }
}
```

### Cascading Effect
- **AppReducer** depends on 9 child reducers (htmlToSwift, jsonPretty, etc.)
- **InputOutput** reducers depend on each other
- **Each** would need `@ObservableState` applied
- This affects bindings, Scopes, and view updates

---

## Migration Decision Matrix

### Option 1: Full Migration (High Risk)
**Migrate all 23 reducers to @Reducer + @ObservableState**

Pros:
- ✅ Maximum modernization
- ✅ Leverages latest TCA features
- ✅ Better integration with async/await tooling

Cons:
- ❌ High complexity due to nested state
- ❌ Requires cascading changes across entire hierarchy
- ❌ Testing burden (5 test files affected)
- ❌ Risk of breaking existing functionality
- ❌ ViewStore bindings may need rework

**Verdict:** Too risky without comprehensive testing

---

### Option 2: Hybrid Migration (Recommended)
**Migrate only non-nested, standalone reducers first**

Migrate (Candidates - No Children):
1. ✅ UUIDGeneratorReducer (simple, isolated)
2. ✅ TextCaseConverterReducer (simple)
3. ✅ JsonPrettyReducer (simple)

Don't Migrate Yet (Complex Hierarchies):
- ❌ AppReducer (has 9 children)
- ❌ InputOutput reducers (interdependent)
- ❌ NameGenerator variants (complex composition)
- ❌ FileContentSearchReducer (has effects)
- ❌ HtmlToSwiftReducer, SwiftPrettyReducer (have child scopes)

**Verdict:** Safe incremental approach with validation at each step

---

### Option 3: No Migration (Conservative)
**Keep manual Reducer protocol conformance**

Pros:
- ✅ Zero risk
- ✅ Already TCA 1.23.1+ compatible
- ✅ All 23 reducers work perfectly
- ✅ No breaking changes

Cons:
- ❌ Doesn't leverage macro convenience
- ❌ Slightly more verbose

**Verdict:** Valid long-term position; macro is optional

---

## Recommended Approach: Hybrid Migration (Option 2)

### Phase 1: Simple Reducers (Low Risk)

#### Target 1: TextCaseConverterReducer
- No child reducers
- Simple State with basic types
- Minimal dependencies
- **Risk Level:** LOW

**Migration Pattern:**
```swift
@Reducer
public struct TextCaseConverterReducer {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        @BindingState var input: String
        @BindingState var textCase: TextCase
        var output: OutputEditorReducer.State
        var isProcessing: Bool = false
        // ... rest unchanged
    }
    
    // Action, body remain unchanged
}
```

#### Target 2: JsonPrettyReducer
- No child reducers
- Simple State
- **Risk Level:** LOW

#### Target 3: UUIDGeneratorReducer
- Single child: OutputEditorReducer
- BUT: Child State stays in Scope (not nested in parent State)
- **Risk Level:** LOW-MEDIUM

---

### Phase 2: Validation & Testing

For each migrated reducer:
1. Build successfully
2. Run unit tests (if applicable)
3. Test in preview/UI
4. Commit with proper message

---

### Phase 3: Monitor & Backlog

If Phase 1 succeeds:
- Plan Phase 2 (intermediate reducers)
- Eventually address nested hierarchies

If Phase 1 shows issues:
- Revert and document findings
- Mark as "requires TCA enhancement" 
- File issue with Point-Free

---

## What NOT to Do

⚠️ **DON'T migrate these yet:**
1. **AppReducer** - 9 child scopes
2. **InputOutput reducers** - Heavily nested
3. **NameGenerator variants** - Complex composition
4. **Reducers with complex effects** - FileContentSearchReducer

---

## Success Criteria

### For Phase 1 (Simple Reducers)
- [ ] All 3 simple reducers use @Reducer macro
- [ ] All use @ObservableState correctly
- [ ] Full compilation success
- [ ] All tests pass
- [ ] Preview providers work
- [ ] Store initializations work unchanged
- [ ] No breaking changes to dependent code

### For Phase 2+ (if Phase 1 succeeds)
- [ ] Identify which complex reducers can safely migrate
- [ ] Document any special handling needed
- [ ] Plan incremental migration

---

## Implementation Notes

### Minimal Changes for Simple Reducers
1. Change `struct X: Reducer` → `@Reducer struct X`
2. Remove `: Reducer` conformance
3. Add `@ObservableState` to State struct
4. Everything else (Action, body, functions) unchanged

### Testing Checklist Per Reducer
- [ ] `swift build` succeeds
- [ ] No compilation warnings
- [ ] Unit tests pass (if present)
- [ ] Preview works
- [ ] ViewStore operations functional
- [ ] Binding operations work (if applicable)

---

## Rollback Strategy

If migration causes issues:
```bash
# Simple rollback for any single file
git checkout HEAD -- Sources/FeatureName/FeatureReducer.swift
```

All migrations are isolated, so individual revert is possible.

---

## Timeline Estimate

- **Phase 1 (Simple):** 1-2 hours
  - 3 reducers × 15 min each (edit + test)
  - Validation & documentation: 30 min

- **Phase 2 (if proceeding):** TBD after Phase 1

---

## Final Recommendation

**Start with Phase 1: Hybrid Migration**

✅ Migrate 3 simple, non-nested reducers  
✅ Validate thoroughly  
✅ Document findings  
❌ Don't force migration of complex hierarchies  

This balances modernization with risk management and provides data for future decisions.

If the three simple migrations succeed without issues, we can confidently evaluate Phase 2. If they reveal problems, we have a clear record of TCA macro limitations in this codebase.

---

**Next Steps:**
1. Get approval to proceed with Phase 1
2. Migrate TextCaseConverterReducer first (simplest)
3. Test and validate
4. Document any issues encountered
5. Plan Phase 2 based on results
