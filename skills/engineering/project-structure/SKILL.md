---
name: project-structure
description: Scaffold a new personal project folder under a-projects/ with a standardized skeleton (master index, business/domain glossary, external-documentation folder, a stable home for design-decision sessions), or audit an existing organically-evolved project folder against that same convention and propose a migration plan for approval. Use this whenever the user wants to start a new project folder for ongoing multi-session work (a new client, initiative, or investigation), says things like "set up a project structure," "scaffold a project," "apply the project structure to X," or is about to create a new top-level folder/file in an existing a-projects/ folder without first checking whether an established convention already covers it. Also trigger proactively when a project folder has clearly grown ad hoc — multiple sessions each inventing new top-level folders with inconsistent naming (numbered vs. not, PascalCase vs. spaces vs. underscores) — even if the user hasn't explicitly asked to fix it.
---

# Project Structure

Scaffold a new personal project folder under `a-projects/` with a standardized skeleton, or audit an existing one against the same convention and propose a migration — never applied automatically.

## Why this convention exists

This isn't an arbitrary standard invented up front. It's extracted from a real, long-running project folder that organically evolved a structure across many work sessions — a master index, a business/domain glossary, a specs folder, numbered story folders — and that structure proved itself: sessions found things faster because of it, and its author explicitly said they liked the index + glossary pattern once it existed. The rule going forward: **check this convention before inventing new top-level structure in any project folder**, the same "mirror a sibling convention before inventing your own" habit that already applies to code and docs — just now with an actual template to mirror, instead of every project rediscovering its own structure from scratch.

Read this whole file before scaffolding or auditing anything — the convention only helps if it's applied consistently, and a half-remembered version of it is worse than checking the real thing each time.

## The convention

**Fixed reference folders** — exactly one of each, not chronologically ordered relative to one another, so no number prefix: PascalCase, no spaces (spaces in folder names cause real friction — every shell command touching them needs quoting, which this exact convention has already been bitten by once).

