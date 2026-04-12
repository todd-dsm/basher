# Reference Format

How each section in `reference.md` is structured. Follow this for every construct.

## Section Anatomy

```
## Concept Name

<!-- One-line context for the AI caller — what this construct is and when it matters. -->

```bash
# DO
<correct form>

# DON'T
<wrong form>    # inline reason why it's wrong
```

Rules:
- Directive. No hedging.
	- *Why this rule exists.*
- Next directive.
	- *Why.*

Further research:
1. [Link to shallowest authoritative source](URL): the basics.
2. [Link to deeper source](URL): edge cases.

---

```
## Constraints

- **Heading**: `##` level. The concept name — one or two words.
- **HTML comment**: One line. States why this construct matters — the stakes of getting it wrong. Not a definition; the rules carry the "what". Not rendered on GitHub.
- **Code block**: `bash` fence. DO first, DON'T second. Each DON'T gets an inline comment explaining the failure mode.
- **Rules**: Directives the agent must follow. Each rule is a concrete instruction, not a principle. Sub-bullet in italics carries the rationale. Order rules by what the agent needs first for correct output.
- **Further research**: Numbered list of authoritative external links. Ordered shallow to deep — the first link handles the common case, later links cover edge cases. Omit the section if no authoritative source applies.
- **Separator**: `---` after every section. Hard boundary between concepts.
- **Brevity**: every element earns its place. If removing a line doesn't lose information, remove it.
```
