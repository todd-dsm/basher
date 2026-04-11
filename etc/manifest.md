# Knowledge Manifest

What the system knows, where it lives, and who needs it. Agents read this at spawn time to discover available knowledge. Retrieve only what your role requires.

Updated by the scribe whenever knowledge is added, changed, or removed.

---

## Schema Contract

This manifest follows a fixed schema. The Scribe populates rows. The Scribe does not modify the schema.

| Rule | Constraint |
|------|-----------|
| Columns | Exactly 4: Topic, Location, Summary, Relevant To |
| Categories | `###` headings. Do not add, remove, or rename category headings in the Universal Knowledge section. Project sections are extensible. |
| Location values | Relative paths from repo root. Must resolve to an existing file. |
| Relevant To | Role names from `docs/process-feature-development.md`: PM, PE, QA, Scribe, $engineer, Security, domain specialists |
| Row operations | Add rows, update rows, remove rows. Do not alter column structure. |

---

## Universal Knowledge (provided by Cascadian plugin)

### Foundations

| Topic | Location | Summary | Relevant To |
|-------|----------|---------|-------------|
| IEEE Standards Framework | `etc/foundations/standards-framework.md` | 12207, 730, 29148, 14764 process groups. Process tailoring rules | PE, QA |
| Deming Philosophy | `etc/foundations/deming.md` | System of Profound Knowledge, 14 Points, PDSA, Chain Reaction | All roles |
| Documentation Standards | `etc/foundations/documentation-standards.md` | 15289, 26514, 26513, 26515. Seven generic document types | Scribe, PE |

### Rules

| Topic | Location | Summary | Relevant To |
|-------|----------|---------|-------------|
| Universal Rules | `etc/rules-universal.md` | 7 governing rules derived from Deming | All roles |
| Project Rules | `etc/rules-project.md` | Project-specific: aim, domain constraints, technical decisions, active context | PM, PE |

### Agents

| Topic                | Location                             | Summary                                                                  | Relevant To   |
| -------------------- | ------------------------------------ | ------------------------------------------------------------------------ | ------------- |
| PE (Process Expert)  | `skills/process-expert/`             | The translator. Stakeholder → technical requirements. Orchestrates team  | All roles     |
| QA                   | `skills/quality-assurance/SKILL.md`  | Verification + Validation. Drift detection, IEEE 730 SQA                 | PE, $engineer |
| Scribe               | `skills/scribe/SKILL.md`             | Write side of coherence cascade. Knowledge capture, manifest maintenance | All roles     |
| $engineer (backend)  | `skills/implement-backend/SKILL.md`  | The implementer. Parameterized by domain                                 | PE, QA        |
| $engineer (frontend) | `skills/implement-frontend/SKILL.md` | The implementer. Parameterized by domain                                 | PE, QA        |
| $engineer (platform) | `skills/implement-platform/SKILL.md` | The implementer. Parameterized by domain                                 | PE, QA        |

### Skills

| Topic | Location | Summary | Relevant To |
|-------|----------|---------|-------------|
| Scribe Skill | `skills/scribe/SKILL.md` | Write side of coherence cascade. Document types, quality criteria | All roles |
| Project Init | `skills/project-init/SKILL.md` | Archetype-aware project initialization with interview and invariant verification | PE |

### Operations

| Topic | Location | Summary | Relevant To |
|-------|----------|---------|-------------|
| Feature Development Process | `docs/process-feature-development.md` | Seven-phase PDSA cycle. Roles, V&V, maintenance variants, exit criteria | All roles |
| Hooks | `docs/hooks.md` | Process enforcement hooks. Config: `hooks/hooks.json`, scripts: `bin/` | All roles |
| Parameters | `docs/parameters.md` | Tunable parameters ($doubt). Set in `etc/rules-project.md` | PM, PE |

---

## Project: basher

### Architecture & Design

| Topic | Location | Summary | Relevant To |
|-------|----------|---------|-------------|

### Decisions

| ID | Decision | Location | Date |
|----|----------|----------|------|

### Lessons Learned

| Lesson | Location | Date |
|--------|----------|------|

---

## How to Use This Manifest

**At spawn time**: read this file. Identify which topics are relevant to your assigned role and task. Retrieve only those files.

**During work**: if you encounter a gap — a question the manifest suggests has been answered elsewhere — retrieve the relevant document before proceeding.

**After producing knowledge**: invoke the scribe to document findings AND update this manifest. Knowledge that isn't in the manifest doesn't exist to other agents.
