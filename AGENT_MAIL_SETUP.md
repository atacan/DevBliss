# Agent Mail Setup Guide for DevBliss

## One-Time Setup (do this once)

### 1. Install agent_mail globally

```bash
# One-line installer (recommended)
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/mcp_agent_mail/main/scripts/install.sh?$(date +%s)" | bash -s -- --yes
```

This will:
- Install Python 3.14 and uv if needed
- Create a virtual environment for agent_mail
- Start the server on port 8765
- Generate a bearer token
- Create an `am` alias for quick startup

**Save the bearer token** from the output. You'll need it.

### 2. Configure environment

Add to your shell profile (`.zshrc`, `.bashrc`, etc.):

```bash
# Agent Mail
export AGENT_MAIL_TOKEN="<paste-your-token-here>"
export AGENT_MAIL_PROJECT_KEY="/Users/atacan/Developer/Repositories/DevBliss"
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Every Session

### 1. Start the agent_mail server

```bash
am
```

You should see:
```
Server running on http://127.0.0.1:8765
```

**Leave this running** in the background while you work.

### 2. Register your agent identity (once per session)

In your Claude Code console or tool context, run:

```
ensure_project("/Users/atacan/Developer/Repositories/DevBliss")
register_agent(
  project_key="/Users/atacan/Developer/Repositories/DevBliss",
  program="Claude Code",
  model="Claude 3.5 Sonnet",
  name="<Your Agent Name>"
)
```

**Name ideas:**
- PurpleGarden, BlueLake, GreenCastle
- SilverFox, GoldenEagle, OrangeFox
- PinkFlower, IvoryTower, CrimsonWolf

### 3. You're ready to coordinate!

## Common Tasks

### Check what other agents are working on

```
list_agents(project_key="/Users/atacan/Developer/Repositories/DevBliss")
fetch_inbox(project_key="/Users/atacan/Developer/Repositories/DevBliss", agent_name="<your-name>", limit=10)
```

### Start a task

1. Pick an issue from Beads:
   ```bash
   bd ready --json | jq '.[0]'
   ```

2. Announce it to other agents:
   ```
   send_message(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     sender_name="<your-name>",
     subject="[bd-123] Starting: Brief description",
     body_md="I'm working on bd-123. Files I'll touch: Sources/MyFeature/...",
     thread_id="bd-123"
   )
   ```

3. Reserve the files you'll edit:
   ```
   file_reservation_paths(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     agent_name="<your-name>",
     paths=["Sources/MyFeature/**"],
     ttl_seconds=3600,
     exclusive=true,
     reason="bd-123"
   )
   ```

### Check for conflicts before editing

If another agent is already reserving files you need:

```
# See all active reservations
search_messages(
  project_key="/Users/atacan/Developer/Repositories/DevBliss",
  query="file_reservation"
)

# Or browse the web UI
# Open: http://127.0.0.1:8765/mail
```

### Ask another agent for help

```
send_message(
  project_key="/Users/atacan/Developer/Repositories/DevBliss",
  sender_name="<your-name>",
  to=["<other-agent-name>"],
  subject="Question about API design",
  body_md="I'm stuck on the authentication flow. Can you review the approach at Sources/Auth/...",
  thread_id="bd-123"
)
```

They'll see your message in their inbox.

### Complete a task

1. Release your file reservations:
   ```
   release_file_reservations(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     agent_name="<your-name>"
   )
   ```

2. Close the Beads issue:
   ```bash
   bd close bd-123 --reason "Completed"
   ```

3. Announce completion:
   ```
   send_message(
     project_key="/Users/atacan/Developer/Repositories/DevBliss",
     sender_name="<your-name>",
     subject="[bd-123] Completed",
     body_md="Implementation complete. Ready for review. PR: #...",
     thread_id="bd-123"
   )
   ```

## Web UI

Browse all messages, threads, and reservations:

```bash
# After agent_mail is running
open http://127.0.0.1:8765/mail
```

Features:
- Search message history
- Browse per-agent inboxes
- See all active file reservations
- Track who's working on what

## Troubleshooting

### "Server not found" error

Make sure agent_mail is running:
```bash
am
```

### "Bearer token invalid" error

Check your token is set:
```bash
echo $AGENT_MAIL_TOKEN
```

If empty, get it from the server startup output and add to your `.zshrc`/`.bashrc`.

### "Agent not registered" error

Register before using other tools:
```
ensure_project("/Users/atacan/Developer/Repositories/DevBliss")
register_agent(project_key="...", program="Claude Code", model="Claude 3.5", name="<your-name>")
```

### Can't send message to another agent

Check their contact policy. By default, agents use `auto` policy which allows messages in:
- Same thread
- Files you both reserved

If blocked, request contact:
```
request_contact(
  project_key="/Users/atacan/Developer/Repositories/DevBliss",
  from_agent="<your-name>",
  to_agent="<their-name>",
  reason="Coordinating on bd-123"
)
```

The other agent needs to approve:
```
respond_contact(
  project_key="/Users/atacan/Developer/Repositories/DevBliss",
  to_agent="<their-name>",
  from_agent="<your-name>",
  accept=true
)
```

## Best Practices

✅ **DO:**
- Use meaningful agent names (adjective+noun)
- Link messages to Beads issues with `thread_id="bd-123"`
- Reserve files before you start editing
- Check other agents' inboxes before starting
- Release file reservations when done
- Use the web UI to browse activity

❌ **DON'T:**
- Forget to register before using tools
- Hold file reservations for more than a few hours
- Edit files another agent has exclusively reserved
- Send unsolicited messages to agents with `contacts_only` policy

## Integration with Beads

Keep task tracking and communication in sync:

```bash
# Create a task
bd create "Implement dashboard UI" -t feature -p 1 --json

# Take note of issue ID (e.g., bd-42)

# Send message linked to it
# (Use thread_id="bd-42" when sending)

# Close issue when done
bd close bd-42 --reason "Completed"
```

## Need Help?

- **Setup issues**: Check `.claude/agent-mail.local.md`
- **Agent Mail docs**: https://github.com/Dicklesworthstone/mcp_agent_mail
- **Beads docs**: https://github.com/steveyegge/beads
- **Web UI**: http://127.0.0.1:8765/mail (browse the actual system)
