---
name: baseline-gap-review
description: Reconcile the piled-up `_Improvements/` backlog against both toolkits' current baselines/skills, classify and place every note, and archive the source files with a disposition manifest. Use when the user asks to "review the improvements backlog", "reconcile _Improvements", do a "baseline gap review", or "check if anything needs promoting from _Improvements".
status: trial
problem: Session-closeout runs write candidate notes into `_Improvements/` but nothing reviews or promotes them on its own cadence, so the folder silently piles up until a manual reconciliation pass is needed — and that pass has a real, repeatable shape that was being re-derived from scratch each time.
when-not-to-use: Do not use for a single new note reviewed the same day it's captured — that doesn't need a full reconciliation pass, just read it and decide. Do not use this skill to do the underlying company or personal work itself; it only reconciles the improvement backlog, it does not replace `improvement-extraction`, `lesson-extraction`, or `session-closeout`.
maintainer: Justin Choi
---

# Baseline Gap Review

Occurrence #2 of this exact pain (`_Improvements/` piled up again — 41 new
notes since the 2026-07-29 pass — with no review cadence). Per this
toolkit's own `process-vs-work-doctrine` rule 1 (same pain twice, dated,
before building), the second dated occurrence is what justifies this skill
existing at all. Per rule 3, it **must stay in this single-file form**
until a third real use — no spec directory, no install script, no
CONTEXT.md, no supporting scripts. Do not scaffold further on your own
initiative; a third occurrence is what would justify that conversation, not
this one.

## Paths

Resolve all three from the environment. Do **not** prompt for them, and do not
write literal machine paths back into this file:

- `_Improvements/` root: `$IMPROVEMENTS_ROOT` (the same variable
  `improvement-extraction` writes to — they must agree)
- work toolkit repo: `$WORK_TOOLKIT_ROOT`
- personal toolkit repo (this repo): `$AI_TOOLKIT_ROOT`, or the repo root
  containing this skill

If a variable is unset, ask for that one path once and use it for the run only.

> Superseded 2026-09-09: these were previously three hardcoded absolute paths,
> kept that way on a standing "don't parameterize" instruction. That is now
> overridden by a stricter constraint — the paths embedded the employer's name,
> and this repo must carry no company-identifying information. Reading them from
> the environment satisfies both: still no prompting in the normal case, and
> nothing employer-specific committed. It also makes the skill work on a second
> machine, which the hardcoded form never did.

See the disposition record of occurrence #1 for the concrete shape this
procedure is distilled from:
`$IMPROVEMENTS_ROOT/Done/2026-07-29-baseline-consolidation-manifest.md`.

## Procedure

### 1. Read every non-Done file in full

List everything directly under `_Improvements/` (not `_Improvements/Done/`).
Read each file completely — not just the filename or first paragraph.
Classify each into exactly one bucket:

- **company-toolkit rule** — domain/technology-specific fact that belongs in
  `es-ai-toolkit`.
- **personal-toolkit rule** — portable, employer-agnostic process discipline
  that belongs in `ai-toolkit`.
- **skill-candidate** — proposes a new repeatable workflow/skill rather than
  a baseline bullet.
- **not-actionable** — empty placeholder, unreadable attachment, or too
  repo-narrow to generalize into either shared toolkit.

While reading, flag near-duplicate or overlapping notes that should merge
into a single baseline entry rather than ship as separate lines — occurrence
#1 found several of these (e.g. multiple notes converging on one
`verification-epistemics` bullet).

### 2. Survey both toolkits' current content topic-by-topic

Before proposing anything, read the actual current state of both toolkits'
relevant baselines/skills — never assume from memory what a toolkit already
contains. Go topic by topic (SQL Server safety, .NET conventions, git
hygiene, Azure DevOps hygiene, verification epistemics, handoff-doc
discipline, etc.) and check whether the candidate note's point is already
covered, partially covered, or a genuine gap. Only genuine gaps get written.

List every baseline directory in BOTH repos directly (`ls baselines/` in
each, not a remembered list) before doing anything else — occurrence #2's
own survey missed that `es-ai-toolkit` already had its own
`git-collaboration-hygiene` fork, stuck 4 minor versions behind
`ai-toolkit`'s, purely because a stale mental list stood in for actually
checking. For every baseline name that exists in **both** repos, diff their
`baseline.md` principle lists against each other, independent of whether
`_Improvements` has anything to say about that topic this round — same-named
packs are not guaranteed to be intentional mirrors (some are; some are
accidental leftovers from unrelated tooling work), and drift between them
should surface as its own finding either way, not stay silent until someone
happens to notice.

