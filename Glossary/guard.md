# Guard

**The condition required to leave a state** in a [flow](../flows/README.md).

Guards already existed in this toolkit as prose before they had a name. `diagnose` writes them
plainly — *"Do not proceed to Phase 2 until you have a loop you believe in"*, *"Do not proceed until
you reproduce the bug"* — and that phrasing is the model to copy. In a flow's mermaid diagram, a
guard is a **transition label**.

## Declared, detectable, not enforced

A guard is a declaration. **Nothing prevents a model from skipping one** — a markdown file is not a
runtime, and claiming otherwise is the same error as assuming a baseline fires because it was
written (see [activation](activation.md)).

What a guard buys is *detection*: because the legal transitions are declared, a run's exit log can
be checked against them — was the terminal state a declared one, was every transition legal, did a
loop exit on its stated condition. Detection is weaker than prevention, and sufficient for the real
gap, which is that nothing is measured at all.

**If a specific guard matters enough to block on, it becomes a `hooks/` pack.** Flows declare; hooks
enforce. Keep them separate, and note that only mechanically detectable triggers can be hooked —
judgment cannot.

## Writing a good one

- State it as an observable condition, not an intention: "grepped both folders", not "considered
  duplicates".
- Give loops a **numeric or observable exit** — "re-run until zero new hits", not "until it looks
  complete".
- A guard whose satisfaction cannot be observed from outside is a comment, not a guard.
