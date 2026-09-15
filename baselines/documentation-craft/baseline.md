# Documentation Craft Baseline

Status: active
Version: 0.7.0

Always-on discipline for documentation structure, mechanics, and prose-style
decisions — how a document is organized, linked, scoped, and worded. This is
a distinct concern from `code-doc-sync`, which is about keeping documentation
synced to actual code/system behavior, and from `handoff-doc-discipline`,
which is about the living-document lifecycle of a single resume/plan file
that gets edited in place. This baseline applies whenever the agent is
writing, restructuring, relocating, or reviewing documentation of any kind —
independent of whether that documentation happens to describe code.

## Principles

1. **[Highest-priority principle in this baseline — see Priority.]** Collapse
   to the smallest unit that still carries the full idea, recursively, at
   every level.
   Use one word if one word conveys what two would; use two words if they
   convey what more than two would; use a phrase if it conveys what a clause
   would; use one sentence if it conveys what more than one would. Apply this
   test recursively at every level of the document — word, phrase, clause,
   sentence, paragraph, section — not just once at the sentence level.
   Length is not a neutral default to leave alone; it is the thing this
   principle exists to push back against. This is distinct from durable
   audit/decision records (ADRs, incident writeups, handoff docs), where
   completeness matters more than brevity and this default does not apply —
   see Non-Goals.

2. Turn an in-prose recommendation to edit a different file into an action or
   a tracked item, not just a sentence.
   Before requesting review, if a response recommends an edit to a different
   file than the one being written, either make that edit immediately or
   explicitly track it as an open item somewhere it will be re-surfaced (a
   TODO list, an issue, a tracked-items section). A recommendation written in
   one document's prose is not itself a completed action, and prose
   recommendations buried in an unrelated document are the easiest kind of
   follow-up to lose.

3. Verify link integrity with a script after moving or renaming cross-linked
   markdown files, and re-check every file that was touched.
   After moving or renaming cross-linked markdown files, verify link
   integrity with a script that resolves every relative link target — don't
   rely on memory of what was touched. Re-check every file that WAS touched,
   not just the ones the move intended to reference, for over-broad
   find/replace corruption of unrelated links; a global search-and-replace
   run to fix the intended links can silently mangle an unrelated link that
   happened to share the same substring.

4. Recognize a request spanning or sequencing multiple existing units as a
   shift in information grain, and create a new parallel category instead of
   forcing it in.
   When a follow-up documentation request spans or sequences multiple
   existing units rather than adding depth to any single one, recognize it as
   a shift in information grain (e.g. from "detail on one thing" to "an index
   or sequence across several things") and create a new parallel category or
   document instead of forcing it into an existing file. Stuffing a
   cross-cutting concern into one of the units it cuts across leaves it
   discoverable from only one of the places a reader would look.

5. Place general system knowledge in the producer's repo, and keep only
   tool-specific content in the consumer's repo.
   When writing or relocating documentation that spans "how the system
   generally works" and "how this one tool/consumer uses it," place general
   system knowledge in the producer's repo (linked from the consumer) and
   keep only tool-specific content in the consumer's repo. Decide this
   per-section, using the test "would this be equally true for a different
   consumer of the same system?" — not by where the need for the doc first
   arose. A section that would read identically if written for any other
   consumer belongs with the producer.

6. Keep an inline bug-fix comment to a short "does X — previously did Y"
   statement; move audit-trail evidence elsewhere.
   Inline bug-fix code comments should be a short "does X — previously did
   Y" statement in 1-2 sentences, with no duplicated phrasing and no
   ambiguous reused terms between the "does" and "previously did" halves.
   Move full audit-trail/cross-validation evidence (what was tested, what
   confirmed the bug, links to the investigation) to a separate durable doc —
   never inline in the comment itself, where it outlives its usefulness and
   clutters the code it's attached to. Principle 6 is Principle 1 applied
   specifically to code comments — read together, not as unrelated rules.

7. **Externalize non-fresh content out of the mandatory-read path; leave a
   one-line pointer.**
   When adding content to a file in the agent's mandatory-read path (a
   CLAUDE.md/AGENTS.md-style file read every session), ask whether it needs
   to be fresh every session; if not, externalize it to its own file with a
   one-line pointer left in place. The mandatory-read path is a scarce
   attention budget, not just another place to put things.

