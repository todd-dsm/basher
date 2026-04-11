# Plug-in: content

## Purpose

Content creation — researching, writing, editing, and publishing quality content. This plug-in adds a parameterized Writer agent (voice-assignable) and a context-isolated Editor agent for independent review.

## Agents

- agents/writer.md
- agents/editor.md

## Agent Parameters

The Writer agent accepts a voice parameter at instantiation. Set the voice in your project's `share/plugin.md`:

```markdown
## Agents
- agents/writer.md (voice: W. Edwards Deming)
- agents/editor.md
```

If no voice is specified, the Writer defaults to a clear, neutral, professional voice.

## Test Profiles

- etc/test-profiles/global.md

## Process Modifications

- Phase 2 (Requirements): Define the content brief — audience, purpose, tone, key messages, publication target.
- Phase 3 (Design & Implementation): Writer agent produces content on a feature branch. Outline before prose. Voice parameter shapes style but does not override requirements.
- Phase 4 (Verification): Editor reviews content against requirements in parallel with QA. DEFECT findings require revision before promotion.
- Phase 5 (Validation): PM validates the content serves its stated purpose and is ready for publication.
- Phase 6 (Commit): Content integrity check — no placeholder text, no unresolved TODOs, no orphaned references.
- Phase 7 (Merge): Requires /merge-to-main skill (decision 0014). Direct `git merge main` is blocked by hook.
