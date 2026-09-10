# Glossary — this toolkit's own vocabulary

> **Purpose:** terms this toolkit's docs kept re-explaining inline. Go here first when a term
> appears in a `SKILL.md`, `flow.md`, or `baseline.md` and its exact meaning matters. This is the
> toolkit's *own* vocabulary — how its machinery works — not general AI or engineering terminology.
>
> **One file per term** (not one growing file) — easier to link to from a skill or flow, and easier
> to scan the list below for what's covered.

## Terms

| Term | File | One-line hook |
|---|---|---|
| Activation | [activation.md](activation.md) | Whether a rule is *reachable* by the session, as opposed to whether it is well written. The toolkit's dominant failure mode. |
| Always-on budget | [always-on-budget.md](always-on-budget.md) | Context billed on every turn. Fixed, not append-only — the scarce resource all placement decisions trade against. |
| Core / full split | [core-full-split.md](core-full-split.md) | Two renderings of one pack: an append-only reference, and a bounded slim version that is the only thing installed always-on. |
| Guard | [guard.md](guard.md) | The condition required to leave a state. Declared, detectable, not enforced. |
| Loading axis | [loading-axis.md](loading-axis.md) | *When* an artifact loads — independent of *who* inherits it. The second axis, long unused. |
| Tier | [tier.md](tier.md) | *Who* inherits an artifact: user, workspace, or repo. |

## How to add a term

New file, `kebab-case-term.md`, one row added to the table above.

**When does a concept earn its own file?** Once it is a distinct named mechanism — not just a field
or flag on another term — and it is referenced from **two or more** other entries or artifacts. If a
term meets that bar but has no file yet, say so explicitly in a line right here rather than leaving
the gap silent.

**Candidates that do not yet clear the bar:** *exit log*, *provenance*, *recurrence / reopen*,
*flow*, *terminal state*, *path-scoped rule*. Each is currently defined where it is used
(`flows/README.md`, `flows/improvement-pipeline/flow.md`, `baseline-gap-review` step 7). Promote one
here the moment a second artifact needs it.
