# Flows

A **flow** is a methodology that spans more than one skill, declared as a state graph.

## Why this is a separate domain

The toolkit already had three artifact types, split by *when they load*:

| Domain | What it is | Loads |
|---|---|---|
| `baselines/` | always-on context packs | every turn |
| `skills/` | on-demand procedures | on invocation |
| `hooks/` | mechanical enforcement | on a tool event |
| **`flows/`** | **multi-skill methodology as a state graph** | **referenced by its entry skill** |

None of the first three fits a methodology that spans several skills. Written as a skill, a flow
becomes an ad-hoc orchestrator, and the tell is **fractional step numbers** — `session-closeout` has
a Step 0.5 and a Step 3.5, because inserting a conditional state into a numbered list has nowhere
clean to go. That is a graph being written as a list.

Two dated occurrences justify the domain (`process-vs-work-doctrine` rule 1):

- **2026-09** — `session-closeout` built as a hand-rolled chain of three skills, with guards
  ("check availability"), a conditional branch (compaction detected → escalate step 3 to full-sweep),
  and skip-paths that are explicitly not failures.
- **2026-09-09** — the `improvement-extraction` → `baseline-gap-review` pipeline identified as a
  genuine cycle, including a feedback edge (`reopened-*` notes) that was added *without anyone
  noticing it closed a loop*.

## What a flow is for

Three things a prose procedure cannot do:

1. **State the exit.** A skill "ends" when its steps run out, which is not the same as succeeding. A
   flow names its terminal states and what makes each one true.
2. **Close loops explicitly.** Feedback edges are the whole point and are exactly what prose hides.
3. **Produce data.** A run emits an exit log naming its terminal state and path. That log can be
   checked against the declared graph — which is the only way to answer "is this methodology
   actually working?"

## Structure

```
flows/<name>/
  pack.json     name, version, status, member skills, entry state, terminal states
  flow.md       the normative mermaid state diagram, the guards, the exit-log contract
```

No `adapters/`. A flow is not installed into an instruction file — it is referenced by its entry
skill and read on demand, so it costs nothing when unused.

## The diagram is normative

The mermaid `stateDiagram-v2` block in `flow.md` is **the source of truth**, not an illustration of
prose written elsewhere. Guards are transition labels. Prose may explain a state; it may not
contradict the diagram or define a transition the diagram lacks.

This matters because a diagram that merely *depicts* a procedure is a second thing to keep in sync,
and drifting duplicates are a failure mode this toolkit has repeatedly recorded. One source, which
happens to render.

## What a flow does and does not enforce

**It does not intercept.** Nothing prevents a model from skipping a guard — a markdown file is not a
runtime, and claiming otherwise would be the same mistake as assuming a baseline fires because it
was written.

**It does detect.** The exit log is checkable against the graph: was the terminal state a declared
one, was every transition legal, did a loop exit on its stated condition. Detection is weaker than
prevention and sufficient for the actual gap, which is that nothing is measured today.

If a specific guard turns out to matter enough to enforce mechanically, that is a `hooks/` pack, not
a flow. Keep the two separate: flows declare, hooks enforce.

## Adding one

Only when a methodology genuinely spans multiple skills *and* has at least one loop, branch, or
non-obvious terminal state. A linear three-step procedure with one outcome is a skill; giving it a
state diagram is ceremony.
