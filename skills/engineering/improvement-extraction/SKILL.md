---
name: improvement-extraction
description: Scan the current session (or, in full-sweep mode, the ENTIRE session transcript including everything dropped by prior compactions) for candidate CLAUDE.md/AGENTS.md baselines, candidate Claude Code skills, or improvements to an existing baseline/skill/template, and write them as structured notes to a configurable output folder for later manual review. Use when the user asks to extract improvement ideas, capture process improvements, or save candidate baselines/skills surfaced during this session — phrases like "extract improvements", "capture what we'd add to CLAUDE.md", "save this as a candidate skill idea". For full-sweep mode specifically, invoke with the arg `full-session` or `--fs` (e.g. "/improvement-extraction full-session") for a deterministic trigger, or phrases like "go through the entire session", "full/thorough sweep", "check everything discussed".
status: trial
problem: Candidate process improvements (baseline rules, skill ideas) surfaced during a session were only captured by manually asking, in full sentences, for the session to be scanned and written up — a repeated, mechanizable step done by hand every time.
when-not-to-use: Do not use for capturing a full session log (that belongs to a work-log capture skill such as capture-assistant-session), for cross-company-portable personal lessons (that belongs to a personal-vault lesson-extraction skill), or for ideas too narrow to generalize past the current task.
maintainer: Justin Choi
---

# Improvement Extraction

Scan the current session for candidate CLAUDE.md/AGENTS.md baselines or candidate skills, and write each as a structured note to a configurable output folder. This is a scratch capture step — candidates land here for later manual review, not automatic promotion into this repo's baselines or skills.

## Step 1 — Resolve the output root

- Read `IMPROVEMENTS_ROOT` from the environment.
- If unset, ask the user for the path once, then use it for this run only. Tell them how to persist it so this step isn't needed again:
  - Windows: `setx IMPROVEMENTS_ROOT "<path>"`
  - macOS/Linux: `export IMPROVEMENTS_ROOT="<path>"` in their shell profile
- Never write the resolved path into this skill file or any committed content — the environment variable is the only place it lives.

## Step 1b — Full-session sweep mode (only when explicitly asked)

Default scope is "the current context" — what's actually visible in this conversation right now, which after one or more compactions is only a summary of most of the session, not the real thing. That's fine for a normal end-of-task run. It costs roughly 100-120k tokens per chunk (a handful of chunks for a normal session, ~8-10 for a multi-day one), so this mode is never the default — only enter it when triggered:

**First, check whether it would buy anything.** This mode exists to recover what *compaction dropped*. If no compaction has happened and the whole session is still visible in context, the default scope already covers every turn, and fanning out agents to re-read a transcript you are already holding is pure cost for zero new coverage. When the flag is passed but the session is fully visible, say so and run the default scope instead — the flag is a request for completeness, and completeness is already satisfied.

- **Deterministic trigger (preferred):** the skill's `args` is (or contains, as a whole token) `full-session` or `--fs` — e.g. invoked as `/improvement-extraction full-session` or `/improvement-extraction --fs`. Either token means the same thing; no judgment call needed, and this is the reliable way to ask for it on purpose.
- **Fallback trigger:** the user's own words plainly ask for it without using the flag — "go through the entire session," "full/thorough sweep," "check everything discussed," or similar. Use judgment here since phrasing varies; when genuinely unsure whether a vaguer request means this mode, ask rather than assume — the token cost is real enough that guessing wrong is expensive in both directions.

1. Run the bundled script to pull the real transcript and split it into review-sized chunks:
   ```
   python3 <this skill's dir>/scripts/extract_transcript.py --out <scratch dir> --chunk-lines 2400
   ```
   Omit `--session` — it auto-detects the current session's `.jsonl` (most-recently-modified transcript under this project's `~/.claude/projects/<encoded-cwd>/`) and prints which one it picked; pass `--session <path>` explicitly if that's ever wrong, and treat the printed path as something to actively verify (session ID + file size) if a background agent's later report reads suspiciously thin. Use a scratch dir outside any repo (e.g. the job's own tmp dir) — these chunk files are working material, not something to commit. The script prints the exact chunk filenames it wrote — use those literal paths when dispatching agents in Step 3, don't assume a `chunk_1.txt`/`chunk_2.txt` (1-indexed) naming convention; the real files are 0-indexed (`chunk_00.txt`, `chunk_01.txt`, ...) and the last one is typically much shorter than the rest (just the tail).

   **Known limitation:** auto-detect matches by the *current* working directory, not the cwd the session actually started in — if the working directory changed mid-session (a `cd`), it looks up the wrong project folder (or none) instead of the one holding the real transcript. Workaround: when auto-detect fails or seems to pick the wrong transcript, manually list `~/.claude/projects/` for the session's ORIGINAL working directory (not wherever you `cd`'d to later) and pass it explicitly via `--session`. If multiple same-day sibling `.jsonl` files in that folder have mtimes too close together to distinguish, disambiguate by grepping each for distinctive content (a project name, a specific topic mentioned) and comparing match counts, rather than guessing from mtime alone. Observed twice on 2026-09-04 — same day, two separate sessions, same failure mode.
2. Do Step 3 (dedup) first, so you have the existing-and-promoted topic list ready to hand to every chunk agent — from **both** `IMPROVEMENTS_ROOT` and `IMPROVEMENTS_ROOT/Done/`.
3. Dispatch one `Explore` agent per chunk file — **all in a single message**, as separate tool calls. Sequential Agent calls across separate messages run one at a time, not concurrently; batching them together is what actually parallelizes the sweep. Each agent's prompt: the chunk file path, the same three categories from Step 2, the existing-candidate filename list from Step 3 (so it can skip known topics), and an explicit note that it's one of many chunks and won't see the whole session — report findings as a compact structured list, do not write files.
4. As each chunk's task-notification arrives, do not write files yet — collect all of them first. The same underlying incident routinely gets surfaced by two or three different chunk agents (chunk boundaries are arbitrary; long-running incidents span them), so writing per-chunk would fragment one lesson into duplicate files. Merge those before proceeding to Step 4.
5. Continue at Step 3 (final dedup pass against `IMPROVEMENTS_ROOT`) and Step 4 as normal, using the merged, deduped list.

