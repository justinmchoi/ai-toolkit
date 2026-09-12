# Code Review Reporting Baseline

Status: active
Version: 0.1.0

Always-on discipline for *conducting and reporting* a code review — deciding
whether an observation is a finding at all, what scope the review actually
covers, and what shape a finding has to take to be actionable. This is a
distinct concern from `design-review`, which critiques a design proposal, and
from `pr-description`, which is about authoring the PR rather than reviewing
it.

Distilled from four reviews in 2026-09 where the review's *reporting* was the
defect: four non-findings nearly shipped as findings, a bot's resolved threads
nearly set the human reviewer's scope unverified, a confirmed bug was handed
back as an open question to the one person who had said she could not answer
it, and a brand-new module passed CI green with zero tests ever executed.

## Principles

1. Diff a candidate finding against sibling implementations before reporting
   it — a deviation-shaped observation is only a finding if it deviates.
   In any repo with sibling components (a monorepo, a plugin or module tree, a
   set of services from one template), run one comparison across siblings
   before writing an observation into the review. Usually
   `grep -rn "<pattern>" --include=<ext> <siblings>/` is the whole check.
   Three outcomes, three actions: **only this component does it** — a real
   finding, report it; **every sibling does it** — convention, not a finding,
   and if it is genuinely bad that is a separate repo-wide item rather than
   this PR's problem; **siblings are split** — the interesting case, so check
   which siblings are the maintained reference ones (the repo's own rules file
   usually names them) and compare against those. State the comparison in the
   review — "matches all 14 front-ends" is what stops the next reviewer
   re-raising it — and report the non-findings briefly too, so the author
   knows their choices were verified rather than skipped. Convention is not
   correctness: the check tells you *whose problem* something is, not whether
   it is fine.

2. A review thread marked resolved is the author's claim, not evidence —
   verify each against current source before layering a second review on top.
   When a PR has already been reviewed, by a bot or a person, that resolved
   status silently determines the second reviewer's scope: believing it means
   skipping those topics. Read the current source at each location instead. It
   pays three ways — no duplicated feedback, no topic silently dropped by both
   passes, and the "already fixed" lines are a good place to find what the
   first pass missed, because a reviewer that fixes a symptom often leaves the
   cause sitting on the same line. On 2026-09-10 all seven prior threads were
   genuinely fixed, and reading one of them in context is what exposed the
   real bug: the first pass had corrected an operation string's *casing* on a
   line whose *value* should never have been a literal at all. Say so in the
   review — "verified all N prior threads are addressed in current code; below
   is what's left". This is verification, not re-litigation: confirm the fix
   landed, then move on.

3. When a fix hinges on an unmade product decision, test current behaviour
   against every candidate answer before reporting it as blocked.
   Enumerate the defensible answers and check what the code does against each.
   If it satisfies **none**, it is a confirmed defect — report it as one, with
   the fix per branch, not as a question. Lead with the table: showing current
   behaviour failing every candidate is what converts "someone must decide"
   into "this is broken either way", and it is what lets the reader start work
   today. Then check whether sibling implementations already answer the
   question by convention; they often do, which demotes an apparent cross-team
   product decision to "match what the neighbours do" and removes the blocker
   outright. Only if current behaviour *does* satisfy one candidate is it
   genuinely a decision — and then say which one it implements, so the choice
   is "keep or change" rather than "design from scratch". This is not licence
   to invent the product decision: where branches diverge in user-visible
   behaviour, still surface the question — alongside the confirmed defect and
   the branched fixes, rather than instead of them.

4. In a CI that dispatches per-package by script name, a new package's
   `scripts` block is its coverage declaration — read it before the diff.
   When a pipeline runs each stage by invoking a per-package script and skips
   any package that does not define it, every stage the package omits is a
   stage it silently never runs. On 2026-09-10 a new module defining only
   `typecheck` and `build` went green with **zero tests ever executed**, and
   the bug the review found was exactly what one test would have caught. The
   skip prints one indented line into a log nobody reads. Report it as
   coverage, not style — "defines typecheck and build; CI skips lint and test
   for this package entirely" — and point at the nearest sibling that does
   define the missing stage, so adding it is a copy rather than a design task.
   This generalises past npm to any convention-over-configuration CI (a
   `Makefile` target, a `tox` env, a `just` recipe, a workflow matrix keyed on
   a file's existence): **absence is configuration, and absence is invisible in
   a green build.** Not every package needs every stage — a types-only or
   fixtures package legitimately has no tests — so the finding is "nobody
   decided this"; flag the gap and let the author confirm it was deliberate.

## Priority

Apply this baseline whenever reviewing someone else's change, but never use it
to override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions.

## Non-Goals

- This is not a review checklist for *what* to look for; it is about how a
  finding is qualified and reported once you have one.
- This does not cover critiquing a design proposal (`design-review`) or
  authoring a PR description (`pr-description`).
- This does not require a sibling comparison for the first component of its
  kind, or where the only sibling is deprecated and being migrated away from.

## Origin

Distilled 2026-09-11 from four notes captured during two 2026-09-10 reviews of
a new monorepo module and one 2026-09-11 session:
`diff-review-finding-against-siblings-before-reporting`,
`verify-resolved-review-threads-against-current-source`,
`unmade-product-decision-is-still-a-confirmed-defect`, and
`check-which-ci-stages-a-new-package-opts-into`. Before this pack, no baseline
in either toolkit covered review conduct: `design-review` critiques proposals
and `pr-description` authors them, so all four notes had no home and would
have been filed into a pack whose loading trigger does not match a review.

## Managed Block

The pack applies one managed block per instruction file through the standard
baseline CLI. The block can be updated or removed without rewriting
surrounding repo-specific instructions.
