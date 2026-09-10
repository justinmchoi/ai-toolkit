# Activation

**Whether a rule is actually reachable by the session that needed it** — as distinct from whether
the rule is correct, well worded, or well placed in principle.

A rule has three independent properties, and only the first two get attention:

1. **Authored** — it exists and says the right thing.
2. **Promoted** — it landed in a pack.
3. **Activated** — it is installed somewhere the work inherits from. See [tier](tier.md) and
   [loading axis](loading-axis.md).

**This is the toolkit's dominant failure mode.** On 2026-09-09, two rules that were authored,
promoted, and shipped were both violated in a single session, because no pack was installed at any
tier the working directory inherited from — no `~/.claude/CLAUDE.md`, no `~/.claude/rules/`, no
ancestor `CLAUDE.md`. The content pipeline was working; the delivery was not.

## Why the distinction is load-bearing

Because the instinctive response to a recurrence is to **reword the rule**, and rewording a rule
that failed for activation reasons *looks like progress and changes nothing*. `baseline-gap-review`
step 5 exists to force the question the other way round: given where this pack is actually installed,
would it have fired at all?

Diagnose an activation failure as one of three causes:

- **Unreachable** — the pack is not installed at any tier the work inherits.
- **Buried** — installed, but competing with dozens of bullets in the same
  [always-on budget](always-on-budget.md).
- **Mis-scoped** — worded for a situation that did not look like this one, or (for a
  path-scoped rule) glob-scoped to files the session never opened.

Only the third is a wording problem. Fix the first two by placement.

## Related

- A `reopened-*` note is the recorded evidence of an activation failure.
- [core / full split](core-full-split.md) — how a pack stays activated without consuming the budget.
