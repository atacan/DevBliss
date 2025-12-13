---yaml
enabled: true
mcp-server: agent-mail
project-key: /Users/atacan/Developer/Repositories/DevBliss
agent-mail-port: 8765
---

# Agent Mail Configuration for DevBliss

Agent Mail provides asynchronous messaging and coordination for multiple coding agents working on the DevBliss project.

## Setup

### Prerequisites

1. Install agent_mail globally or locally:

```bash
# One-line installer (recommended)
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/mcp_agent_mail/main/scripts/install.sh?$(date +%s)" | bash -s -- --yes

# Or from local clone
cd /path/to/mcp_agent_mail
uv sync
uv run python -m mcp_agent_mail.cli serve-http
```

2. Start the agent_mail server on port 8765:

```bash
# If installed globally
am

# If running locally
cd /path/to/mcp_agent_mail
uv run python -m mcp_agent_mail.cli serve-http
```

3. Capture the bearer token from the startup output and set:

```bash
export AGENT_MAIL_TOKEN=<your-token-here>
```

### Quick Start

Once the server is running and token is set, agents can immediately:

```bash
# Check inbox for messages
mcp__plugin_agent_mail_agent_mail__fetch_inbox

# Send a message to another agent
mcp__plugin_agent_mail_agent_mail__send_message

# Check file reservations
mcp__plugin_agent_mail_agent_mail__file_reservation_paths

# Search messages
mcp__plugin_agent_mail_agent_mail__search_messages
```

## Agent Identity

When using agent_mail, register your identity first:

```
Project Key: /Users/atacan/Developer/Repositories/DevBliss
Agent Name: <descriptive-adjective-noun-pair, e.g., "PurpleGarden">
Program: Claude Code (or your tool name)
Model: Claude 3.5 Sonnet (or your model)
```

## Key Tools

### Messaging

- **send_message**: Send a message to one or more agents
- **fetch_inbox**: Check your inbox for new messages
- **reply_message**: Reply to a specific message in a thread
- **acknowledge_message**: Mark a message as acknowledged
- **search_messages**: Search message history (FTS5)

### Coordination

- **file_reservation_paths**: Reserve files to signal editing intent (avoid conflicts)
- **release_file_reservations**: Release file reservations when done
- **whois**: Look up another agent's profile
- **list_agents**: See all registered agents in the project

### Thread Management

- **summarize_thread**: Get a summary of a conversation thread
- **send_message** with `thread_id`: Continue an existing conversation

## Workflow

### Recommended Workflow for Agents

1. **Register identity** (once per session):
   ```
   ensure_project(project_key="/Users/atacan/Developer/Repositories/DevBliss")
   register_agent(project_key="...", program="Claude Code", model="Claude 3.5", name="<your-name>")
   ```

2. **Reserve editing surface** (before making changes):
   ```
   file_reservation_paths(
     project_key="...",
     agent_name="<your-name>",
     paths=["Sources/**"],  // glob patterns
     ttl_seconds=3600,       // 1 hour
     exclusive=true,         // avoid conflicts
     reason="Implementing feature X"
   )
   ```

3. **Announce work** (so others know what you're doing):
   ```
   send_message(
     project_key="...",
     sender_name="<your-name>",
     to=["<other-agent>"],  // optional
     subject="[bd-123] Starting: Implement API endpoints",
     body_md="# Plan\n\n- Create /api/users\n- Add auth middleware\n- Write tests",
     thread_id="bd-123"  // link to Beads issue
   )
   ```

4. **Coordinate as needed** (ask, reply, share progress):
   ```
   reply_message(
     project_key="...",
     message_id=<id>,
     sender_name="<your-name>",
     body_md="Progress: API endpoints done. Starting tests."
   )
   ```

5. **Release and close**:
   ```
   release_file_reservations(
     project_key="...",
     agent_name="<your-name>",
     reason="Completed implementation"
   )
   
   send_message(
     project_key="...",
     sender_name="<your-name>",
     subject="[bd-123] Completed: API endpoints ready for review",
     body_md="Implementation complete. All tests passing.",
     thread_id="bd-123"
   )
   ```

## Contact Policies

By default, agents use `auto` contact policy:
- Messages are allowed within the same thread
- Messages are allowed if you're both reserving overlapping files
- Otherwise, agents must request contact first

To change your contact policy:

```
set_contact_policy(
  project_key="...",
  agent_name="<your-name>",
  policy="open"  // or "auto", "contacts_only", "block_all"
)
```

## File Reservations

File reservations are **advisory** (they don't block edits, but they signal intent and avoid conflicts):

- **Exclusive**: "I'm the only one editing these files right now"
- **Shared**: "I'm editing these files, but others might too"

The optional pre-commit hook can block commits that violate exclusive reservations by other agents (set `AGENT_NAME` env var for this to work).

## Resources

Check your inbox and threads with resources (read-only):

```
resource://inbox/<agent-name>?project=<project-key>&limit=20
resource://thread/<thread-id>?project=<project-key>&include_bodies=true
```

## Web UI

Browse messages, threads, and file reservations:

```bash
# After starting server on port 8765
open http://127.0.0.1:8765/mail
```

## Troubleshooting

### Server not running

```bash
# Start the server
am
# or
cd /path/to/mcp_agent_mail && uv run python -m mcp_agent_mail.cli serve-http
```

### Token not set

```bash
# Get token from server startup output
export AGENT_MAIL_TOKEN=<your-token>
```

### Agent not registered

```
# Always register first (call in context)
ensure_project(project_key="/Users/atacan/Developer/Repositories/DevBliss")
register_agent(project_key="...", program="Claude Code", model="Claude 3.5", name="<your-name>")
```

### Can't send messages

- Check contact policy: `list_contacts` shows approved contacts
- Request contact: `request_contact(from_agent="<you>", to_agent="<them>", reason="coordination")`
- Approve contact from the recipient side: `respond_contact(to_agent="<recipient>", from_agent="<you>", accept=true)`

## Integration with Beads

Link messages to Beads issues by using `thread_id="bd-123"` when sending messages. This keeps your task tracking and communication in sync:

```bash
# Create a task
bd create "Implement authentication" -t feature -p 1 --json

# Take note of the issue ID (e.g., bd-42)

# Send a message linked to it
mcp__plugin_agent_mail_agent_mail__send_message(
  thread_id="bd-42",
  subject="[bd-42] Starting: Implement authentication"
)
```

## Security Notes

- Bearer tokens are sent with each request; use HTTPS in production
- File reservations are advisory and not cryptographically enforced
- All messages are stored in the local Git repo and searchable
- The web UI serves on localhost by default (set `HTTP_ALLOW_LOCALHOST_UNAUTHENTICATED=true` for dev)
