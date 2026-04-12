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

RULES:
- Directive. No hedging.
	- *Why this rule exists.*
- Next directive.
	- *Why.*

---

```
## Constraints

- **Heading**: `##` level. The concept name — one or two words.
- **HTML comment**: One line. Orients the agent before the code block. Not rendered on GitHub.
- **Code block**: `bash` fence. DO first, DON'T second. Each DON'T gets an inline comment explaining the failure mode.
- **RULES**: Directives the agent must follow. Each rule is a concrete instruction, not a principle. Sub-bullet in italics carries the rationale.
- **Separator**: `---` after every section. Hard boundary between concepts.
- **Brevity**: every element earns its place. If removing a line doesn't lose information, remove it.
```
