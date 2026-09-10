# Loading axis

**When an artifact loads** — the second axis of placement, independent of [tier](tier.md) (*who*
inherits it). Choosing a tier without choosing a loading mode is what lets the
[always-on budget](always-on-budget.md) grow unnoticed.

Claude Code supports three settings:

| Mode | Mechanism | Loads |
|---|---|---|
| **Always-on** | a `CLAUDE.md` block, at any tier | every turn |
| **Lazy by file pattern** | `.claude/rules/<name>.md` **with `paths:` frontmatter** | only when a matching file is read |
| **Lazy by invocation** | a skill | only the body; `name` + `description` stay always-on |

Two details that decide designs:

- **A rule file *without* `paths:` frontmatter loads eagerly.** The frontmatter is the entire
  mechanism — omit it and you have moved a block, not made it lazy.
- **`@path` imports expand eagerly** (4-hop max). They reorganise a file; they do not reduce its
  cost. This is the plausible-looking non-solution.

`~/.claude/rules/` works at user tier, which is the useful combination: a path-scoped user rule has
universal reach *and* zero cost when irrelevant. Stack packs (SQL, .NET, Python, PowerShell) belong
here rather than at the repo tier — strictly better on both axes at once.

## Caveats

- Path-scoped rules fire when Claude **reads a matching file**. A rule that should apply while
  *planning*, before any file is opened, is a bad fit and stays always-on.
- A glob that is slightly wrong fails **silently** — the same invisible failure as a pack installed
  at an unreachable tier. See [activation](activation.md).
- Tooling gap as of 2026-09-09: `baseline.ps1` **detects** rules (`status` reports `user-rule` /
  `local-rule` layers) but cannot **write** them; `apply` maps `claude` to `CLAUDE.md` only.
