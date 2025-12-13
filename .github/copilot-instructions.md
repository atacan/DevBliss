# GitHub Copilot Instructions for DevBliss

## Project Overview

**DevBliss** is a Swift application for iOS. We use **bd (beads)** for all task tracking and AI-assisted development.

## Tech Stack

- **Language**: Swift 5.9+
- **Platform**: iOS
- **Build System**: Swift Package Manager
- **Testing**: XCTest
- **CI/CD**: GitHub Actions
- **Localization**: Strings file format

## Issue Tracking with bd

**CRITICAL**: This project uses **bd** for ALL task tracking. Do NOT create markdown TODO lists.

### Essential Commands

```bash
# Find work
bd ready --json                    # Unblocked issues
bd list --json                     # All issues

# Create and manage
bd create "Title" -t bug|feature|task|chore -p 0-4 --json
bd update <id> --status in_progress --json
bd close <id> --reason "Done" --json

# Discover new work during development
bd create "Found issue" -p 1 --json  # Create new issue
bd dep add <new-id> <parent-id> --type discovered-from  # Link to parent task

# Sync changes (run at end of session!)
bd sync
```

### Workflow

1. **Check ready work**: `bd ready --json` - see what's not blocked
2. **Claim task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Discover new work?** 
   ```bash
   bd create "Found bug or TODO" -t bug -p 1 --json
   bd dep add <new-id> <current-task-id> --type discovered-from
   ```
5. **Complete**: `bd close <id> --reason "Completed"`
6. **Sync**: `bd sync` - ensures database syncs with git

### Priorities

- `0` - Critical (security, crashes, data loss)
- `1` - High (major features, important bugs)
- `2` - Medium (default, regular work)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Issue Types

- `bug` - Something broken or incorrect
- `feature` - New functionality
- `task` - Work item (refactoring, tests, docs)
- `chore` - Maintenance (dependencies, cleanup)

## Project Structure

```
DevBliss/
├── App/                 # iOS app resources
├── Sources/             # Swift source code
│   ├── Views/          # SwiftUI views
│   ├── Models/         # Data models
│   └── ...
├── Tests/              # Unit tests
├── Package.swift       # Swift Package manifest
├── .beads/             # Issue tracker database (auto-managed)
│   └── issues.jsonl    # Synced with git
└── AGENTS.md           # Full workflow documentation
```

## Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic bd commands
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ✅ Run `bd sync` at end of sessions
- ✅ Commit `.beads/issues.jsonl` together with code changes
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT clutter AGENTS.md with implementation details

---

**For detailed workflows and advanced features, see [AGENTS.md](../AGENTS.md)**