Same-named packs across the two repos are versioned **independently**, not
in lockstep — that's correct, not a bug to "fix" by forcing matching version
numbers. What actually needs tracking is provenance (record it in the drifted
pack's `pack.json` `source.relationship` field when you resync one) and
periodic drift-detection (this step), not synchronized version counters.

### 3. Cross-check every skill-candidate against `process-vs-work-doctrine` rule 1

For each note classified as a skill-candidate, use the note's own embedded
dates (not today's date, not assumption) to check whether the same pain has
a second dated occurrence:

- **Second dated occurrence exists** → clears the gate, proceed to build it
  as a skill (in minimal single-file form per rule 3, unless it already has
  a documented third occurrence).
- **No second dated occurrence** → downgrade. Do not build a skill. Fold it
  into a baseline bullet, a reference/technique note, or a checklist line in
  an existing skill instead, per whatever the content actually needs.

This is the same test this skill itself was just put through — apply it as
rigorously to every candidate as it was applied to this skill's own
candidacy.

### 4. Apply the placement heuristic

- **Domain/technology-specific facts** (SQL Server, .NET DI, Azure DevOps
  ticket mechanics, a specific repo's internals) → `es-ai-toolkit` only.
- **Portable, employer-agnostic process discipline** (git hygiene,
  verify-from-source epistemics, handoff-doc lifecycle, meta-doctrine itself)
  → `ai-toolkit` only.
- **Purely technical facts that merely happened to surface during company
  work but aren't actually employer-specific** (e.g. a SQL Server rule, a
  .NET DI gotcha) → mirror into **both** toolkits, so the same mistake
  doesn't recur if `ai-toolkit` is ever used for similar work outside the
  company.

If a note doesn't cleanly fit one of these three, ask Justin rather than
guessing — occurrence #1 resolved the ambiguous middle by asking, not by
mechanically filing by "which employer's session produced this."

### 5. Write the content

- **`es-ai-toolkit`** (shared team repo): create a fresh branch off an
  up-to-date `main` — never the currently-checked-out WIP branch, whatever
  it happens to be. Write the actual baseline/skill content, verify
  structural completeness (valid JSON/YAML where applicable, required files
  present), push, and open a PR for team review. Do not merge it yourself.
- **`ai-toolkit`** (this repo, personal, solo): write directly to `main`,
  verify structural completeness, and push. No PR, no review gate — this is
  a personal repo.

For every existing baseline that gets NEW principles added (not brand-new
baselines — those get fresh adapters as part of creating them), a
`baseline.md` edit is not the whole job. Two derived artifacts drift out of
sync if left untouched, and occurrence #2 shipped both mistakes at first:

- **`pack.json`**'s `version` field — bump it to match `baseline.md`'s
  `Version:` header in the same edit, not as a follow-up pass.
- **`adapters/{CLAUDE.md,AGENTS.md,copilot-instructions.md}.block`** — these
  are the condensed renderings that actually get installed into a consuming
  repo's instruction files via `baseline apply`. They do not auto-update
  when `baseline.md` changes. Rewrite all three (check they're byte-identical
  to each other first — they have been every time so far — and if so, treat
  them as one edit copied three ways) to reflect the *complete current*
  principle list, not just the new ones, and bump their `<!-- BEGIN
  baseline:<name> vX.Y.Z -->` marker to match. Then check `baseline status`
  in that repo: if the pack shows as already `YES` (applied), re-run
  `baseline apply <name>` so the repo's own installed instruction files pick
  up the fix immediately rather than staying stale until someone happens to
  re-apply it later.

### 6. Archive every processed source file

Move every file this pass touched — including `not-actionable` ones — into
`_Improvements/Done/`. Write a new dated disposition manifest alongside them
(`_Improvements/Done/<YYYY-MM-DD>-baseline-consolidation-manifest.md`,
following the shape of the 2026-07-29 one) recording:

- Session context: what triggered this pass, how many files, what date
  range, how many source repos/incidents they span.
- A full disposition table: one row per file, naming exactly where its
  content landed (or why it didn't).
- The placement heuristic actually used this round, and any refinements to
  it.
- Landing status for both repos (branch/PR link for `es-ai-toolkit`; merged
  confirmation for `ai-toolkit`).

The point of this manifest is that a future occurrence can recognize
itself and compare against this one — write it with that reader in mind,
not just as a changelog entry.

## If this recurs a third time

Per the candidate note's own "Future work" section: before building
anything further, ask *why the review cadence keeps breaking down* — was
`_Improvements/` simply unreviewed for N weeks, did the backlog cross some
size threshold that made a live review impractical, or did a missed note
cause a repeat mistake? That diagnostic answer — not just the raw fact of a
third recurrence — should decide whether this skill needs an earlier or
automatic trigger (e.g. a nudge after every N `session-closeout` runs)
instead of staying purely manually-invoked.

Do not build that trigger now. This is only this skill's first real use;
automation on top of it needs its own justification, earned the same way
this skill earned its own existence — a real, dated recurrence of the
specific pain that automation would fix, not an assumption that it would
help.
