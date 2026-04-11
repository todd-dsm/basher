# Plugin Instructions

A plugin is a markdown file that tells Cascadian the purpose of your project and what domain-specific capabilities it needs beyond core.

## How plugins work

Cascadian core provides process discipline, knowledge architecture, and framework agents (PE, QA, Scribe) for every project. A plugin adds domain-specific agents, test profiles, and process modifications on top of core.

```
Plugin (project-level) — share/plugin.md
─────────────────────────────────────────
Core (global) — always-on framework
```

Cascadian loads `share/plugin.md` at session start. One plugin active per project.

## Activating a plug-in

The default plug-in is `software`. Its agents (`agents/full-stack.md`, `agents/security.md`) are always active. To switch to a different plug-in:

```bash
cp share/plugins/plugin-content.md share/plugin.md
```

Non-default plug-ins store their agents in `share/agents/`. When activating a plug-in, copy its agents to the project's `agents/` directory:

```bash
cp share/agents/writer.md agents/
cp share/agents/editor.md agents/
```

Cascadian loads whatever is at `share/plugin.md` and discovers agents in `agents/`.

## Composing plugins

A plugin can pull in additional capabilities via `## Extensions`:

```markdown
## Extensions
- share/plugins/plugin-content.md
```

The primary plugin's `## Purpose` stays authoritative. Extensions add agents and capabilities — they don't redefine the mission.

## Writing your own plugin

A plugin file must contain these headings:

### Required

- `# Plugin: <name>` — the plugin identity
- `## Purpose` — what this project is for. One paragraph. This replaces the default software framing. Cascadian uses this to orient all agents toward the project's actual mission.
- `## Agents` — list of agent definition files (paths relative to project root). Place custom agents in your project's `agents/` directory — Cascadian discovers them by conventional path.

### Optional

- `## Test Profiles` — security/quality test profiles to activate (paths relative to plugin root)
- `## Process Modifications` — overrides or additions to the core PDSA cycle
- `## Extensions` — references to other plugin files whose agents and capabilities are composed with this plugin

## Conventions

- Default plug-in agents live in `agents/` — always active
- Non-default plug-in agents are stored dormant in `share/agents/` — copy to `agents/` to activate
- Test profiles go in `etc/test-profiles/` — the security agent reads from there
- One plugin active at a time (`share/plugin.md`), composed via extensions
- Core agents (PE, QA, Scribe) are always available — plugins add to them, never replace them
- Scribe activation is a core process guarantee — it always runs after Gate 2 approval. Plugins can define additional Scribe triggers via `## Process Modifications` but cannot suppress the core activation.
