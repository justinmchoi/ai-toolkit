# Tier

**Who inherits an artifact** — one of the two axes of placement. The other is the
[loading axis](loading-axis.md); they are independent and both must be chosen.

| Tier | Target | Holds packs that are… |
|---|---|---|
| **User** | `~/.claude/` | true of all work, any language, any employer |
| **Workspace** | any directory containing many repos | true of one org's repos but not personal ones |
| **Repo** | the repo root | stack- or product-specific |

Claude Code resolves instruction files from `~/.claude/CLAUDE.md` **and** by walking up every parent
directory of the working directory. So a pack applied once at a high tier reaches every descendant,
including repos cloned later — which is the point.

## Rules of thumb

- Apply a pack at the **highest tier where it is still correct**. Too high is noise, and noise is
  what dilutes the packs that matter.
- **Never apply the same pack at two tiers.** Blocks are keyed by pack *name*, so both end up in
  context at once, silently, at possibly different versions. `baseline status` shows every source
  for a pack — use it to catch this after any move.
- Raising a tier multiplies its [always-on budget](always-on-budget.md) cost by the number of repos
  beneath it. Pair a tier increase with the [core / full split](core-full-split.md).
- **Only Claude inherits.** `AGENTS.md` (Codex) and `.github/copilot-instructions.md` have no
  documented directory-inheritance model, so those remain per-repo regardless of tier.

## Related

- [activation](activation.md) — a pack at no tier the work inherits from is inert, however good it is.
