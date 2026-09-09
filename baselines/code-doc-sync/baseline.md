# Code-Doc Sync Baseline

Status: active
Version: 0.6.0

Always-on documentation hygiene for AI coding agents working in repositories
that contain architecture documentation, flow diagrams, or developer references
alongside the code.

Distilled from two production bug fixes that were merged without updating
adjacent flow trees and architecture docs, and from a flow tree that described
an abstract declaration site instead of the concrete runtime type.

## Principles

1. Check adjacent documentation before closing a behavior-changing task.
   First establish whether the repo has architecture docs at all (see "Applying
   in a Repo" below); if no documentation folder exists, this principle fires
   on nothing. When docs exist, and the task changes externally observable
   behavior or a contract other code depends on — a public API, a documented
   flow, a class relationship that appears in diagrams — check the docs that
   describe the changed behavior and decide whether each needs updating. An
   explicit decision of "no update needed" is fine; skipping the check is not.
   This applies equally to bug fixes and feature work — bugs often correct
   behavior that was documented as if it were correct. Purely internal changes
   with no observable-behavior or contract impact do not require the check.

2. Show the concrete runtime type in flow diagrams and call traces.
   When writing or updating a flow tree, sequence diagram, or call trace that
   involves a virtual or abstract method, use the concrete class name that
   actually executes at runtime — not the abstract declaration site. Writing the
   base class name hides the polymorphism the diagram is meant to explain, and
   creates the false impression that the base class logic runs unconditionally.

3. Check the target repo's own decision records before recommending a pattern seen in a sibling repo.
   Before recommending that a codebase adopt a library, pattern, or
   convention observed working well in a different codebase, search the
   target codebase's own decision-record location (ADRs, RFCs, a
   decision-records folder) for whether it already evaluated and made a
   deliberate, different choice covering the same concern. A prior recorded
   decision may have picked the more manual or explicit option specifically
   because of a tradeoff the automatic option reintroduces. This check
   applies only where the target codebase maintains discoverable decision
   records; where none exist, it reduces to ordinary judgment.

4. Scope each architecture decision record to exactly one decision.
   When writing ADRs for a body of related work, write one file per
   genuinely independent decision — not one file per feature, PR, or
   component — even when several decisions touch the same component. This
   keeps each record's Context, Alternatives, and Consequences honest to a
   single choice, and lets a later reader or an automated doc-sync check
   reason about one decision at a time instead of untangling several
   interleaved decisions from one document.

5. Tag each claim in a mixed current-state/target-design doc with an explicit verification status.
   When a document or diagram mixes what exists today with what is planned
   but not built, mark each individual claim, arrow, or box as
   confirmed-in-code, designed-not-built, or unverified rather than relying
   on uniform notation for both. This lets a reader trust which parts are
   current without redoing the investigation, and means only the flipped
   items need updating as design items ship.

6. Check whether earlier session work already closed a documented "gap" before repeating it as current fact.
   Before restating a documented "gap", "stub", "TODO", or "not yet
   implemented" claim as current fact — in an answer, a status report, or a
   doc edit — check whether earlier work in this same session (in this repo
   or a sibling repo/branch) already closed it. This is the inverse trigger
   of Principle 1: Principle 1 fires when you change behavior and must check
   whether docs describe it; this principle fires when you are about to
   assert a doc's existing claim as true and must first check your own prior
   session work. The moment a stale claim is found, fix the doc immediately —
   do not let the assertion stand and file a follow-up.

7. Call out a manually-enforced cross-system invariant in the operational onboarding template at decision time, not as a follow-up.
   When resolving an ambiguity produces an invariant that only holds because
   two independently-created values are kept identical by hand — with
   nothing automated checking it — add a call-out to the operational
   onboarding template or script that actually creates the value, in the
   same pass as writing the decision record. Do not defer this to a
   follow-up task. This applies even when the triggering event was a
   zero-code-diff decision (a naming or config choice recorded in an ADR or
   decision doc) rather than a code change — the invariant still needs to be
   visible to whoever runs the onboarding step next.

8. Render an embedded Mermaid diagram with mermaid-cli before committing a change to it.
   Before committing a change to a Mermaid diagram embedded in
   documentation, render it with mermaid-cli (or an equivalent renderer) to
   catch parse-breaking syntax errors. Visual inspection of the diagram
   source is not sufficient — some syntax errors only surface at render time
   and are not visible by reading the text.

9. Run a rename/reshape that touches a linked doc as one deterministic
   checklist, not a reconstructed-by-hand sequence.
   For any rename/reshape of a field or method used across multiple projects
   and referenced in a linked doc (ADR/test plan) — especially likely to
   recur multiple times in one session during active design churn — run it
   as: (1) grep all usage sites first, don't rely on memory of "the
   propagation points"; (2) fix production code; (3) fix tests; (4) build
   each touched project incrementally; (5) full-solution build; (6) update
   linked docs to match; (7) a final stale-reference grep; (8) `git status`
   sanity check. A one-off single-file rename with no accompanying doc
   doesn't need this.

10. When a runbook step says "manually build a follow-up query/artifact
    from a script's output," check whether the script can instead emit
    that follow-up as a generated file directly, rather than leaving the
    derivation as a manual step.

## Applying in a Repo

These principles are folder-name-agnostic. If the repo's CLAUDE.md or README
specifies where architecture documentation lives, read that first. Otherwise,
look for common patterns: `_Documents/`, `docs/`, `architecture/`, `design/`,
`ADR/`. If no documentation folder is found, these principles fire on nothing —
that is an acceptable outcome.

## Priority

This baseline takes precedence over ordinary implementation habits, but never use it to
override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions.

## Non-Goals

- This is not a requirement to write documentation where none exists.
- This does not require every code change to produce a doc change.
- This does not define what documentation format or structure to use.
- Principle 2 does not prohibit noting the abstract declaration — it requires
  the concrete runtime class to be the primary label.

## Origin

A carrier-integration service. Two bug-fix commits
were merged without reviewing adjacent flow trees or the
architecture progress log. A flow tree also labeled a virtual call as
its abstract base class's method when the method that executes at
runtime is the carrier-specific subclass override.
