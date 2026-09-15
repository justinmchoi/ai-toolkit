# Handoff Document Discipline Baseline

Status: active
Version: 0.3.0

Always-on lifecycle discipline for a **living snapshot document** — a plan,
implementation status doc, or "paste this to resume" prompt that gets
overwritten in place as work progresses, rather than a dated append-only
record. This repo's own `docs/handoffs/YYYY-MM-DD-<slug>.md` convention (see
`docs/how-to/handoffs.md`) already avoids the in-place-overwrite failure mode
by being dated and append-only — this baseline is for the *other* shape of
handoff doc: any file a project keeps as a single living resume/plan doc that
gets edited in place across a session or across sessions.

## Principles

1. Archive the prior version before overwriting a living handoff doc in
   place.
   Before replacing the entire content of a document that's reused as "the
   thing to read to pick this back up" (a resume prompt, an implementation
   plan, a status snapshot), save the pre-overwrite version as a separate
   file first — unless the document is already under real version control
   where the prior version is trivially recoverable from history. A wholesale
   in-place rewrite with no version control is not recoverable once done.

2. Re-read a long handoff doc linearly for self-contradiction before
   dispatching it.
   A handoff/plan doc that's accumulated additive "correction" sections over
   a long session is prone to earlier sections going un-reconciled with later
   ones. Before handing it to a fresh session or another person, read it
   start-to-finish as a single linear document — not just the latest diff —
   specifically checking whether an earlier section still says something a
   later correction contradicts.

3. Recheck a deferred fix's blast-radius scope at each newly-discovered call
   site rather than treating "already deferred" as a blanket exemption.
   A fix deferred for blast-radius reasons (too many call sites, unknown
   downstream dependents) is deferred because of that reasoning, not because
   of every call site that happens to share the same mechanism. When later
   work touches a specific site, recheck whether the original blast-radius
   concern actually applies there — fix it now if the site is inside the
   current work's own scope, and treat it as still deferred if that's
   ambiguous.

4. Hand over the literal, copy-pasteable command when recommending a
   destructive or rollback action for someone else to execute, never a
   paraphrased target.
   Describing only the target state ("roll back to migration X") lets a
   paraphrase drop the exact command and a substitution error silently swap
   in a catastrophic scope; give the literal command string, call out the
   real-world meaning of any special or sentinel argument (a `0` that means
   "roll back everything," not "do nothing"), and ask for the exact command
   to be read back before it runs when the handoff is asynchronous.

5. When spinning off a deferred or generalized finding into a new backlog
   item, write falsifiable acceptance criteria, state the boundary case
   explicitly, and flag open design decisions as open.
   Point the background at the origin discussion instead of re-pasting the
   analysis, phrase acceptance criteria so they can only pass if the real
   behavior changed (not a narrow or synthetic test), state what must NOT
   happen alongside what must, and list genuinely undecided design questions
   as open rather than resolving them on the implementer's behalf.

6. Never silently substitute "defer" for a just-approved "do it now".
   When an explicit approval says now, either do it now or state in the same
   turn that the plan is to defer it and why. Handing the work to a future
   session, a continuation prompt or a batch without surfacing that
   substitution reads as compliance while actually changing the outcome — an
   unstated downgrade from "now" to "later" is invisible to the person who
   approved it. Deferring is reasonable when new information genuinely
   changes the situation after the approval (the session is about to end, a
   dependency turns out to be missing); the rule is about surfacing the
   change, not about never deferring.
   _(added 2026-09-15, from `reconfirm-before-silently-deferring-an-approved-now-action`)_

## Priority

Apply this baseline before overwriting or dispatching a living
plan/resume/status document, but never use it to override explicit user
instructions, safety rules, privacy boundaries, or stricter repo-local
instructions — including this repo's own dated-handoff convention where it
applies instead.

## Non-Goals

- This does not apply to dated, append-only handoff files (this repo's
  `docs/handoffs/` convention already avoids the overwrite failure mode by
  design).
- This does not define what a handoff document should contain, only its
  lifecycle safety around edits and dispatch.