- **Always create when scaffolding a new project:**
  - `CLAUDE.md` — the session entry point, and the file a fresh session reads before anything else.
    It carries what the rest of the convention cannot: whether this is a docs/research project or a
    code repo, "read `0000-INDEX.md` first", the locations of any code repos the project references,
    and the read-only git guardrails for those clones. Copy `references/claude-md-template.md`.
    Without it a scaffolded project silently loses the most useful file it could have had — the
    project this convention was extracted from had one, and the convention did not.
  - `Glossary/` — business/domain term reference, one file per term, kept separate from any code-repo `CONTEXT.md` (that's precise code-domain vocabulary; this is "what does this business/telecom/industry term mean and why does the project care," for readers without that background). **A concept earns its own file once it's a distinct named entity/mechanism (not just a flag/field on another term) referenced from two or more other glossary entries** — this bar exists because it's easy to explain a related concept inline while writing a different term's file and never circle back to give it its own entry (this happened once already: a central connecting table got referenced from two files while writing them, met the bar, and had no file of its own until a direct re-check caught it). If a term meets the bar but doesn't get written yet, disclose that explicitly in `Glossary/README.md` rather than leaving the gap silent.
  - `ExternalDocumentation/` — specs, vendor docs, legacy internal docs, anything authored by someone else that the project treats as reference material rather than its own decisions.
  - `Grilling/` — design-decision / grilling-session output. One dated subfolder per session (`Grilling/YYYY-MM-DD-topic/`), not a new top-level `YYYYMMDD-Grilling/` folder invented each time — that ad hoc pattern is exactly what this skill exists to replace.
- **Create on demand, only when actually needed** — don't pre-create empty folders nobody's using yet: `MeetingPrep/`, `ToImplementNotes/`, `DbNotes/`, `Bugs/`, `SetupNotes/`, `DecisionRecords/`, `SystemFlows/`, or whatever cross-cutting category a specific project turns out to need. List these as available names in the scaffolded `0000-INDEX.md` so a future session reaches for one of them instead of inventing a new name for the same kind of thing.
  - `DecisionRecords/` — architecture/design decisions worth recording, one file per genuinely independent decision. Mirror the pattern already proven in this ecosystem's code repos (`Documentation/decision-records/`): sequentially numbered (`0001-slug.md`, `0002-slug.md`...) with a `README.md` index, kebab-case after the number — no separate `ADR-` file prefix needed, since the folder plus the number already signal what it is. Reach for this once a decision's relevance outlives the single story folder that produced it, rather than dropping an `ADR-*.md` file inside that story folder (a decision scoped tightly enough to matter only within one story is fine staying there — this folder is for the ones that don't stay scoped).
  - `SystemFlows/` — a systematically-built code-level flow/mechanism reference: one file per distinct flow or lifecycle (a class diagram + sequence diagram, or equivalent), built via deliberate exploration and kept current. Parallel to `Glossary/` but one layer down — business/domain *terms* vs. code-level *processes*. Worth creating once a project's own subject matter has enough distinct call-flow shapes that a reader benefits from one file per flow instead of scattered mentions across story folders; a subfolder inside it (e.g. `SystemFlows/lifecycles/`) is fine when a genuinely different grain of the same subject matter shows up (per-flow detail vs. cross-flow caller journeys) — see "Recognizing a grain shift," below.

**Sequential story/ticket folders** — one per unit of work, numbered because creation order genuinely matters here: `00N-<ticket-id>-<short-kebab-name>/` (e.g. `007-4521-migrate-billing-export/`). This part already worked before this skill existed — don't change it, just keep using it.

**Cross-project reference links** — when a sibling project already documents a term, flow, or
decision this project needs, **link to it and record why the link exists** (supersedes / precedent /
shared domain); never copy the content. Two copies drift, and the drift is silent. Formalized
2026-09-09 after a second load-bearing use: a project superseding a sibling's scope inherited that
sibling's 17-term glossary by reference rather than duplicating it.

**One deliberate exception**: `0000-INDEX.md` keeps its numeric prefix specifically so it sorts before every PascalCase folder and every `00N-...` story folder in a plain alphabetical directory listing. State this explicitly inside the INDEX itself (the template below already does) so it reads as an intentional choice, not leftover inconsistency.

**Files within any folder**: kebab-case `.md` — matches what already works inside `Glossary/` and in story-folder files like `implementation-plan.md`. **One more deliberate exception**: files inside `DecisionRecords/` are `000N-kebab-slug.md` (numbered, mirroring the code repo's own decision-records convention) rather than plain kebab-case — the number is load-bearing (creation/sequence order matters, same reasoning as story folders), not decoration.

## Recognizing a grain shift (when a follow-up request needs a new category, not more depth)

A request that sounds like "add more to what's already there" is sometimes actually a different information *grain* — e.g. per-unit detail (one file per endpoint/flow/term) vs. a cross-unit journey (the sequence several of those units get used in together). The test: does the new content naturally belong inside one existing file, or does it only make sense described across several of them? If the latter, it's a grain shift — create a new, clearly-labeled parallel category (a sibling folder, or a subfolder like `SystemFlows/lifecycles/`) and cross-link it, rather than forcing the new content into whichever existing file seems closest. Don't over-apply this: most follow-ups genuinely are "more detail on this one thing" and belong right there.

## Observed but not yet formalized (candidates for a future pass)

Real sessions occasionally invent structure this scaffold doesn't account for yet. When that happens, don't retrofit the skill on the spot — note the pattern here and revisit it deliberately later, the same way a grain shift gets flagged rather than forced into an existing file. Candidates observed so far, all from one 2026-09-04 device-trade-in project session, none urgent or settled:

- **`Templates/` folder** — a project-level folder holding reusable document templates specific to that project (distinct from this skill's own `references/*-template.md`, which are for scaffolding new projects, not for a project's own working documents).
- **Dated Q&A closeout index** — a single file summarizing a session's resolved questions, separate from `Grilling/`'s design-decision output.
- **Letter-suffix continuation files** — `open-items-b.md` continuing `open-items.md` once a topic file grows unwieldy, rather than growing one file indefinitely.

Whether any of these earn a place in the fixed convention above — and if so, what the naming/placement rule should be — is an open question for a future pass, not a decision made here.

## Scaffolding a new project

1. Confirm the project name and location with the user if it's not obvious from context — default to a new folder directly under `a-projects/`, matching sibling project folders. List `a-projects/` first (`Glob`/`ls`) rather than assuming what's already there or what naming pattern siblings use.
2. Create:
   - `0000-INDEX.md` — copy `references/index-template.md`, filling in the project name and leaving the quick-answers table and folder map with their example/placeholder rows until real content exists to point at. Don't invent example content — an empty table with a header is more honest than filled-in placeholders that look like real entries.
   - `Glossary/README.md` — copy `references/glossary-readme-template.md`, then append any
     project-specific sections it needs (a cross-project inheritance table, an explicit disclosure of
     terms that meet the own-file bar but aren't written yet). The template is a starting point, not
     a file to leave untouched — "verbatim" was the original wording and did not survive contact.
   - `ExternalDocumentation/README.md` — copy `references/external-documentation-readme-template.md` verbatim.
   - `Grilling/` — create the empty folder itself; don't create a dated subfolder yet, that happens when an actual session needs one.
3. Report the created structure back to the user, and mention explicitly: story folders (`00N-<ticket-id>-<short-name>/`) get created as real work starts, not upfront — an empty `001-.../` folder before any ticket exists is just clutter.

## Auditing or retrofitting an existing project

Existing projects evolved before this convention existed and won't match it exactly, and that's expected — this is a retrofit tool, not a "you did it wrong" tool.

**Never rename or restructure anything automatically.** Renaming a folder in one of these projects touches every cross-reference in its `0000-INDEX.md`, any `Resources.txt`-style repo-path file, and every story folder that links back to whatever moved — a silent rename breaks those links without anyone noticing until later.

1. List the project's current top-level contents directly (`Glob`/`ls`), not from memory of a prior read or from what the project's own INDEX claims — the INDEX itself can lag behind the real folder contents (this happened once already: an orphaned duplicate folder sat completely undocumented until a fresh listing caught it).
2. Compare each item against the convention above. Categorize honestly into three buckets, not two — the third bucket matters as much as the first two:
   - **Already matches** — no action needed.
   - **Would rename under the new convention** — e.g. `Meeting Prep/` → `MeetingPrep/`, `700-TOIMPLEMENT-NOTES/` → `ToImplementNotes/`.
   - **Doesn't fit any category in this convention** — flag it and ask, don't force it into the nearest-looking bucket just to make the audit look complete. Some project-specific folders (a repo clone, a zipped snapshot, loose screenshots) are legitimately outside this convention's scope.
3. Present the proposed renames as an explicit before → after list, and for each one, name the specific files that reference the old name and would need updating alongside it. Let the user approve renames individually or all at once — their call, not a forced all-or-nothing choice.
4. Only after approval, execute the approved renames and fix every cross-reference that pointed at an old name. Re-`Glob` afterward to confirm nothing was missed, rather than trusting the plan matched what actually happened.

## Reference templates

- `references/claude-md-template.md` — the project `CLAUDE.md` skeleton: project kind, "read the
  index first", repo locations, and the read-don't-disturb git guardrails.

- `references/index-template.md` — the `0000-INDEX.md` skeleton: quick-answers table, folder map grouped by category, a conventions section documenting the naming rules above, and the maintenance instruction ("when you add a new folder, add one line here").
- `references/glossary-readme-template.md` — the `Glossary/README.md` skeleton.
- `references/external-documentation-readme-template.md` — the `ExternalDocumentation/README.md` skeleton.
