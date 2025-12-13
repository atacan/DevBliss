# Agent Instructions for DevBliss

## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**
```bash
bd ready --json
```

**Create new issues:**
```bash
bd create "Issue title" -t bug|feature|task -p 0-4 --json
bd create "Issue title" -p 1 --deps discovered-from:bd-123 --json
bd create "Subtask" --parent <epic-id> --json  # Hierarchical subtask (gets ID like epic-id.1)
```

**Claim and update:**
```bash
bd update bd-42 --status in_progress --json
bd update bd-42 --priority 1 --json
```

**Complete work:**
```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`
6. **Commit together**: Always commit the `.beads/issues.jsonl` file together with the code changes so issue state stays in sync with code state

### Auto-Sync

bd automatically syncs with git:
- Exports to `.beads/issues.jsonl` after changes (5s debounce)
- Imports from JSONL when newer (e.g., after `git pull`)
- No manual export/import needed!

## Full Beads Documentation

This project uses [Beads](https://github.com/steveyegge/beads) for issue tracking and task management. Before working on any tasks, read the following:

### Quick Start with Beads

When you start working, use the `bd` command instead of creating markdown files for task management:

```bash
# Find ready work (issues with no blockers)
bd ready --json | jq '.[0]'

# Create issues during work
bd create "Issue description" -t bug -p 1 --json

# Update status
bd update <issue-id> --status in_progress

# Close completed work
bd close <issue-id> --reason "Implemented"
```

### Core Beads Workflow

1. **Check ready work first**: `bd ready` shows issues you can start immediately
2. **Create issues for discovered work**: If you find bugs or TODOs, file them with `bd create`
3. **Link related work**: Use `bd dep add` to connect issues
4. **Update status**: Move issues through `open` → `in_progress` → `closed`
5. **End session carefully**: Close completed work, file discovered issues, sync the database

### Key Commands

```bash
# Query
bd ready              # Show ready work (no blockers)
bd list               # Show all issues
bd show <id>          # View issue details
bd dep tree <id>      # See dependencies

# Create/Update
bd create "..."       # Create new issue
bd update <id> --status in_progress  # Update status
bd close <id>         # Close issue

# Dependencies (blocks, related, parent-child, discovered-from)
bd dep add <issue> <blocker> --type blocks  # Make blocker required
bd dep add <issue> <parent> --type parent-child  # Hierarchical

# Sync (automatic, but manual when needed)
bd sync               # Force sync with git
```

### End-of-Session Protocol

Before finishing your session:

1. **File remaining work**: Create issues for any discovered bugs, TODOs, or follow-up tasks
2. **Close completed issues**: Mark finished work as closed with `bd close`
3. **Update in-progress**: Ensure active work shows correct status
4. **Sync the database**: `bd sync` (or let auto-sync handle it after 5 seconds)
5. **Commit and push**: Git push to sync beads database with the team

### Issue Types & Priorities

Use these when creating issues:

- **Types**: `bug`, `feature`, `task`, `epic`, `chore`
- **Priorities**: `0` (highest), `1`, `2` (default), `3`, `4` (lowest)
- **Labels**: Use tags like `backend`, `swift`, `ui`, `tests`, etc.

### Examples

```bash
# Create a bug
bd create "Auth token validation fails on logout" -t bug -p 1 -l auth,critical

# Create a feature
bd create "Add dark mode support" -t feature -p 2 -l ui,frontend

# Create a task with description
bd create "Refactor authentication module" -t task -p 2 \
  -d "Split into smaller, testable functions" -l backend,refactor

# Link work: new-task depends on bug-fix
bd dep add <new-issue-id> <bug-fix-id> --type blocks
```

### Discovering Work During Development

When you find issues while working:

```bash
# Create discovered issue
bd create "Potential memory leak in networking layer" -t bug -p 1

# Link it back to current work
bd dep add <discovered-id> <current-task-id> --type discovered-from
```

### Status Values

- `open` - Ready to start or actively being worked
- `in_progress` - Currently being developed
- `closed` - Completed or resolved

### More Help

- Run `bd --help` for CLI reference
- Run `bd quickstart` for interactive tutorial
- See `.beads/README.md` for architecture overview
- Check https://github.com/steveyegge/beads for full documentation

### Integration with Development

When implementing features:
1. Check `bd ready` to understand current priorities
2. Create sub-issues for discovered bugs during implementation
3. Link them back with `bd dep add ... --type discovered-from`
4. Close issues as you complete them
5. At session end, ensure all work is tracked and synced

The goal: your agent maintains perfect memory of project state across sessions and helps coordinate work across the team.

## Agent Communication with MCP Agent Mail

**IMPORTANT**: This project now uses **MCP Agent Mail** for agent-to-agent coordination. Use it when multiple agents are working simultaneously to avoid conflicts and stay synchronized.

### What is Agent Mail?

Agent Mail is an asynchronous messaging and file coordination system that lets agents:

- Exchange messages and updates (like email for agents)
- Signal file editing intent with reservations (avoid merge conflicts)
- Search conversation history
- Maintain a synchronized view of ongoing work

### When to Use Agent Mail

Use agent_mail when:
- Multiple agents are working on the same project simultaneously
- You need to signal which files you're editing (file reservations)
- You want to leave notes or progress updates for other agents
- You're splitting work across frontend/backend or other boundaries

### Quick Start

1. **Start the server** (if not already running):
   ```bash
   am
   # or: cd /path/to/mcp_agent_mail && uv run python -m mcp_agent_mail.cli serve-http
   ```

2. **Register your identity** (once per session):
   ```
   ensure_project("/Users/atacan/Developer/Repositories/DevBliss")
   register_agent(project_key="/Users/atacan/Developer/Repositories/DevBliss", program="Claude Code", model="Claude 3.5", name="<your-agent-name>")
   ```

3. **Reserve files before editing**:
   ```
   file_reservation_paths(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     agent_name="<your-name>",
     paths=["Sources/MyFeature/**"],
     ttl_seconds=3600,
     exclusive=true,
     reason="Implementing feature bd-123"
   )
   ```

4. **Send a message** to announce your work:
   ```
   send_message(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     sender_name="<your-name>",
     subject="[bd-123] Starting implementation",
     body_md="Working on feature bd-123. ETA: 2 hours.",
     thread_id="bd-123"
   )
   ```

5. **Release reservations** when done:
   ```
   release_file_reservations(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     agent_name="<your-name>"
   )
   ```

### Agent Naming

Use memorable adjective+noun names (agent_mail will auto-generate if needed):
- ✅ PurpleGarden, BlueLake, GreenCastle, OrangeFox
- ❌ agent1, Agent_2, claude_code

### Best Practices

1. **Link to Beads issues**: Use `thread_id="bd-123"` to tie messages to your task
2. **Be explicit about files**: When reserving, use glob patterns matching actual edits
3. **Communicate intent**: Message subjects should be clear (`[bd-123] Starting feature X`)
4. **Release promptly**: Don't hold file reservations longer than needed
5. **Check inbox before starting**: See what other agents are working on
6. **Use the web UI**: Open `http://127.0.0.1:8765/mail` to browse messages visually

### File Reservations

Reservations signal intent to edit (not cryptographically enforced):

```
# Exclusive: "I'm the only one touching these files"
exclusive=true

# Shared: "I'm editing these, others might too"
exclusive=false

# TTL: How long to hold the reservation (default 1 hour)
ttl_seconds=3600
```

### Contact Policies

By default, agents use `auto` policy (messages allowed in same thread or with overlapping reservations).

To change:
```
set_contact_policy(
  project_key="/Users/atacan/Developer/Repositories/DevBliss",
  agent_name="<your-name>",
  policy="open"  # or "contacts_only", "auto", "block_all"
)
```

### Useful Tools

| Tool | Purpose |
|------|---------|
| `send_message` | Send a message to agents or in a thread |
| `fetch_inbox` | Check your inbox for new messages |
| `file_reservation_paths` | Reserve files before editing |
| `release_file_reservations` | Release files when done |
| `search_messages` | Search message history (FTS5) |
| `summarize_thread` | Get a summary of a conversation |
| `whois` | Look up an agent's profile |
| `list_agents` | See all registered agents |

### Configuration

See `.claude/agent-mail.local.md` for detailed setup and configuration options.

### Integration with Beads

When creating a Beads issue, use the same issue ID in your agent_mail messages:

```bash
# Create a task
bd create "Implement authentication" -t feature -p 1 --json
# Returns: bd-42

# Start working
send_message(..., thread_id="bd-42", subject="[bd-42] Starting...")

# Complete work
bd close bd-42 --reason "Completed"
send_message(..., thread_id="bd-42", subject="[bd-42] Completed")
```

This keeps task tracking and communication synchronized.
