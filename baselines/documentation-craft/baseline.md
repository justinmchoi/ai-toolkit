# Documentation Craft Baseline

Status: active
Version: 0.5.0

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

9. **Resolve every reference in a durable file to inlined content or another
   durable file's path.**
   When writing any durable file, a reference must resolve to either
   inlined content or another durable file's path — never to ephemeral
   session/conversation context ("see earlier discussion"), which becomes a
   dead pointer the moment the session ends.

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