8. **Elicit a highly personalized document through layered guided
   discussion, writing each layer as it's agreed.**
   For a highly personalized document (a persona, a voice/style guide, a
   decision doctrine), elicit its content through layered guided discussion
   and write each layer to file as soon as it's agreed, rather than
   discussing everything first and writing once at the end.

9. **Resolve every reference in a shared artifact for its *audience*, not
   just for you.**
   Before a reference ships in anything shared — repo docs, code comments,
   ADRs, PR descriptions, ticket comments — ask who reads this and whether
   they can open it. Rank targets by reachability: (1) **inline the
   substance** — if it fits in two sentences it is not a reference, it is a
   sentence you have not written yet; (2) same repo, stable path; (3) a
   shared system the audience already uses (the wiki, the ticket, the
   runbook); (4) another repo, only if the audience certainly has access;
   (5) never a personal folder, a local path, a chat message, or "see the
   earlier discussion", which becomes a dead pointer the moment the session
   ends. Two sharpeners: **never cite by position** ("#1", "the third
   bullet", "the section above") — lists get reordered and items get
   deleted, so cite by stable name or inline; and **match the genre** —
   domain knowledge belongs in documentation a human would look for, not in
   an agent-instruction file that happens to contain it. Provenance framing
   without a path is fine and often useful ("this traces back to notes kept
   outside this repo"); the failure is the bare path that reads as
   actionable and is not. Four unfollowable references across two
   repositories surfaced in one day on 2026-09-14, in all four flavours, one
   of them written while correcting another. Cheap to sweep for:
   `grep -rniE "in .*'s own notes|see (the )?(earlier|above) discussion"`
   over `*.md` and source files before pushing, paired with a relative-link
   checker — the checker proves a path *exists*, this proves the reader can
   *reach* it.
   _(widened 2026-09-15, from `every-reference-must-resolve-for-the-reader`)_

10. **Write two separate documents when one change must inform two
    audiences with genuinely different needs.**
    When one underlying change must inform two audiences with genuinely
    different needs (a reviewer deciding whether to approve, a learner
    absorbing what to do differently), write two separate documents rather
    than forcing both purposes into one.

11. **Propagate a correction to every deliberately duplicated copy, not
    just the one pointed out.**
    When content is deliberately duplicated across multiple files (each
    adapted per destination), propagate a substantive correction to every
    copy, not just the one explicitly pointed out — check for sibling
    duplicates before considering a fix done.

12. **Default decision-dense technical documents to bolded-label point
    form, chosen by structure not document type.**
    Default decision/change-dense technical documents in general — not only
    PR descriptions or review comments — to bolded-label point form when the
    content is structurally a list of discrete points; choose format by the
    content's actual structure, not by document type or length.

13. **Do one full linear read-through after several rounds of incremental
    edits, before finishing.**
    After several rounds of incremental, localized edits to the same
    document, do one full linear read-through before finishing — per-edit
    review only catches whether each addition is correct in isolation, not
    whether the document's ordering and cross-references still hold (e.g. a
    conclusion that cites content added after it).

14. **Append a dated superseded block in place rather than rewriting or
    forking a resolved decision record.**
    When a resolved decision record is superseded, append a dated
    "superseded" block in place, preserving the original reasoning, rather
    than rewriting the file or forking to a new one.

15. **Classify an outdated document before correcting it: snapshot vs.
    continuously-maintained reference.**
    Before correcting an outdated document, classify it first: a
    point-in-time snapshot (annotate/point to the current source, leave the
    body's original reasoning unchanged) or a continuously-maintained
    reference (correct in place, dated) — the two natures require opposite
    correction strategies, and using the wrong one for either causes real
    problems.

16. Run a comment-tightening pass as diff+grep+rebuild, and never paraphrase
    a referenced code identifier while shortening a comment.
    Given a branch and a base ref, tighten wordy comments by: extracting
    every added comment line from the diff, grouping into contiguous
    multi-line blocks, flagging blocks over N lines as candidates, editing
    one file at a time, then re-running the same diff scan to confirm
    convergence — and gate the commit on a full rebuild plus affected test
    suites passing, since a comment-only edit can still introduce a real
    regression. Specifically: when shortening or paraphrasing a comment that
    references a specific code identifier (an enum member, a method name, a
    field name), never invent a shortened/paraphrased form of the identifier
    itself — keep it byte-for-byte as it appears in code, or re-verify
    against the actual declaration before using a shortened form. Diff any
    identifier-looking tokens in the "before" vs. "after" text and flag if
    the after-text introduces a token not found by grep in the codebase.

17. When synthesizing a messy human source into a clean doc, flag
    contradictions found in it — don't silently pick one.
    When normalizing a messy human source (meeting notes, a chat transcript,
    a voice-memo dump) into a clean, structured doc, actively look for
    internal contradictions in the source rather than only looking for facts
    to extract. When found, preserve the contradiction explicitly in the
    output (quote or paraphrase both sides) and flag it as unresolved —
    don't silently resolve it by picking whichever reading seems more
    plausible; only the original author can adjudicate what they meant. This
    applies specifically to normalizing informal/real-time notes where
    contradictions are a natural byproduct of fast note-taking; doesn't
    apply to genuinely ambiguous phrasing with no real contradiction, which
    can be clarified with reasonable inference noted as an inference.

18. Update a project's own knowledge folders when a fact is learned, not
    just when code changes.
    When a conversation resolves an open design question, corrects a stale
    assumption, or surfaces a new durable domain term, proactively update
    the project's own knowledge folders (glossary, decision log, an
    open-questions folder) in the same turn. The trigger is "a durable fact
    became known," not "code changed" — don't wait to be asked, and don't
    rely on a code-change-triggered doc-sync rule (see `code-doc-sync`) to
    cover conversational/business findings it was never scoped to catch.

19. Before publishing a Mermaid-in-HTML (or other HTML/XML-rendered)
    diagram artifact, check for two specific rendering traps.
    (a) Never rely on `<br/>` inside a `Note over` statement for a line
    break — some renderers silently drop it, concatenating the two halves
    with no space; use consecutive stacked `Note over` lines instead,
    reserving `<br/>` for message-arrow labels only, which do render it
    correctly. (b) Grep the file for any bare `&` not already part of a
    valid entity (`&amp;`, `&gt;`, `&lt;`) before every publish, not just the
    first one — domain text containing a literal `&` will otherwise break
    rendering silently. Irrelevant for plain markdown or code-only
    artifacts.

20. Tag each listed mitigation as closes-at-root, reduces-odds, or
    detection-only — never a bare "addressed by."
    When documenting mitigations against failure/risk scenarios (tables,
    ADRs, recommendation sections), never use a generic verb like "addressed
    by"/"closes"/"fixes" unless the item is actually a guarantee — explicitly
    tag each mitigation as closes-at-the-root, reduces-likelihood, or
    detection-only, and add an explicit disclaimer near the table if nothing
    in the tier being described is a guarantee. Re-check every section of
    the document for the same overstatement once one instance is found — it
    tends to recur in prose summaries even after the table itself is fixed.

21. Given a false claim already found once, run a fact-correction sweep
    across the whole genre, not just the one hit.
    Given a wrong claim already flagged once: (a) grep the literal text
    across every directory touched this session; (b) for each hit, classify
    it as live/current vs. deliberately-preserved-historical and apply the
    matching fix convention (silent correction in live docs; a visible
    correction note in sections deliberately kept as history, per principle
    17's supersede-in-place convention); (c) beyond the literal string,
    re-scan every document of the same genre (all ADRs, all planning notes)
    for the same *class* of issue, since the same mistake is often phrased
    differently elsewhere — don't stop at fixing the one instance that was
    pointed out.

22. Compute the exact cut for a known platform character limit up front —
    don't trim in small blind iterations.
    When trimming drafted content to a known hard platform length limit
    (a PR description cap, a field's character limit), compute the exact
    excess (current length minus limit) up front and make one deliberate
    cut sized to that excess, or draft within a per-section budget from the
    start, rather than iterating blind small edits with a recount after
    each one. Only worth this for a known, fixed platform constraint — not
    worth building process around for a one-off trim with no known limit.

23. Match the codebase's existing selective doc-comment convention; don't
    default to documenting everything or nothing.
    When adding or converting structured doc comments in a pass (XML doc,
    docstrings, Javadoc — whatever the language's convention is), check
    whether the codebase already applies it selectively (structured comments
    on some public members, not all; plain inline comments on
    implementation detail) and match *that* granularity rather than a
    blanket rule. Apply structured doc comments only to genuine public API
    surface intended for generated-doc/IntelliSense consumption; keep plain
    inline comments on private implementation, especially ones carrying
    "why this line does X" reasoning that doesn't map to a structured
    comment's per-member shape — converting it is pure churn against the
    file's established style.

24. Never manually hard-wrap prose in a markdown file — write each
    paragraph/bullet as one continuous line and let the renderer
    soft-wrap. Manual line breaks render as garbled mid-sentence breaks in
    plain-text viewers, narrow terminals, and some diff tools.

25. Renumbering a markdown doc's sections after an insertion should be one
    scripted old→new mapping pass over headers, the TOC, and every
    cross-reference — not manual header-by-header edits discovered
    piecemeal across multiple ad hoc greps.

26. When adding a markdown TOC to a doc with non-trivial headers
    (punctuation, dashes, backticks), generate the anchor slugs via a
    script implementing the real GFM slug algorithm rather than
    hand-typing them, and cross-check against any existing TOC in the same
    project.

27. When a batch mechanism fails all-or-nothing and the per-item mechanism
    fails per-item, prefer per-item as soon as the batch is more than a couple
    of items.
    Authoring 18 prose files as chained shell heredocs in one call produced a
    single parse error and **zero** files — not seventeen, because the parse
    failure precedes any execution, so one stray character in ~600 lines
    discarded all of it, and locating it would have cost more than starting
    over. Use the dedicated file-writing tool, one call per file: a defect
    fails that file only, each result confirms its own write, and no quoting
    rules apply to the content at all. Markdown is close to worst-case input
    for shell quoting — backticks, apostrophes in ordinary English, `$`, `{}`,
    `!`, and fenced blocks that may themselves contain heredocs — and a quoted
    delimiter protects the body from expansion while doing nothing about the
    surrounding command-line parse. Heredocs stay right for one file, a
    multi-line commit message, or generating from known-safe content. The
    token cost of extra calls is far below one silent total failure plus the
    hunt for the offending character.
    _(added 2026-09-11, from `batch-heredoc-file-authoring-fails-all-or-nothing`)_

28. For teaching material with a real audience, four structural choices do
    most of the work — none of them about the content.
    (1) **Number the files and put the reading order in file `00`.** A teaching
    set has a load-bearing sequence; `00` carries a table of what each file
    gives you, a 60-second summary, and the two or three mental models that
    make the rest click, so a reader who stops there is still net ahead.
    (2) **End each file with "you should now be able to answer…"** — four or
    five questions phrased the way a colleague would actually ask them. It
    turns a passive read into a self-test, and writing them exposes sections
    that explained a mechanism without conveying when it matters.
    (3) **Give every factual row an evidence column** naming the command that
    produced it: the reader can re-verify without asking, a row with no
    runnable command is visibly an inference, and those commands become the
    verification suite almost for free.
    (4) **Separate terms from mechanisms from narrative, and cross-link.** A
    glossary answers "what is X" in one screen, a flows directory answers "what
    happens, in order, when Y" one file per flow, and the teaching narrative
    threads them — three questions at three grains, and one document serving
    all three serves none.
    On tone: write failure modes as observations ("every new joiner reports
    this") rather than warnings; it is more memorable, because it tells the
    reader they are about to have a specific experience. This is for material
    with an audience and a sequence — a reference doc for your own later use
    needs neither the questions nor the reading order, though the evidence
    column is worth it well below that bar.
    _(added 2026-09-11, from `teaching-doc-structure-that-survives-handoff`)_

29. **Executive Summary is a document type with a hard 1000-word gate.**
    Distinct from a from-zero explainer: it is the artifact you hand someone to
    explain a domain, and it has a fixed shape — vocabulary in one table (one
    line per term, no prose); the two or three relationships everything else
    hangs off; old flow vs new flow side by side where a system has been
    rewritten; one real, named, ideally production scenario; every operation
    tabulated; watch-outs numbered and ranked by how expensive getting each
    wrong is; the one-sentence version. The cap is the point — a one-pager
    nobody finishes explains nothing — so write to fit it *first*, before asking
    whether it can be raised. When it genuinely will not fit, escalate by
    **100 words at a time** and state what the extra 100 bought; never
    open-ended, and three escalations in a row is the signal the document is
    really two documents. Record the current `wc -w` count in the folder's
    README so drift is visible. The number is what made this work: a "default
    to concise, not exhaustive" preference had already been captured once and
    failed again, while the cap produced a 974-word draft that covered more
    usefully than the longer ones. Not for durable audit or decision records
    (ADRs, incident writeups, handoff docs) where completeness outranks
    brevity — those have the opposite failure mode — nor for reference material
    meant to be searched rather than read end to end.
    _(added 2026-09-15, from `executive-summary-word-gate`)_

30. **Lock a verified executive summary; report and propose, never silently
    fix.**
    Once the claims on a page that gets handed to *other people* have been
    re-verified against source or live data in one pass — not trusting earlier
    passes in the same session — add a banner naming the lock date, the owner
    whose explicit approval is required for any edit including "small" fixes and
    wording tidy-ups, and the word budget with its current count. While locked,
    wrong or stale content is reported and proposed, never silently corrected.
    That restraint is the whole point: the instinct on spotting an error is to
    fix it, and on 2026-09-14 that instinct introduced two errors *into* a
    document that had been correct — a capability claimed for a bulk-import
    feature that cannot do it, and a claim about which component walks a
    fallback order that was never verified — across eight revisions, both of
    which still read fluently, still fit the budget, and looked exactly like the
    correct rows. Verification is what earns the lock, not the banner: a
    locked-but-unverified page is worse than an open one because it carries
    authority it has not earned, and the locking pass is a re-check rather than
    a formality. Unlocking is a decision the owner makes, never an inference
    from the change looking small; the banner's date independently records when
    the content was last known true. For documents that are distributed and
    acted on — summaries, onboarding pages, anything handed to someone who will
    not re-derive its claims — not for working notes or a reference someone
    maintains as they go.
    _(added 2026-09-15, from `lock-verified-executive-summaries`)_

31. **Write "what can I do, and how" as job-grouped tables, not a flat endpoint
    list.**
    Four axes together: (1) group by the **job**, in the order work actually
    happens — the unit is the task someone is assigned ("onboard this carrier's
    products", "give one customer a different price"), never the API call, and
    "create a Carrier" is not a task on its own; (2) one small table per job, so
    each stays scannable and the grouping survives; (3) a column per route —
    internal tool, raw API, and implicitly neither — naming the **screen or
    command** rather than a checkmark; (4) a Note column for that row's trap.
    The `—`/`—` rows carry the most information, because they are the things
    *no* route can do, which is exactly what someone planning work needs before
    they start. Naming the screen is a verification step, not formatting: you
    cannot fill the cell without opening the tool or grepping its client, and
    that is where wrong assumptions surface — treat an unfillable cell as a
    finding. Reshaping a flat table this way on 2026-09-14 surfaced two real
    findings that had been invisible: the most dangerous endpoint was
    deliberately unreachable from the internal tool (a safety property nobody
    had written down), and a row confidently marked tool-supported was simply
    wrong. Where two flows or versions exist, call the difference out inline in
    the affected row rather than splitting into parallel tables — most rows are
    identical and duplicating them forces the reader to diff. Not for API
    reference material, where per-endpoint is the right grain, and not worth it
    for a surface small enough to hold in one table.
    _(added 2026-09-15, from `job-grouped-capability-matrix`)_

32. **Keep internal design-doc phase labels out of public-facing text.**
    Internal planning labels ("Tier A/B/C", "Phase 2", a project codename) stay
    scoped to the doc that defines them. Code comments, doc comments, UI copy,
    agent-instruction files and PR titles or descriptions are read by people
    without that doc's context — other developers, support staff, external
    reviewers — so describe the behaviour in plain language: what the feature
    does. Fine to keep the label in the design doc itself, in a commit message
    that only ever references that doc, or in planning conversation. Cleaning up
    afterwards is expensive out of proportion to the mistake: one leak on
    2026-09-14 required a multi-file pass across two repositories plus amending
    and force-pushing two already-pushed branches.
    _(added 2026-09-15, from `keep-internal-design-doc-labels-out-of-public-facing-text`)_

33. **Heading detection in markdown must skip fenced regions first.**
    Any tool treating `^#` as a heading has to track ` ``` ` and `~~~`
    open/close and ignore everything between. Dockerfiles, shell, YAML, Python
    and INI all put `#` at column 0, so this fires on most real documents
    containing code: a script lifting sections with `(?m)^#{1,3} ` ended a
    Dockerfile section at its own `# Build stage` comment and moved **8 lines
    instead of 63**. It was completely silent — the insert succeeded, the file
    parsed, headings stayed unique, fences stayed balanced — and was caught only
    because the section's line count had been measured before the move and the
    arithmetic did not reconcile. So measure the extracted size against the
    source before writing, and reconcile; truncation is invisible in the output
    and only the count shows it. Applies to heading detection specifically —
    a simple grep for content inside fenced blocks is fine. Same family as
    rendering Mermaid before committing and generating GFM anchors by script:
    markdown looks trivially parseable and is not.
    _(added 2026-09-15, from `markdown-section-extraction-must-be-fence-aware`)_

34. **A multi-file transform validates every edit before writing any of them.**
    When one logical change spans several coupled files, run it in two phases:
    resolve and validate everything in memory first — asserting each replacement
    matched exactly the expected number of times — and write only after all of
    it succeeds. A helper that updated a pack's four coupled files as it went
    threw on the fourth because a replacement did not match, leaving a bumped
    version in two files and the old version in the other two: a state the
    repo's own coherence check exists to forbid, created by the tool meant to
    maintain it. A partially-applied edit is worse than a failed one, because it
    leaves a state nobody designed and the error message points at the file that
    failed rather than at the ones that changed. This is the inverse of
    preferring per-item writes for *independent* files, where failures isolating
    is exactly the point; the deciding question is whether a consistency
    invariant spans the files or not.
    _(added 2026-09-15, from `validate-every-edit-before-writing-any-of-them`)_

## Priority

**Principle 1 outranks every other principle in this baseline, including the
other twenty-five below it** — it is not one of twenty-six equally-weighted
rules, it is the lens the rest get read through. Apply the whole baseline
whenever writing, restructuring, relocating, or reviewing documentation, but
never use it to override explicit user instructions, safety rules, privacy
boundaries, or stricter repo-local instructions — including a repo's own
more specific documentation conventions.

## Non-Goals

- This does not cover keeping documentation synced to actual code or system
  behavior — see `code-doc-sync`.
- This does not cover the lifecycle of a living, in-place-edited
  handoff/resume/plan document — see `handoff-doc-discipline`.
- This does not mandate a specific documentation tool, static-site generator,
  or file-naming scheme; it applies regardless of the toolchain.
- Principle 1's brevity default does not apply to audit trails, incident
  writeups, ADRs, or other durable decision records, where completeness is
  the priority.
