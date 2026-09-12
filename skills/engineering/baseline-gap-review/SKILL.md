---
name: baseline-gap-review
description: Reconcile the piled-up `_Improvements/` backlog against both toolkits' current baselines/skills, classify and place every note, and archive the source files with a disposition manifest. Use when the user asks to "review the improvements backlog", "reconcile _Improvements", do a "baseline gap review", or "check if anything needs promoting from _Improvements".
status: trial
problem: Session-closeout runs write candidate notes into `_Improvements/` but nothing reviews or promotes them on its own cadence, so the folder silently piles up until a manual reconciliation pass is needed — and that pass has a real, repeatable shape that was being re-derived from scratch each time.
when-not-to-use: Do not use for a single new note reviewed the same day it's captured — that doesn't need a full reconciliation pass, just read it and decide. Do not use this skill to do the underlying company or personal work itself; it only reconciles the improvement backlog, it does not replace `improvement-extraction`, `lesson-extraction`, or `session-closeout`.
maintainer: Justin Choi
---

# Baseline Gap Review

Built after the second dated occurrence of this pain (`_Improvements/` piled up
again, 41 new notes since the 2026-07-29 pass, with no review cadence), which is
what `process-vs-work-doctrine` rule 1 requires before building anything.

**Don't state the occurrence count here.** Earlier versions of this file hardcoded
one and it was wrong within a month, because the file cannot know how many times it
has since been run. Count the dated manifests instead — `ls $IMPROVEMENTS_ROOT/Done/*-baseline-consolidation-manifest.md`
is the number of passes, and `$IMPROVEMENTS_ROOT/.flow-log` is the running record.

Per rule 3 this **stays a single file** — no spec directory, no install script, no
CONTEXT.md, no supporting scripts. It has now run several times without needing
any of them, which is evidence the constraint is right rather than a countdown to
relaxing it. Do not scaffold on your own initiative.

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
Read each file completely — not just the filename or first paragraph. Filenames are
written at capture time and routinely understate what a note grew into: on
2026-09-11 the file named for a Windows encoding crash had been extended in place
with a second, worse instance in the opposite direction, and the note named for one
skill's friction turned out to be the owner reversing a documented decision.
Classify each into exactly one bucket:

- **company-toolkit rule** — domain/technology-specific fact that belongs in
  `es-ai-toolkit`.
- **personal-toolkit rule** — portable, employer-agnostic process discipline
  that belongs in `ai-toolkit`.
- **skill-candidate** — proposes a new repeatable workflow/skill rather than
  a baseline bullet.
- **flow-candidate** — a methodology that spans **more than one skill** and has
  at least one loop, branch, or non-obvious terminal state. Belongs in `flows/`,
  not as another orchestrator skill. The tell that one is hiding in an existing
  skill: fractional step numbers (a "Step 0.5", a "Step 3.5") — that is a graph
  being written as a numbered list.
- **hook-candidate** — a hard prohibition with a **mechanically detectable
  trigger** (a destructive command against a path, editing a generated
  directory, committing without a typecheck). Belongs in `hooks/`, where it
  fails closed, not in baseline prose where it is merely advisory. Judgment
  cannot be hooked; only triggers can.
- **glossary-term** — a term or concept this toolkit's own docs keep re-explaining
  inline. Belongs in `Glossary/`, one file per term.
- **recurrence** — a `reopened-*.md` note, written by `improvement-extraction`
  when a candidate matched a rule already promoted into a pack. These are **not**
  new rules and must never be processed as one. They are evidence that a shipped
  rule failed to fire, and they route to step 5, not step 4.
- **not-actionable** — empty placeholder, unreadable attachment, or too
  repo-narrow to generalize into either shared toolkit. Also: a note whose content
  **already landed** since it was captured. Check before classifying anything else
  — a note written on the 9th can be resolved by a commit on the 9th, and three of
  the 2026-09-11 batch were.
