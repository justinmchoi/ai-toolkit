# Core / full split

**Two renderings of one baseline pack**: an append-only reference, and a bounded slim version that
is the only thing installed always-on.

| File | Role | Growth |
|---|---|---|
| `adapters/CLAUDE.md.block` | the **full** list — the reference | append-only; nothing is ever deleted |
| `adapters/CLAUDE.md.core.block` | the **core** — load-bearing rules plus a pointer to the full version | bounded, target under 15 lines |

A new principle always goes into the full block. It goes into the core **only if it displaces
something**, or the core has room.

## Why this beats deletion

The obvious answer to a pack outgrowing the [always-on budget](always-on-budget.md) is eviction —
delete the bullets that have stopped earning their place. That requires evidence a bullet has gone
silent, which requires provenance data the pipeline only started collecting on 2026-09-09. Until
then, deleting on the judgment that a rule *sounds* redundant is exactly what the eviction criteria
forbid: this toolkit has already recorded rules that were violated because they were
**uninstalled**, not because they were unnecessary.

The split sidesteps that entirely. **Nothing is removed, so nothing needs proving** — the always-on
cost is bounded by construction, and the full list survives intact for the on-demand path. Eviction
becomes an optimisation to run later on real data, not a prerequisite for fixing the budget.

## When it does not apply

A pack whose rules are file-type-scoped skips this question: install the **full** block as a
path-scoped rule (see [loading axis](loading-axis.md)) so it loads only when a matching file is read
and costs nothing otherwise. The split is for behavioural packs that cannot be glob-scoped —
`verification-epistemics`, `git-collaboration-hygiene`, `repo-context-grounding`.
