# Always-on budget

**Context billed on every turn, in every session, in every directory that inherits it.**

Claude Code concatenates instruction files rather than overriding them, so everything installed
always-on accumulates. That makes it a **fixed budget, not an append-only log** — every bullet added
is paid for on every turn forever, including sessions with nothing to do with it.

## The documented ceiling

Claude Code's own guidance targets **under 200 lines per `CLAUDE.md`**, and notes that files past
that consume more context *and reduce adherence* — so overrunning it makes the packs less effective,
not merely more expensive. Measured 2026-09-09: `~/.claude/CLAUDE.md` reached **189 lines** after
installing five packs, one of which (86 lines) was 46% of the file on its own.

## Why this shapes every placement decision

An artifact's cost depends entirely on its [loading axis](loading-axis.md):

| Loading | Always-on cost |
|---|---|
| `CLAUDE.md` block | full, every turn |
| `@path` import | **full, every turn** — imports expand eagerly; they reorganise, they do not reduce |
| path-scoped rule (`paths:` frontmatter) | zero until a matching file is read |
| skill body | zero until invoked (name + description only) |

The `@path` row is the trap: it looks like the obvious fix and is not one.

## How to spend it

- Reserve it for judgment that must fire **unprompted** — things you would not know to go looking
  for. Anything you would reach for by name belongs in a skill.
- Anything file-type-scoped becomes a path-scoped rule instead of a block.
- Everything else uses the [core / full split](core-full-split.md), which bounds the cost by
  construction rather than by periodic deletion.

## Related

- [tier](tier.md) — raising an artifact's tier multiplies its budget cost by the number of repos below it.