- **external-methodology** — an article, framework or write-up someone handed over
  for evaluation, rather than a lesson from a real failure. `methodology-intake`
  used to own these and is deprecated; this skill absorbed it. Judge it with step 5
  like anything else: name the dated failure it would have prevented here. If none
  can be named, it is a `bookshelf/` pointer, not a rule — however good the article.

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

Survey **every domain**, not just baselines and skills: `ls baselines/`,
`ls skills/`, `ls flows/`, `ls hooks/`, `ls Glossary/` in each repo. A candidate
that looks like a new baseline is often an existing flow's missing guard, or a
term already in the glossary. Checking only the two oldest domains is how a
note gets filed into the wrong one.

List every baseline directory in BOTH repos directly (`ls baselines/` in
each, not a remembered list) before doing anything else — one pass's survey
missed that `es-ai-toolkit` had its own `git-collaboration-hygiene` fork,
stuck 4 minor versions behind `ai-toolkit`'s, purely because a stale mental
list stood in for actually checking. For every name that exists in **both**
repos, diff the two `baseline.md` principle lists against each other,
independent of whether `_Improvements` has anything to say about that topic
this round — same-named packs are not guaranteed to be intentional mirrors,
and drift should surface as its own finding rather than stay silent.

**As of 2026-09-09 no baseline name overlaps.** `es-ai-toolkit` shed its 15
duplicated packs that day, keeping only the three genuinely company-specific
ones, because adapter blocks are keyed by pack **name**: applying the same
name from both sources puts two blocks with different content into context
simultaneously and silently, and six repos were already in that state. Still
run the comparison — the point is to catch a duplicate reappearing — but expect
it to come back empty, and do not "restore" a missing pack to `es-ai-toolkit`
without reading that decision first.

**The overlap has moved to `skills/`.** Seven names now exist in both repos
(`query-azure-devops`, `project-structure`, `improvement-extraction`,
`client-flow-diagrams`, `improve-codebase-architecture`,
`diagnose-migration-history-divergence`, `sql-backfill-pipeline-scaffold`), and
these drift in **both** directions — `query-azure-devops` is far richer in
`es-ai-toolkit`, `improvement-extraction` far richer in `ai-toolkit`. Never
resolve that by copying the larger file; direction is per-artifact and decided
by **content sensitivity first** (anything company-identifying belongs to
`es-ai-toolkit`, always), never by recency or line count.

