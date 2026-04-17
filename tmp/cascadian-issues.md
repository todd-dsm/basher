# Cascadian issues — surfaced during basher target.sh development

Logged 2026-04-16. These are discoverability and process gaps in cascadian observed during a real session.

---

## CI-1. Decision 0008 (backlog location) not discoverable at point of action

**What happened:** Agent proposed adding backlog items to `tmp/outstanding.md`. OP had to prompt "cascadian should have made this clear." Agent then grepped the plugin cache to find decision 0008 (GitHub Issues as backlog source of truth).

**Root cause:** The knowledge tree references "where backlogs live" abstractly but the actual rule (`gh issue create --label backlog`) isn't surfaced when an agent is about to record a work item. The decisions directory doesn't exist in basher — it lives in cascadian's plugin cache, requiring a deep search.

**Expected behavior:** When an agent proposes recording a backlog item in a markdown file, the decision should be immediately accessible — either via the session hook, the rules-project file, or the knowledge tree entry being specific enough to act on without further lookup.