## Step 2 — What counts as a candidate

Three categories qualify:

1. **Candidate portable baseline** — a rule that, had it existed in CLAUDE.md/AGENTS.md at the start of the session, would have prevented a mistake, correction, or ambiguity that actually came up. General enough to survive a future session or a different repo.
2. **Candidate skill** — a repeatable, at least partly mechanizable procedure that came up this session and would be cheaper to run as a scripted/semi-scripted skill next time than to redo by hand.
3. **Candidate improvement to an existing skill/baseline/template** — a friction point hit while actually *using* one this session: a verbose template, an ambiguous step, two sections that always say the same thing, a rule that no longer fits how it gets applied. Don't limit the scan to brand-new ideas; using an existing tool is itself a chance to spot what it should stop doing.

Exclude: routine bug fixes, one-off decisions, anything already covered by an existing baseline or skill, and anything too narrow to generalize past this one task.

## Step 3 — Dedup against existing notes **and against the promoted archive**

Check **two** places, not one:

1. `IMPROVEMENTS_ROOT` — the live, not-yet-reviewed notes.
2. `IMPROVEMENTS_ROOT/Done/` — everything already reviewed and promoted. **This is the folder most likely to already contain your candidate**, and it is the one that gets skipped. Live notes get archived on promotion, so the live folder is routinely near-empty while `Done/` holds hundreds.

**Grep both; do not skim filenames.** Once `Done/` is more than ~50 files it is not skimmable, and filename similarity is a bad proxy in both directions — a note called `check-local-disk-when-chat-tool-cant-render-attachment.md` looks like a match for a work-item-attachment candidate and is a different rule entirely, while `verify-gitops-manifest-against-origin-default-branch-not-local-checkout.md` looks unrelated to "find a module in a monorepo" and is exactly that rule. Search on each candidate's distinctive terms instead:

```sh
grep -ril "<distinctive term>" "$IMPROVEMENTS_ROOT" "$IMPROVEMENTS_ROOT/Done"
```

Then act on what you find:

- **Hit in `IMPROVEMENTS_ROOT`** — extend that file (add an observation, a nuance, a "seen again" note) instead of creating a near-duplicate.
- **Hit in `Done/`** — the stronger signal: the rule was already captured *and promoted*, and the failure still happened. This needs **two** writes, because one of them would never be read again:

  1. **Append a "Seen again" section to the archived note**, recording the new occurrence and, critically, **why the shipped rule didn't fire** (never installed? wrong scope? buried in a long pack?). Do **not** reword the rule itself — a rule that failed for activation reasons is not improved by rephrasing, and rewording looks like progress while changing nothing. This write is for provenance: it keeps the recurrence history with the rule.
  2. **Reopen it into the live folder.** `baseline-gap-review` reads only what is *directly under* `_Improvements/` and explicitly skips `Done/`, so an append to an archived note is invisible to every future review pass. Write a short live note at `IMPROVEMENTS_ROOT/reopened-<original-note-slug>.md` that links back to the archived one and states the **activation failure**, not the rule. Keep it to: which shipped rule failed, where it is installed (or isn't), the new occurrence, and what would make it fire next time.

  Frame the reopened note as a question about the *delivery mechanism* — installed at the wrong level, competing with too many other bullets, worded for a situation that didn't look like this one. A recurrence is evidence about activation; treat rule-text edits as the last resort, not the first.
- **No hit** — proceed to Step 4.

## Step 4 — Write one file per genuinely new idea

Filename: `kebab-case-topic.md`. Use this structure — every field earns its words; skip a section if the one above it already covers it:

```markdown
# <the rule/skill, one line>

**Captured:** <date> — <repo/PR, one line>

## Trigger
<the incident that surfaced this — self-contained, no restating in a second section>

## Rule
<the actionable rule or skill, stated directly>

## Boundary
<where this should NOT apply — omit if there's no real risk of over-applying it>

## Next step
<what it'd take to formalize this — omit if "review and adopt" is all there is to say>
```

Write tight: one word beats two if it carries the same meaning, two words beat a clause, a clause beats a sentence. Don't restate the same fact in two sections (the old "observation" vs. "what triggered this" split routinely did — that's why they're merged into one `Trigger` section now).

No confirmation gate before writing — `IMPROVEMENTS_ROOT` is a working/scratch folder for candidate ideas, not curated long-term memory or this repo's governed skill/baseline inventory.

## Step 5 — Report back

State which files were created vs. extended, with a one-line summary of each.

## Relationship to other end-of-session tools

This is a third, distinct capture tool, not a replacement for whatever session-log or personal-lesson skills already exist in this environment:

- A **session-log capture skill** (e.g. `capture-assistant-session`) → full session log, written to a personal work-log vault.
- A **lesson-extraction skill** → sanitized, cross-company-portable personal knowledge distilled into a personal vault for the user's own long-term reference. It is not aimed at producing a repo baseline or skill.
- `improvement-extraction` (this skill) → things learned this session that could become a future CLAUDE.md/AGENTS.md baseline rule or a Claude Code skill, written as one candidate markdown file per idea so each can be reviewed and formalized into an actual baseline or skill later, one at a time. Stays inside the work context (a project folder), not a personal vault.

If neither of the other two skills exists in this environment, that's fine — this skill still runs standalone.