Same-named packs across the two repos are versioned **independently**, not
in lockstep — that's correct, not a bug to "fix" by forcing matching version
numbers. What actually needs tracking is provenance (record it in the drifted
pack's `pack.json` `source.relationship` field when you resync one) and
periodic drift-detection (this step), not synchronized version counters.

### Also survey what is *installed*, not only what is authored

A repo is where a rule is written; it is not where a rule runs. Three separate
things determine whether anything you promote ever loads, and none of them is
visible from `ls baselines/`:

- **`baseline status`** in the relevant repo — which packs resolve, from which
  tier, at which version, and in which variant. A pack showing at two tiers means
  both blocks are literally in context.
- **`ls -l ~/.claude/skills/`** — which repo each installed skill actually points
  at. On 2026-09-11 every symlink pointed at `ai-toolkit` and **none** at
  `es-ai-toolkit`, so the company skills were a publication target that never ran.
- **`ls ~/.claude/commands/`** — the ungoverned parallel library. Skill generators
  write finished artifacts straight in here with no review, and this pipeline has
  no visibility into it. On 2026-09-11 it held four copies of one support-tool
  skill at three different states of correctness, one of them shipping another
  team's identifier as a literal. Anything found there is a routing finding, not
  a rule to promote.

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

Then place by **artifact type**, which is a separate question from which repo:

| The note is… | Domain |
|---|---|
| a judgment that must fire unprompted | `baselines/` |
| a repeatable procedure invoked on demand | `skills/` |
| a methodology spanning several skills, with a loop or branch | `flows/` |
| a hard prohibition with a detectable trigger | `hooks/` |
| a term the docs keep re-explaining | `Glossary/` |

The two axes are independent: *who inherits it* (which repo, which tier) and
*when it loads* (always-on, path-scoped, on invocation, on a tool event). Decide
both, explicitly. A pack destined for always-on also needs the core/full split
(see step 7) so it does not silently grow the always-on budget.

If a note doesn't cleanly fit one of these three, ask Justin rather than
guessing — occurrence #1 resolved the ambiguous middle by asking, not by
mechanically filing by "which employer's session produced this."

### 5. Activation test — would this rule actually have fired?

Before writing a single bullet, answer both questions **in writing** for each
candidate. This step exists because the pipeline's dominant failure is not a
badly-worded rule; it is a correct rule that never reaches the session where the
mistake recurs.

1. **What specific failure would this have prevented?** Name the incident, with a
   date. If no concrete failure can be named, it is documentation, not a rule —
   file it as a reference note and stop. "Sounds like good practice" is how packs
   grow without getting better.
2. **Given where it would be installed, would it have fired?** Check the tier the
   target pack is actually applied at, on disk — not where you assume it is. A rule
   promoted into a pack installed nowhere near the failure changes nothing, however
   well written. If the honest answer is no, **the fix is placement, not text**:
   record it as an activation problem and resolve that instead.

#### File by loading trigger, not by topic

This is the dominant misfile, and it is invisible because the wrong home always
*reads* right. Three of the 2026-09-11 recurrences had this single root cause:

| Rule | Filed under | Loads when | Failure happened while |
|---|---|---|---|
| `az` CLI drops non-ASCII on Windows | `python-conventions` (`paths: **/*.py`) | a Python file is read | running `az`, no Python file in sight |
| `MAX_PATH` breaks a scratchpad build | `dotnet-conventions` (`paths: **/*.cs`) | a C# file is read | `dotnet new` then `dotnet test`, before any `.cs` was read |
| precedent ≠ equivalence | `verification-epistemics` **full** block | never — the user tier installs **core** | reusing a precedent |

Each was filed by the topic it *mentions* — Python, .NET, verification — rather
than by the situation that triggers it. Each read as promoted. None had ever
loaded at the moment it was needed, across three months and eight occurrences.

So before writing, answer the trigger question mechanically. Three checks, none
of which can be done from memory:

1. **Is the target pack path-scoped?** `cat baselines/<pack>/pack.json` and read
   `paths`. If it has them, the rule loads only when a matching file is *read*. Ask
   what file was open at the moment of the failure — if the answer is "none of
   those", the pack is wrong however well the topic matches.
2. **Does the target pack have a core adapter, and would this bullet be in it?**
   `ls baselines/<pack>/adapters/`. If `CLAUDE.md.core.block` exists, that is
   probably the only rendering installed, and **everything in the full block is
   unloaded**. `verification-epistemics` carried 84 principles of which 11 loaded.
   A load-bearing rule goes in core or it does not ship — see step 7.
3. **Where is the pack actually installed?** `baseline status` in the repo where
   the failure occurred. "It's in the pack" and "it was in context" are different
   claims, and only the second one matters.

When none of the existing packs has the right trigger, that is the finding: the
rule needs a **new pack whose activation matches the situation**, or a move to an
always-on one. Squeezing it into the nearest topical pack is how a correct rule
recurs for three months.

For every note in the **recurrence** bucket, question 2 is the whole job. The rule
text is already correct — it shipped and the failure happened anyway. Diagnose the
delivery mechanism: installed at an unreachable level, buried mid-pack among
dozens of bullets, or worded for a situation that didn't look like this one.
**Rewording a rule that failed for activation reasons is the trap** — it looks like
progress and changes nothing. Only touch the wording if the third cause is the
real one, and say so explicitly.

Record each answer in the disposition manifest (step 8). They are what makes the
next eviction pass possible.

### 6. Eviction pass — what leaves?

An always-on pack is a **fixed budget, not an append-only log**, and every bullet
is billed on every turn in every repo that inherits it. Nothing in this pipeline
removes anything, so packs only grow. Fix that here, in the same pass that adds.

For any pack receiving new principles this round, review its existing ones against
four tests:

- **Age + silence** — provenance says it was added N months ago and no note has
  cited it since. A candidate, not yet a verdict.
- **Ablation** — remove it, run a representative task, compare. The only real
  evidence. Do this for at most one bullet per pass; it is the expensive test.
- **Generality drift** — worded so narrowly it can only ever match the single
  incident it came from. That is a reference note, not an always-on rule.
- **Internalization** — general engineering advice current models now follow
  unprompted. Depreciating inventory. Org-local facts are not in this category and
  should not be evicted for looking mundane.

**Do not evict on elegance.** A bullet that reads as blindingly obvious and still
catches real mistakes is doing its job — this pipeline has already recorded rules
that were violated *because they were not installed*, not because they were
redundant. Eviction needs evidence of silence, not a judgment that a rule sounds
unnecessary.

Aim for a pack's net bullet count not to grow every single pass. If nothing can be
evicted, say so explicitly in the manifest and move on — a deliberate "nothing
left this round" is a finding; silently skipping the step is how the budget breaks.

### 7. Write the content

- **`es-ai-toolkit`** (shared team repo): create a fresh branch off an
  up-to-date `main` — never the currently-checked-out WIP branch, whatever
  it happens to be. Write the actual baseline/skill content, verify
  structural completeness (valid JSON/YAML where applicable, required files
  present), push, and open a PR for team review. Do not merge it yourself.
- **`ai-toolkit`** (this repo, personal, solo): write directly to `main`,
  verify structural completeness, and push. No PR, no review gate — this is
  a personal repo.

**Keep the core adapter slim; never trim the full one.** An always-on pack has two
renderings, and adding a principle touches both:

- `adapters/CLAUDE.md.block` — the **full** list. This is the reference. It grows
  freely and nothing is ever deleted from it.
- `adapters/CLAUDE.md.core.block` — the **core**, and the only thing installed
  always-on. A short list of the pack's load-bearing rules plus one line pointing
  at the full version. Target **under 15 lines**.

A new principle goes into the full block always, and into the core **only if it
displaces something** or the core has room. This is what makes growth safe: the
reference is append-only, while the always-on cost is bounded by construction.
It also replaces deletion-based eviction, which needed provenance evidence the
pipeline does not have yet — nothing is removed, so nothing needs proving.

**State the trade honestly: the split is not free.** Whatever stays out of core is
**not loaded in any session** — it is a reference someone must choose to open, and
nobody opens it mid-task. On 2026-09-11 that cost was measured: two shipped rules
recurred specifically because they sat in a full block while the user tier
installed core, and one of the reopened notes concluded the rule "does not appear
to have been promoted into any baseline file" — the author had grepped the
*installed* file, which is the honest test.

So the core question is not "does it fit". It is **"if this rule fails to fire
again, was leaving it out of core the reason?"** If yes, it goes in core and
something else comes out. A pack whose core is full and whose next principle is
load-bearing is telling you the pack has become two packs; split it by trigger
rather than quietly filing the rule where it cannot fire.

Packs whose rules are file-type-scoped (SQL, .NET, Python, PowerShell) skip the
core/full question entirely: install the full block as a **path-scoped rule**
(`~/.claude/rules/<pack>.md` with `paths:` frontmatter) so it loads only when a
matching file is read, and costs nothing otherwise.

**Stamp provenance on every new principle.** In `baseline.md`, append to each
principle a marker naming the date it landed and the note it came from:
`_(added 2026-09-09, from `note-slug`)_`. This is not bookkeeping — it is the only
thing that makes "when was this added, what incident produced it, and has anything
cited it since?" answerable later. Without it the age-and-silence test in step 6
has no input, and the pipeline can never tell a load-bearing rule from a
decorative one. Backfill provenance for any principle you touch while you are in
the file anyway; do not attempt a full historical backfill in one pass.

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

### 8. Archive every processed source file

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
- **The step-5 activation answers** for every promoted rule, and for every
  recurrence note the diagnosed reason the shipped rule didn't fire.
- **The step-6 eviction outcome** — what was removed, what was considered and
  kept, or an explicit "nothing evicted this round" with the reason.
- Landing status for both repos (branch/PR link for `es-ai-toolkit`; merged
  confirmation for `ai-toolkit`).

The point of this manifest is that a future occurrence can recognize
itself and compare against this one — write it with that reader in mind,
not just as a changelog entry.

### 9. The completion gate

A pass is done when every gate below passes, not when the notes are archived.
Archiving is the *visible* output, which is exactly why it becomes the definition
of done by default — and every one of these gates can be false while the folder
looks clean. Report the result gate by gate, and report a `SKIP` as a skip with
its reason, never folded into a pass.

**9.1 — Structure.** `doctor` green in both repos. It checks the four version
places, the three byte-identical adapters, core tagging, and the personal-repo
boundary. A pack edited without bumping all four fails here.

**9.2 — Nothing regressed.** Both test suites green in `ai-toolkit`
(`baseline-tests.ps1`, `install-tests.sh`) plus `verify.sh`, whenever `scripts/`
or `skills/` was touched. The commit gate runs these; do not take a passing gate
on trust if you used `--no-verify`.

**9.3 — Every promoted rule is installed where it can fire.** This is the gate
this pipeline has failed most often, and it is not implied by 9.1. For each rule
promoted this round, name the file on disk that now contains it and the tier that
file loads at. A new pack needs `baseline apply`; a bumped pack needs re-applying
(`doctor -Fix` does the stale ones); a path-scoped pack needs `-Tools claude-rule`;
a rule promoted to core needs the *core* variant re-applied. `baseline status`
showing the new version is the evidence — not the commit landing.

**9.4 — Every recurrence note has a diagnosed cause, not a reword.** For each
`reopened-*.md`, the manifest names which of the three causes applied
(unreachable tier, buried mid-pack, wording that didn't match the situation) and
what changed as a result. "Reworded it" against an activation failure is a
failed gate, not a fix.

**9.5 — The eviction step produced a verdict.** Either something left, or the
manifest says explicitly that nothing did and why. Silence is a failure.

**9.6 — Nothing company-identifying entered the personal repo.** `doctor`'s
personal-repo boundary check covers the names it knows; also re-read each
principle you wrote into `ai-toolkit` for an internal service, client, repo,
ticket ID, or path that the check would not recognise.

**9.7 — Landing status is stated, not assumed.** `git rev-list --count
origin/<branch>..HEAD` for each repo, and the PR URL for the shared one. "I
pushed it" from recollection is not evidence, and an unmerged PR is an open
item, not a completed one.

**9.8 — The verification boundary is in the report.** Say what was *not*
verified. For this pass that is normally: the shared repo's rules do not take
effect in consuming repos until the PR merges and `baseline apply` runs there;
and no promoted rule has yet been observed firing in a real session.

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

## Part of a flow

This skill is a member of the **`improvement-pipeline`** flow (`flows/improvement-pipeline/flow.md`), together with `improvement-extraction`. That file holds the normative state graph — the guards, the terminal states, and the feedback edge that returns a failed shipped rule to intake. Read it when the question is *where this step sits in the loop*; this file covers only how to run the step itself.

On reaching a terminal state, append the flow's exit-log line to `$IMPROVEMENTS_ROOT/.flow-log`.
