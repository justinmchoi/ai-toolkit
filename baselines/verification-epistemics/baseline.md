# Verification Epistemics Baseline

Status: active
Version: 0.13.0

Always-on discipline for a recurring failure mode: treating an inherited,
paraphrased, or confidently-stated claim as verified fact without checking it
against current ground truth. Distilled from 2026-07 sessions where this
happened via four different vectors — a stale docs branch, a domain-term
paraphrase, a code trace, and a stakeholder's ambiguous feedback — each
producing a wrong conclusion that direct verification would have caught.

## Principles

1. Re-verify an inherited claim against current ground truth before acting on
   it.
   A "confirmed" claim from a prior session, a stale architecture-docs branch,
   or a teammate's description is a starting hypothesis, not a fact — re-check
   it against the actual current code/data before using it to justify an
   action, especially when the system it describes changes quickly or the
   claim crosses a service/repo boundary.

2. Resolve ambiguous domain terms via schema, not prose.
   When two terms look interchangeable in documentation or conversation (e.g.
   two near-synonymous nouns for related-but-distinct concepts), resolve which
   is which by tracing actual entity/foreign-key structure and code, not by
   how consistently a doc uses the words. A coincidental data match (e.g. a
   legacy fixture name) is a prompt to investigate further, not evidence.

3. Use `git log -S <symbol> --all` (pickaxe) to prove "has X ever been true"
   claims.
   When a claim is about whether something has ever existed, been wired up, or
   been called anywhere in a codebase's history, prove it with a pickaxe
   search across all branches rather than inferring it from inspecting the
   current working tree alone.

4. Pair a "no mechanism found" trace conclusion with an empirical check.
   A static code trace that concludes "nothing in the code explains this
   failure" is a hypothesis, not proof — especially for intermittent or
   environment-dependent symptoms. Before presenting that conclusion as a
   verdict, pair it with an empirical re-run or reproduction attempt.

5. Re-read the original request verbatim before implementing feedback framed
   as "make A consistent with B."
   That framing is directionally ambiguous — either side could be the one
   that changes. Re-read the actual original ask before implementing,
   especially once something related has already shipped and the "obvious"
   direction might be backwards.

6. Diff every case against its prior baseline before a bulk-accept.
   Before accepting a batch of approval-test/snapshot regenerations (or any
   bulk-accept operation), diff each changed case against its previous
   baseline rather than trusting the tool's summary. Never run a repo-wide
   bulk-accept when unrelated, already-pending unreviewed artifacts are
   sitting in the same tree — it will sweep them up too.

7. Search across every locally-known repo before trusting cwd-only evidence
   for a pasted artifact or an unfamiliar file.
   When a user pastes a log line, error, stack trace, or config key with no
   stated source, grep its literal, distinctive text across every repo known
   to be checked out locally before analyzing based on the shell's current
   working directory. When an unfamiliar, tool-generated file turns up (a
   crash dump, lock file, cache artifact), check whether the same filename
   exists in other, untouched local repos before treating it as caused by
   the current session — a hit in unrelated repos points to a systemic or
   environmental cause instead.

8. Read a component's originating ticket scope before inferring its purpose
   from code structure alone.
   When a pipeline or component's name, position, or apparent behavior
   suggests a specific purpose that matters for a conclusion being reported,
   find and read its originating story/ticket's Scope, Out of Scope, or
   acceptance-criteria section — explicit scope statements are more reliable
   than structural inference, since code can legitimately look like it does
   more than it was ever asked to do.

9. Decompile a closed-source dependency's shipped assembly before asserting
   whether it supports a specific capability.
   When a design decision depends on whether a compiled package emits a
   signal, calls a callback, or defaults a value, and the docs are silent or
   ambiguous, decompile the actual shipped assembly (e.g. `ilspycmd`) rather
   than inferring from framework conventions or a similar library's
   behavior. Decompiling answers what a method's own logic does, not which
   runtime instances get shared across component boundaries — verify
   cross-component wiring by running the code, not by reading further
   decompiled output.

10. Do a deliberate side-by-side DRY pass after writing near-duplicate
    wiring for two or more similar call sites.
    After writing wiring, configuration, or registration code for two or
    more structurally similar call sites in the same task, before calling
    the task done, compare the new blocks side by side for duplication worth
    extracting — each block reads as correct and self-contained in
    isolation at write-time, so the duplication is only obvious once
    compared directly.

11. Trace where a "local" or "dev" environment config actually resolves its
    secrets before running anything that writes data through it.
    An environment named `local` or `dev` is not necessarily isolated — grep
    the startup/config-provider chain to see whether it bottoms out in
    hardcoded local values or a real, shared cloud secret store. If it
    resolves to a real shared resource, say so explicitly and get
    confirmation before running any operation that writes data through it.

12. Trust runtime evidence over code-only inference when they conflict, then
    widen the code search to cross-cutting layers.
    When a user or existing evidence (trace screenshots, logs) contradicts a
    conclusion reached by reading handler-level code, treat the runtime
    evidence as authoritative and widen the search to middleware,
    interceptors, base classes, or compiled dependencies with no local
    source — a grep of only the repo's own source can miss both
    cross-cutting registration code and anything shipped as a compiled
    package.

13. Give a subagent dispatched for read-only investigation explicit
    destructive-command restrictions or worktree isolation, not prose
    framing alone.
    Before dispatching a subagent for investigation intended to be
    side-effect-free, check what tools its agent type actually grants — an
    agent type that excludes Edit/Write can still retain Bash. Either
    enumerate forbidden command patterns in the prompt (no `rm`, `mv`,
    `git add/commit/push/reset`, no file writes) or run it with
    `isolation: "worktree"` when an accidental mutation would matter.

14. Verify who wrote a code comment or doc before citing it as evidence to a
    third party.
    Before citing a comment, migration note, or doc as justification for a
    claim to someone with no context on its origin, check its authorship
    (`git blame` / `git log -1`). If the author is the same person making
    the current argument, present it only as the current proposal, never as
    an independently validated constraint.

15. Confirm a config file is actually git-tracked before repurposing it to
    point at a remote or shared environment.
    A filename convention like `.local.` is not a reliable signal of
    git-ignored status — run `git check-ignore -v <file>` or
    `git log -- <file>` before editing a config file to temporarily hold a
    real connection string, secret, or hostname, and plan the revert step
    before making the edit, not after.

16. Verify behavior that only emerges from several real components wired
    together with a throwaway harness on the real production wiring.
    When a behavior can't be proven by any single component's unit tests,
    build a disposable harness that wires everything together exactly as
    production does, substituting only the one component that can't be
    safely or deterministically exercised (an external system, a
    production-only destination). This proves composition, not just
    isolated correctness, and can also disprove an already-agreed plan
    before any production code is written.

17. Run `git remote -v` before choosing which PR or issue-tracking tool to
    query for a repo.
    Don't infer a repo's hosting platform from adjacent context (a
    company's other tooling, a pipeline name, prior session memory) — a
    repo's source and PRs can live on one platform while its CI pipelines
    or work items live on another. Check each repo's remote individually
    when a task spans multiple repos, since siblings in the same
    initiative can differ.

18. Cross-check an issue tracker's status field against actual git merge
    history before reporting status.
    A ticket's tracked state (e.g. "In Test," "Ready") can lag a real merge
    because updating it is a manual step nobody remembers — grep the repo's
    merge-commit history for the ticket ID before reporting status. If
    tracker and code disagree, state both explicitly rather than treating
    the tracker as automatically authoritative.

19. Check the opposite cardinality direction before closing a single-result
    assumption bug.
    When a `.First()`, `.Single()`, or indexing assumption is found broken
    because a call site unexpectedly hit zero or multiple results in one
    direction, explicitly check whether the opposite direction (e.g.
    many-to-one vs. one-to-many) is also reachable at the same call site
    before considering the bug fully diagnosed — fixing only the observed
    direction can leave the mirror-image failure live.

20. Treat a check-in-style confirmation question as a prompt to genuinely
    re-verify, not a request to recap the last action.
    When asked a check-in-style confirmation question ("is X up to date?",
    "did we handle Y properly?"), treat it as a prompt to actually re-verify
    the relevant area against current ground truth, not just to confirm the
    most recent single action taken — the asker is usually probing for
    drift or gaps, not asking for a recap.

21. Confirm which open question a piece of untargeted evidence answers
    before citing it as confirmation.
    When evidence (a screenshot, log, or error text) arrives with no stated
    target and more than one question is genuinely open, confirm which
    specific question it answers before asserting it confirms any
    particular claim — evidence that settles one open question can be
    silently misapplied to a different one it says nothing about.

22. Break a stalled qualitative trade-off debate by finding one concrete,
    verifiable fact.
    When a qualitative architecture or design trade-off debate loops more
    than a round or two without converging, stop arguing the abstract
    merits and go find one concrete, directly verifiable fact (a benchmark,
    a spec detail, existing precedent in the codebase) that could reframe
    the question — a stalled debate is often a missing fact wearing the
    costume of a values disagreement.

23. Triangulate a high-blast-radius claim across independent channels
    before treating it as confirmed.
    When a broad, high-blast-radius claim rests on a single piece of
    confirming evidence, triangulate independently across multiple
    channels (code, cross-repo/history search, team chat) before treating
    it as confirmed, scaling the amount of triangulation to the claim's
    stakes — one source agreeing with itself is not independent
    confirmation.

24. Verify the exact operation against the authoritative primary spec, not
    just that some test or summary exercises "an" operation.
    A working test artifact or a confident secondary summary that
    exercises *an* operation is not evidence it's the *specific correct*
    operation for a stated question — verify against the authoritative
    primary spec by exact name/verb match before concluding the right
    operation was used.

25. Verify a governance/compliance requirement's literal trigger condition
    before raising it as a blocker.
    Before raising a documented governance or compliance requirement as a
    blocker on a newly built mechanism, verify its literal trigger
    condition rather than generalizing from its apparent intent — a rule's
    spirit can sound broader than the specific condition that actually
    activates it.

26. Check every hop of a multi-repo/multi-deployable integration
    independently before declaring a fix complete.
    When verifying whether a value survives a multi-hop integration
    spanning several repos or deployables, check every hop independently —
    not just the first one found broken — before concluding the fix is
    complete, since a value can silently drop or get overwritten at a later
    hop even after the first break is patched.

27. Verify server-side that a scaffolded form field actually flows through
    before presenting it as editable.
    Before presenting a field as editable in a scaffolded create/update
    form, verify server-side that it actually flows through unmodified
    rather than being silently overridden or derived — a form control
    rendering and submitting successfully is not proof the backend honors
    the value it carries.

28. Decompose a multi-layer call chain into layers when verifying an
    edge-case input is safe.
    When verifying an edge-case input is safe across a multi-layer or
    multi-service call chain, decompose the chain into its individual
    layers and check each one for named, concrete risk patterns (injection,
    overflow, encoding mismatch) rather than reasoning generally that the
    input is "naturally safe" — safety at one layer doesn't imply safety at
    the next.

29. Verify a vendor's own definition directly when an internal construct's
    name resembles their spec term.
    When an internal construct's name resembles a term used in an external
    vendor's own specification, verify the vendor's actual definition
    directly from their primary-source document rather than assuming
    shared meaning from name similarity — the same word can mean
    structurally different things across an internal codebase and a
    vendor's spec.

30. Rule out a stale credential before granting new permissions on the
    first auth failure after a routing change.
    On the first auth failure immediately following a credential-routing
    change, rule out a stale pre-change token or credential still cached
    somewhere in the chain before granting new permissions — the fastest
    fix for a routing change's first failure is often clearing stale state,
    not widening access.

31. Code archaeology escalation ladder: search the org wiki for GUI-only
    admin mechanisms before concluding a field's purpose is unknowable.
    When current code plus retired or superseded implementations don't
    fully explain a field's or mechanism's purpose, search the org's
    internal wiki for GUI-only admin/setup mechanisms (settings configured
    through an admin panel with no corresponding code) before concluding
    the answer is unknowable — this is the last rung of the code-archaeology
    ladder, after current code and history, not a first resort.

32. Search existing notes for prior coverage before finalizing output built
    from fresh research.
    Before finalizing any output built from fresh research (a new note, a
    conclusion, a recommendation), search the relevant existing notes or
    vault areas for prior coverage of the same specific question — fresh
    research that duplicates or silently contradicts an existing note is a
    gap worth catching before publishing, not after.

33. Load and apply a stored feedback/mistake memory before an action known
    to have one, not as a post-hoc check.
    Before performing an action type known to have a stored feedback or
    mistake memory associated with it, load and apply that memory
    proactively before taking the action, not as a post-hoc check
    afterward — checking after the fact catches the mistake only once it
    has already been made again.

34. Run a parameterized, re-run-until-zero-new-hits sweep when clearing a
    whole surface, not a single ad hoc pass.
    One ad hoc pass or grep is not proof of completeness when sweeping a
    whole surface for remaining references or artifacts (removing a
    deprecated subsystem, finding all stranded commits across remote
    branches) — run a parameterized sweep across the full surface and
    re-run it until it returns zero new hits, instead of treating one
    incremental ad hoc check as sufficient.

35. Immediately after fixing a bug in a specific category, deliberately
    re-review the next new code you write for that same category.
    Having just fixed one instance of a missing null check, boundary
    check, or similar category of bug doesn't make you immune to writing
    another instance of it minutes later — consciously re-review the next
    new code you write for the same category rather than assuming the fix
    itself raised your guard.

36. Use diff shape as the first signal when attributing an unexpected
    output-field change to code vs. data.
    When a field's value changes unexpectedly, check whether the diff is
    absent→present or value→value before investigating further:
    absent→present usually means a code/schema change (trace the commit
    that added the field), while value→value usually means a data/config
    change (check the record's updated/editor metadata) — this narrows
    where to look before spending time on the wrong side.

37. When credible sources conflict on a number, identify the differing
    methodology or scope before presenting a figure.
    Don't silently pick one source over another — identify the
    differing methodology or scope behind each figure first, then
    present both figures side by side with their scope labeled, so the
    reader can see why they diverge instead of receiving a single
    unexplained number.

38. Don't infer whether code is legacy or dead from its name or folder
    location alone.
    A name like `_deprecated` or a folder called `legacy/` is a hint, not
    proof — verify via git-blame recency, the config's actual default
    value, and real usages/wiring in the target environment before
    removing or disabling it.

39. To judge whether a running process or build reflects a source change,
    compare mtimes and process-start time as objective evidence.
    Compare source file mtime vs. build-artifact mtime vs. process-start
    time to determine whether a running process or build actually
    reflects a given source change, rather than guessing from a
    stale-looking screenshot or the developer's memory of when they last
    deployed.

40. Verify an enumerable identifier against the host's actual runtime
    registry, not the SDK's declared type or a reference prototype.
    For an enumerable identifier accepted by a validating host (an icon
    name, a capability flag, a widget type), check the host's actual
    runtime registry or enum rather than trusting the SDK's declared type
    or a reference prototype — the SDK type is typically an upper bound
    on what the host actually accepts, not a guarantee every listed value
    works.

41. Assess missing or substituted data's impact by the model's sensitivity
    to the specific missing segment, not by the proportion missing.
    A small percentage of missing tail or extreme values can bias tail
    statistics far more than their share of the dataset would suggest —
    judge impact by what the analysis is sensitive to, not by treating a
    low missing-data percentage as automatically low-risk.

42. Hold a half-remembered citation as a flagged, unconfirmed note until
    the original source is traced and confirmed.
    A half-remembered citation ("I recall X said...") is a
    human-sourced, non-canonical claim — never promote it into a durable
    rule or policy until you've traced it back to and confirmed the
    original source; until then it stays a flagged, unconfirmed note.

43. Treat a conveniently exonerating or preferred-conclusion root-cause
    explanation as a signal to raise the verification bar.
    When a root-cause explanation conveniently exonerates the code under
    test, or happens to match the conclusion you were hoping for, treat
    that as a reason to raise the verification bar rather than lower it —
    trace the actual execution path before dismissing the issue on the
    strength of a convenient explanation.

44. Diff two structurally similar call chains layer by layer, not just
    at the outer layers, when a feature breaks via one but not the other.
    When a feature breaks only through a new API entry point that looks
    structurally identical to an old, working one, diff the two full call
    chains (entry → dispatch → resolver) layer by layer rather than
    stopping the comparison once the outer layers look alike — the
    divergence is often deeper in the chain.

45. Enumerate every producer's actual value domain from the code before
    fixing a shared field's type based on one crashing call site.
    Before fixing a shared field's type based on the one call site that
    crashed, enumerate every producer's actual value domain directly from
    the code, and design the fix to cover the full domain rather than
    just the observed crashing case.

46. Rank competing root-cause candidates by precise timestamp correlation
    strength, not by which sounds like a familiar failure mode.
    When two root-cause candidates both fit the overall timeline, rank
    them by precise timestamp correlation strength (minutes vs. hours,
    drawn from independent sources) rather than by which one sounds more
    like a familiar technical failure mode.

47. Treat "the same input succeeds on another record" as a signal to look
    for an overwrite, not for missing reference data.
    When the same input succeeds on another record but fails on this one,
    redirect diagnosis away from "missing reference data" and toward "a
    later operation overwrote or wiped this specific record" — success
    elsewhere with identical input rules out a systemic data gap.

48. Check template or checklist compliance section-by-section against the
    literal template text, not by an overall skim.
    Compare each section of the deliverable against the literal template
    text one at a time rather than skimming the whole document for a
    general impression; a user's "please re-check" request is itself a
    signal to switch from skim to a literal, section-by-section pass.

49. After renaming or moving a source location, resolve — not just list —
    each downstream pointer to confirm the target actually exists.
    After renaming or moving a source location that others point at,
    actually resolve each downstream pointer to confirm the target
    exists, rather than just listing the pointers and confirming they
    have the correct type — a correctly typed link does not mean it
    resolves.

50. Re-check each pipeline stage's scope against the original requested
    scope, not just against the previous stage's output.
    When threading an extraction or filter's scope through a multi-stage
    pipeline, re-check each stage against the *original* requested scope
    rather than only against the previous stage's output — scope can
    silently narrow or drift from stage to stage even when each
    individual transition looks correct.

51. Search your own team's existing tickets and records before assuming a
    question requires an external party or another team.
    Before assuming a piece of information requires reaching out to an
    external party or another team, search your own team's existing
    tickets and records first — the answer may already be documented
    there.

52. Individually verify cross-cutting concerns unrelated to a migration's
    stated theme when auditing whether it's complete.
    When auditing whether a migration or rollout is complete, individually
    verify cross-cutting concerns unrelated to its stated theme (auth
    mechanism, routing, secrets) — completing the migration's named scope
    does not imply those were updated too. This also covers the sibling
    case: a downstream service 404ing for a specific tenant despite
    correct provider/integration-layer config may indicate a separate,
    independent "tenant onboarding" step — check for it as its own
    precondition rather than assuming the provider-layer config is
    incomplete.

53. Check the DNS zone for a wildcard record before treating successful
    resolution as evidence a hostname was ever used.
    A hostname resolving successfully via DNS is not evidence it was ever
    used — check the zone for a wildcard (`*.domain`) record before
    treating resolution as proof of use, and verify actual use via access
    logs or the owning team instead.

54. When a spec reads as functionally identical for two similar options
    even after a re-read, check an adopter's own documentation instead.
    When a spec's prose reads as functionally identical for two similar
    options even after a re-read, stop re-reading the spec and check
    whether an adopter's own (non-spec-author) documentation has already
    made and consistently applied a classification between them.

55. Run a closeout/retrospective review pass against a fixed multi-category
    checklist every time, not a single-direction scan.
    A closeout or retrospective review pass needs a fixed multi-category
    checklist (unclassified statements, session self-inconsistency,
    dedup-vs-existing-records) run every time, not a single-direction
    scan repeated only until someone asks "anything else?"

56. Scope a severity downgrade explicitly to the one finding it applies
    to; don't let softened tone bleed across a batch.
    When new evidence downgrades the severity of one finding in a batch of
    similarly-reported findings, scope the downgraded language explicitly
    to that one finding and state that the others retain their original
    severity — don't let softened tone bleed across the whole batch by
    default.

57. Reproduce a reported symptom directly, confirm it, fix it, then
    re-run the same reproduction — a proxy check is not a substitute.
    Before shipping a fix for a reported-but-not-directly-observed
    symptom, build a direct reproduction of the exact failure, confirm it
    shows the problem, then re-run that *same* reproduction after the fix
    — a plausible proxy check on an adjacent code path is not a
    substitute for re-triggering the original symptom.

58. Mark illustrative numbers and team-made decisions distinctly from
    stakeholder-confirmed facts in a decision document.
    In any decision/design document meant to be read as authoritative (ADR,
    plan, ticket comment), every quantitative figure or stakeholder-attributed
    claim must be traceable to an actual source (a quote, a message link, a
    ticket field) or explicitly marked as an internal estimate/example. Never
    let a number used illustratively in conversation, or a conclusion the
    team reached on its own, drift into being stated as if a stakeholder
    confirmed or approved it.

59. When multiple verification gaps exist, name which one breaks correctness
    silently vs. which is just slow or loud.
    When more than one verification gap exists on the same piece of work,
    don't just list them flat — rank them by failure visibility: a gap that
    could break correctness *silently* (wrong data, no error, surfaces later
    as a confusing unrelated symptom) outranks one that's merely unverified
    but would fail loudly and obviously if wrong (slow, crashes, a visible
    error). Say which is which when reporting status, and close the
    silent-failure risk first if only one can be checked before shipping.
    Distinct from principle 60's reproduction discipline — this is triage
    once multiple gaps are already known, not how to close any individual
    one.

60. Re-verify a vendor/protocol behavior claim against the primary spec, not
    a local summary — and extend "primary source" to a sibling service's own
    code when the claim is about in-house behavior.
    When a decision hinges on an exact vendor/protocol behavior claim,
    re-verify against the primary source document (extract full text, search
    it directly) before writing it into an ADR or shipping code that depends
    on it — even a locally-maintained glossary written for this same project
    can be stale or paraphrased wrong. The same principle generalizes beyond
    vendor spec *documents*: when a fix depends on another in-house service's
    behavior and that service's source is available locally, read its actual
    endpoint/handler code rather than trusting a ticket description, a
    summary doc, or a plausible inference from a similar existing pattern.
    Only worth the extra step when the claim is genuinely load-bearing for a
    design/fix decision.

61. Before trusting a harness's negative result, check it exercises the real
    path, real data, and real object identity.
    Before trusting a harness's "still slow"/negative result as disproof of
    a hypothesis, explicitly check three fidelity gaps: (a) does the
    warm-up/test call route through the *same* method/layer the real code
    path consults, not a lower-level proxy that merely looks similar; (b)
    does the test use domain data (IDs, keys) that actually exists/resolves
    in the target system, not an arbitrary placeholder guaranteeing a
    permanent miss; (c) for any mock of a method whose real implementation
    returns a different object than it received (insert/update-then-refetch
    patterns), does the mock return a genuine copy, not the same reference —
    a mock that aliases the input can mask both the original bug and the
    regression test written to catch it, passing even without the fix. A
    negative result that fails any of these checks is inconclusive, not a
    rebuttal. Refines principle 4's general "pair a no-mechanism trace with
    an empirical check" with the specific fidelity checks that principle
    doesn't spell out.

62. When a planned test turns out infeasible, record the resulting coverage
    gap explicitly — don't just revert silently.
    When a planned verification/test turns out infeasible due to environment
    or shared-infra limitations, don't just revert and move on — record the
    resulting coverage gap explicitly in the design doc/ADR, along with what
    alternative evidence stands in for it. Worth doing for meaningfully-scoped
    gaps a reviewer would want visibility into; not every trivial abandoned
    experiment needs a permanent paper trail. Distinct from principle 59
    (ranking multiple already-known gaps) — this is the separate step of
    disclosing a gap at all once an attempt to close it fails.

63. Confirm a deploy actually picked up a merge with a differential endpoint
    probe, not just "merged."
    Before relying on a shared/deployed environment to validate a
    just-merged change, don't infer "deployed" from "merged." Confirm with a
    cheap differential probe — hit a route/behavior that only exists after
    the change (expect success) and one that should no longer behave the old
    way (expect failure) — especially on a shared environment other people
    also use.

64. Copy a path from the last successful listing verbatim — don't
    reconstruct it from memory for the next call.
    When constructing a file path for a follow-up operation, copy the exact
    path string from the most recent successful listing/tool result rather
    than reconstructing it from memory — a single misremembered path segment
    causes several wasted lookup attempts before the mistake surfaces. Only
    applies when a prior tool call in the same turn/session already produced
    the authoritative path.

65. Never pass `--no-build` (or any stale-output shortcut) when verifying the
    effect of a just-made source edit.
    When running a test/verification command specifically to confirm the
    effect of a just-made source edit, never pass `--no-build` or any
    flag/cache that could reuse stale output — always force a fresh build
    first, or explicitly confirm the binary's timestamp postdates the edit.
    A "passing" result from stale binaries is worse than no result, because
    it's silently wrong.

66. To justify or challenge an existing design decision, trace the specific
    call site through git → PR → ticket → team chat, not just the file's
    history.
    When asked to justify or challenge an existing design decision, trace
    the *specific call site* (via `git log -S <symbol>` to find its
    introducing commit, not just the file's history), pull that commit's PR
    description, pull the PR's linked work item for stated original intent,
    and cross-check team chat for related incident/reliability history.
    Report the original constraint and whether it still holds for the
    current use separately — a call site's own origin can be unrelated to
    why the pattern it uses exists in general. Only worth the full chain when
    historical justification is explicitly wanted (e.g. before proposing a
    redesign); skip it for routine bug fixes.

67. State a verification boundary unprompted, in the same message that
    reports success — don't wait to be asked a pointed question.
    When reporting a fix as done, explicitly state what was and wasn't
    verified in the same message, even when not asked: "confirmed X via
    tests; not confirmed: real-world Y, because Z; here's exactly what would
    confirm it." Reporting a test-pass count ("16/16 passed") is true but can
    read as full verification when it only verified a mocked or partial
    contract — surface the gap in the success message itself, not only when
    directly asked "have you confirmed this resolves the issue?"

68. Verify a source-derived architecture/mechanism understanding against the
    authoritative design-record archive before treating it as final.
    When reverse-engineering how a system or mechanism works purely from
    source code, cross-check the resulting understanding against the
    authoritative design-record archive (ADRs, design docs) before treating
    it as final — source-only reverse-engineering can get the actual
    mechanism shape wrong even when each individual code read was accurate.

69. A declared/pinned version is evidence of intent, not of live runtime
    state — verify the actual runtime/bundled version directly.
    A compile-time SDK/package pin, or a config that says a dependency
    arrived via sync (git pull, IaC apply), is evidence of intent or a
    compatibility floor, not of live runtime state. Verify the actual
    runtime/bundled version directly (e.g. check for bundling evidence with
    an embedded browser/runtime engine like WebView2, Electron, or a JVM)
    before characterizing "what version we're on."

70. Identify which repo owns a cross-repo question's subject before
    answering from whichever repo is already open.
    Before answering a question that spans multiple repos/systems, identify
    which repo actually owns the question's subject rather than answering
    from whichever repo is already open in the session — the wrong-repo
    default can miss a directly relevant, already-shipped precedent.

71. Split a multi-repo search into per-repo, per-tool calls and check exit
    codes rather than batching raw shell search chains.
    A chained multi-repo `find`/`grep` Bash command that times out
    (non-zero exit) can leave a truncated tail indistinguishable from a
    genuine "no matches" result. Split searches per repo/tool call and check
    exit codes rather than batching raw shell search chains for efficiency.

72. Two independently-existing things are not evidence they interact as
    assumed — grep the mechanism for a direct reference to the specific
    subject and check every layer's registration/scope.
    A general mechanism and a specific subject both existing doesn't mean
    they're wired together, and two independent policy/retry layers (e.g. a
    message-bus retry loop and an HTTP-client resilience policy) can each
    look complete while one silently overrides the other. Grep the
    mechanism's implementation for a direct reference to the specific
    subject, and check every layer's registration/scope, before claiming
    coverage.

73. A single derived boolean/summary signal can silently conflate distinct
    underlying causes — require a second discriminating field.
    A single derived boolean/summary signal (e.g. a "safe to retry" column
    produced by a join or correlation) can silently conflate two different
    underlying causes (genuinely-true vs. undetermined/no-match). Such
    filters need a second discriminating field before being trusted as one
    source of truth.

74. Re-fetch an externally-editable artifact's live state before answering a
    question about its current status.
    Re-fetch an externally-editable artifact's live state (an ADO/Jira
    ticket, a wiki page, a shared spec) before answering a question about
    its current status — don't trust a saved snapshot or an earlier
    summary, even one you wrote yourself, since other people can modify it
    between reads.

75. When reusing a precedent, separate what it produced from how it got
    there — the shape transfers, the procedure only if preconditions match.
    A shared proper noun (client, carrier, feature name) between two documents
    or initiatives is not evidence of architectural equivalence. But that
    narrower trigger — "is this really the same thing?" — misses the commoner
    failure, where the precedent genuinely is a sibling and the reuse still
    goes wrong. The shape it produced (files, layout, resulting configuration)
    transfers on domain similarity. The procedure (sequence, risk,
    coordination, who must be involved) transfers only if the starting
    conditions match, and starting conditions are usually invisible in the
    finished artifact. Read the precedent's own history, not its current state.
    For anything version-controlled the check takes seconds: find the commit
    that first added the path (`git log --format=%H --diff-filter=A <ref> --
    <path> | tail -1`) and read it with `git show --stat -M`. On 2026-09-11
    that one command showed a "precedent" migration had changed namespace and
    renamed its release — a recreate, not the in-place move whose procedure had
    already been copied into four documents. Sharpen which half you are
    copying; do not stop copying.
    _(added 2026-09-08; widened 2026-09-11, from `reopened-same-name-different-initiative-verify-structural-match`)_

76. Re-grep a shared ID registry immediately before allocating the next
    slot, not from an earlier grep in the same turn.
    Re-grep a shared, hand-maintained ID registry (lettered open-items, ADR
    numbers, etc.) immediately before writing the next allocation, not from
    an earlier grep in the same turn — a concurrent session can claim the
    same slot in the gap. If a collision is found after the fact, resolve
    it by keeping the occurrence with more existing references and
    renaming the other, with an explicit written note rather than a silent
    patch.

77. Before recommending batching an API call for latency, verify which cost
    actually dominates.
    Before recommending batching an API call to cut latency, verify which
    cost actually dominates by checking the callee's own loop (sequential
    vs. parallel) and whether the deepest dependency accepts multiple items
    at all — batching a shallow layer doesn't help if a deeper layer is
    still sequential.

78. Verify each diagram component's actual repo/namespace directly, and pull
    an existing artifact's literal source data before matching its
    convention.
    Before finalizing an architecture/sequence diagram, verify each
    component's actual repo/namespace directly rather than grouping it by
    assumed logical ownership, and pull an existing artifact's literal
    source data (colors, naming, formatting) before matching its convention
    from a remembered impression.

79. Lean into a narrow, rigorously-verified question snowballing into
    comprehensive understanding.
    A narrow question, verified rigorously against source rather than
    assumption, naturally snowballs into comprehensive understanding — lean
    into that: chase verified adjacent questions, delegate wide
    sub-investigations to parallel agents, and periodically distill what
    surfaces into a reusable reference rather than letting it stay
    scattered.

80. Read a shared code path's full method body before asserting
    reusability, and confirm a citation is accessible to its actual
    audience.
    When asserting a shared/generic code path is reusable, read the full
    method body end-to-end — a verified guard clause is not the same as a
    verified method body. And when citing sources in a doc for a specific
    audience, the citation must be accessible to that audience, not just
    technically present (e.g. a link only the author can open doesn't count
    as grounding for the reader).

81. Verify a cross-boundary data-flow claim at the consumer, never from the
    comment asserting it.
    A comment describing what some *other* component does with a value cannot
    be checked from where it is written, so nothing keeps it honest — the code
    beside it never breaks when the consumer changes. Grep the consumer before
    repeating the claim. One occurrence escalated a field removal to a blocking
    question for another team purely on the strength of two comments saying the
    value was handed downstream; it was never read there at all. Where a repo's
    prose and its code disagree, the code wins and the prose is a bug worth
    reporting.
    _(added 2026-09-09, from `in-repo-docs-went-stale-three-ways-in-one-module`)_
82. Re-check tool and skill availability at the point of use, not from
    conversation memory.
    A skill or tool that worked earlier in the same conversation can be gone
    later — a machine change, an environment reconfiguration, or the tool's own
    lifecycle. Across a multi-day session this has already happened. Any
    workflow that sequences sub-skills should treat "check availability first"
    as a per-run step rather than an assumption carried forward from an earlier
    turn.
    _(added 2026-09-09, from `skill-availability-can-change-mid-conversation`)_

83. Treat an error message as naming a cause, not the cause; and encode a
    batch's preconditions as per-item assertions.
    Before accepting a permission or capability error at face value, check
    whether the documented non-privileged path is already enabled — one
    occurrence read "Administrator privilege required" and concluded admin was
    needed, when Developer Mode was already on and the operation failed anyway,
    making "grant admin" both wrong and useless. If the documented path is in
    place and it still fails, look for the working alternative rather than
    escalating privilege. Separately, when applying one transform across
    several artifacts, assert its structural precondition per item inside the
    script rather than holding it as a belief — a transform validated on one
    artifact is only a hypothesis about the rest, and an assertion fails loudly
    on the one that differs instead of silently corrupting it.
    _(added 2026-09-09, from `encode-preconditions-as-assertions-not-beliefs`)_

84. Verify a checker with two controls before believing either of its
    verdicts, and expect the known-good one to catch errors in your analysis.
    A checker's false negative looks exactly like a clean result, and its false
    positive looks exactly like a real defect, so a surprising verdict is
    evidence about the checker at least as much as about the thing checked.
    Three instances in one session: a fuzzy text matcher reported a principle
    missing that was present but reworded (it keyed on the first 60
    characters); a mutation test passed because a fallback repaired the
    mutation, making a working suite look worthless; and a preset parser
    reported every entry missing because CRLF put a trailing carriage return
    inside each path, while separately mis-reading section markers.
    One control is not enough, and the two do different jobs. The known-bad
    control proves the checker can go red — cheap, reassuring, and it almost
    always confirms what you already believed. The known-good control is the
    one that interrogates your own model of what "correct" means: a FAIL there
    has three causes, and the third is why the exercise is worth doing — the
    checker is buggy, the check is over-strict for a legitimate variant, or
    your belief that this case is good is wrong. Read a green known-good run
    sceptically too: ask which specific check would have caught the defect you
    are worried about, and whether it actually ran. Report SKIP distinctly from
    PASS and never let a skip count toward a green total. If no known-good
    instance exists yet, say so — "the checker has only been shown to go red" —
    rather than implying it was validated both ways.
    _(added 2026-09-10, from three self-inflicted instances in the 2026-09-09 toolkit session; extended 2026-09-11, from `run-both-controls-the-known-good-one-catches-your-errors`)_

85. Write the completion criteria before the plan, not after the work.
    "Done" defaults to whatever produces visible output — the PR merged, the
    build green, the document shipped — and every one of those can be true
    while the deliverable does nothing. For any multi-step task someone will
    act on, write the gates first, in dependency order, numbered so they are
    citable from the plan and from a failure report. Split automated from
    manual per criterion: automated ones get a script, manual ones get the
    exact command written out so they are runnable rather than aspirational.
    SKIP is not PASS — a check that could not run must report distinctly, with
    a reason, and must not count toward a green total. Name the two or three
    criteria most likely to be skipped and say why each alone voids the work;
    that section is the one people read. Writing the gates first changes the
    plan, and it is cheap, because the gates are just the questions you would
    ask when reviewing someone else's claim of completion. Proportion it to
    consequence: a one-file fix does not need seven gates, and the loop must
    not become the deliverable.
    _(added 2026-09-11, from `define-done-as-a-gated-checklist-before-starting`)_

86. Ship a prose deliverable someone will act on with a runnable suite that
    re-asserts every load-bearing claim.
    Research, migration plans, state-of-play documents and teaching packs rest
    on perishable facts — work-item states, which files exist on a default
    branch, tool versions, whether a namespace has been migrated — and a reader
    six weeks later cannot tell which sentences are still true. Write one check
    per claim, each owning the falsifying command rather than the conclusion
    (a tree listing piped to a count returning 0, not "the docs say it isn't
    migrated"). Include the negative claims, which are the weakest thing in any
    research document and the easiest to re-check. Include self-consistency
    checks — every link resolves, every path the index names exists — which
    cost nothing and catch rot introduced by later editing. When you correct an
    error, add a check shaped to fail if the correction was itself wrong.
    Record the runs: what failed and what was done about it tells the next
    reader which claims are load-bearing enough to have broken once. Distinct
    from encoding a precondition inside the script that does the work — here
    there is no script, so the assertions ship as their own artifact or they do
    not exist at all.
    _(added 2026-09-11, from `ship-a-research-deliverable-with-an-executable-claim-suite`)_

87. Match a unique substring and assert the hit count before deleting or
    replacing lines in a structured file.
    Selecting lines by a prefix that encodes a shared attribute — a date, a
    status, a category — matches every other line carrying that attribute,
    including ones in a different table or section of the same file. Match on a
    substring unique to the target, assert the hit count is exactly one before
    writing, and bound any range scan with a hard anchor (the literal line that
    must survive) rather than a structural guess like "until the next blank
    line". Then read the diff and check the arithmetic: "removed 2, added 1"
    has an expected net change, and if the numbers do not reconcile, something
    else was caught. A silent multi-match is the failure mode; the assertion
    converts it into a stop.
    _(added 2026-09-11, from `match-unique-substring-and-assert-count-before-deleting-lines`)_

88. Verify effective state where the work happens, not where the source lives —
    including the agent's own configuration.
    "The source is current" and "it is installed at the tier I apply from" are
    two questions, and a green answer to both says nothing about the third:
    *is anything I actually work in also carrying its own older copy?* On
    2026-09-14 the top-tier evidence was clean — no drift, every pack current at
    the user tier — while a per-repo sweep found 72 duplicate-tier findings
    across 8 repos, every one a stale local copy, the worst ten minor versions
    behind. The cost was concrete: a rule published that morning to fix a real
    mistake was live at the user tier, and the superseded wording that caused
    the mistake was still in context beside it in 7 of the 8 repos where the
    work happens. Sweep per consumer after any change that matters; the failure
    is silent by construction, because both copies parse and neither tool nor
    reader flags the contradiction.
    Before removing a duplicate, separate three cases, and note that "is the
    file tracked" is not the test — check whether the *blocks* are committed:
    an untracked file is personal and safe to clean; a tracked file whose blocks
    are uncommitted is also personal but is someone's in-progress intent, so
    treat it as user-owned and ask; committed blocks are the team's only copy
    and removing them is a decision plus a review, never a local tidy.
    _(added 2026-09-14, from `applied-at-the-top-tier-is-not-applied-everywhere`)_

89. When two systems mint identifiers independently, equality of identifier
    stops being evidence of equality of thing.
    Version numbers, sequence numbers, migration ids and pack markers are all
    assumed to be comparable across sources, and they are not when each source
    increments its own counter. Two toolkits versioning the same pack name
    independently — which is the correct design, since they have different
    audiences and cadences — produced the same name at the same version number
    from two sources with **different content**, and every drift check in the
    pipeline compared version markers, so all of them reported clean. Ordinary
    staleness degrades gracefully, because the older text is usually a subset of
    the newer; equal numbers with different content is a genuine conflict and is
    the one shape a marker comparison cannot see. Compare content — hash or diff
    the two — whenever the same identifier can be minted by more than one source,
    and report a two-source disagreement as a conflict rather than as
    redundancy. The fix is content-based comparison, never coordinating the
    counters, which would couple systems that were separated deliberately.
    _(added 2026-09-14, from `independent-versioning-of-a-shared-pack-name-defeats-version-based-drift-detection`)_

90. Names are hypotheses; trace the runtime path to answer "which value is
    actually used".
    For any "which value, path or config is actually used at runtime" question,
    trace the execution path end to end and cite each hop — the query or stored
    procedure, then the data mapping, then the service that consumes it. Names,
    types, doc comments and table structure are hypotheses, not evidence, and
    the mapping hop is where the lie lives: `X = GetValue("Y")` silently renames
    a column, and every downstream reader then believes `X`. On 2026-09-14 a
    property named `VendorPrice` was fed from a different table's
    `DefaultVendorPrice` column while a real `VendorPrice` column sat unread
    nearby — every name pointed away from the truth, because the system had been
    rewritten and not renamed, so the old names described the old behaviour and
    still compiled. Reserve the full trace for values that decide money,
    routing, permissions or anything irreversible, and specifically when a claim
    is about to be written down: the wrong answer here had already propagated
    into four artifacts across two repos, including the repo's own agent
    instruction file, where being written down had made it harder to question
    rather than easier. Once an inversion is found, grep every doc, comment and
    diagram for the old claim rather than fixing the one instance, and mark the
    correction with a dated "previously said X, which described the legacy path"
    block instead of editing silently.
    _(added 2026-09-15, from `trace-the-runtime-path-not-the-entity-names`)_

91. A probe that agrees with itself is not evidence.
    Three shapes of one fault. A comparison returning the **same verdict on both
    sides of a pair you know to differ** — or "absent everywhere" for something
    you know exists — is almost always a broken matcher rather than a shared
    absence: `grep -ciE "a\|b"` matches a literal pipe, reports zero hits in
    both files, and reads as a finding. A generated artifact **round-tripped
    through the library that wrote it** proves only that the library agrees with
    itself; its reader is tolerant of exactly the malformed shape its writer
    produced, so a `.xlsx` that passed its own writer's reader was still
    rejected by the target application, and the cause was only found with an
    independent reader and raw-XML inspection. And a checker built from the same
    assumption as the thing it checks cannot see that assumption. Cheap guard
    for a one-off query: include one row whose answer you already know and
    confirm the probe reproduces it before reading any other row. Escalate to
    genuinely independent verification whenever the consumer is a third-party
    application with its own, possibly stricter, parser.
    _(added 2026-09-15, from `a-probe-matching-both-sides-is-evidence-about-the-probe`
    and `independent-verification-for-generated-files-not-same-library-roundtrip`)_

92. Validate a structured block with the format's real parser, never a presence
    regex.
    A regex confirming a required key appears proves those characters are
    present; it cannot distinguish "valid" from "so malformed nothing can read
    it", and both come back green. One unquoted `key: value` inside a YAML
    frontmatter value invalidates the **whole block** — name, description, scope
    and maintainer all unreadable, the file matching on its filename alone — and
    two independent checks (a CI workflow and a local drift checker) both passed
    it because both confirmed the key by regex. A presence regex is fine as a
    cheap *first* gate before an expensive parse; the defect is regex *instead
    of* parse. When one bad file surfaces this way, the check that could not see
    it is the larger finding.
    _(added 2026-09-15, from `validator-that-checks-a-key-exists-instead-of-parsing`)_

93. Isolate pre-existing failures before calling anything a regression.
    `git stash` the change and re-run the same failing suite against the
    unmodified base branch, and confirm whether the failure already existed
    there, rather than debugging it or explaining it away. Only after that is it
    honest to report "green except for N known pre-existing failures" — on
    2026-09-14 the same twelve failures reproduced on clean `main` and were an
    unrelated test-database provisioning issue. This is the known-good control
    applied to a test run. Skip it when the stack trace obviously implicates
    code you just added; it earns its cost when the failure's connection to the
    change is genuinely unclear.
    _(added 2026-09-15, from `isolate-pre-existing-failures-via-git-stash-before-regression`)_

94. Prove the survivor is a superset before deleting a duplicate copy — and
    compare symbols, not headings.
    Run the proof at the **finest** granularity from the start: diff the set of
    distinctive symbols (backticked identifiers, paths, URLs) between the
    copies, not their section headings. Heading equivalence is not block
    equivalence is not content equivalence, and each coarser method returns a
    confident, wrong "already covered" for exactly the items the finer one
    catches. Consolidating four copies of one scaffolding template took three
    passes: heading comparison missed a whole service, because its heading sat
    under a numbered phase and the target already had a same-named section;
    normalised-code-block comparison then missed a set of deploy targets,
    because those were prose bullets rather than fenced blocks. Neither copy was
    a superset of the other, so deleting in either direction would have lost
    real content. Classify each gap before acting: a **new concept** must be
    ported, an **older variant of something already present** can be dropped,
    and conflating the two either loses content or bloats the survivor with
    superseded duplicates. Not needed where one copy is mechanically generated
    from the other — there, regenerate and compare output.
    _(added 2026-09-15, from `prove-superset-before-deleting-a-duplicate-copy`)_

95. A checker that cannot express a legitimate exception will be ignored rather
    than fixed.
    That is a property of the checker, not of the person ignoring it. When a
    known-good state is reported as an error — a deliberate cross-source
    override, an intentionally foreign-owned entry, a documented deviation — the
    noise trains its reader to skip the whole channel, and the next real
    breakage goes unnoticed with it. Three dead symlinks into a deleted
    repository survived an unknown period behind exactly this kind of noise.
    Give the checker a way to record the intent (an override list it consults,
    or provenance written beside the artifact), or teach it to infer the
    exception from something observable — a link that resolves to a real target
    outside this repo is an ownership decision, while a link that resolves to
    nothing is still damage. The same applies to any repair tool: one that
    cannot tell damage from a deliberate choice silently reverts the choice, and
    nothing warns you.
    _(added 2026-09-15, from `shared-install-tier-cannot-express-a-deliberate-cross-toolkit-override`)_

96. In a layered permission system, check every scope and the data-plane auth
    mode before concluding access is missing.
    A negative at one scope is not a negative overall: check role assignments at
    the resource, the resource group and the subscription, and through
    transitive or nested group membership, before concluding an external request
    is required. A first-pass check that looked only at the exact resource-group
    scope for a direct assignment reported "you don't have this access either",
    when subscription-level assignments reached via nested group membership
    already covered most of what was needed. Separately, check **which
    authorization mode governs the resource's data plane** before proposing an
    alternate grant: several resource types carry mutually exclusive legacy and
    modern auth modes — access policies vs. role-based access, account keys vs.
    directory identity — where the wrong one is accepted at write time and
    silently inert at read time. The grant looks applied, the identity still
    cannot read, and the failure surfaces later as a crash loop rather than as
    an error on the grant itself.
    _(added 2026-09-15, from `check-access-at-every-scope-including-nested-groups`
    and `azure-dual-authorization-mode-check-before-alternate-grant-path`)_

97. When work runs unattended, write the gates before the work and re-run them
    as commands at the end.
    The distinguishing feature is not length — it is that the normal
    error-correction channel is closed, so a wrong assumption at hour one
    silently shapes everything through hour four and is first reviewed after all
    of it is on disk. Convert every question you would have asked into a gate
    written down before starting. Record each decision as an assumption *with
    the command that would falsify it*, never the assumption alone: an
    assumption with a check attached fails loudly at the gate, an assumption
    alone fails silently and reads as a completed step. Order the work
    reversible-first, so anything that cannot be undone (a push, a merge, a
    delete) happens after everything that can, and stop at an irreversible step
    whose precondition will not verify rather than guessing through it. Re-run
    every gate as a command at the end and report its real output — a gate
    checked at hour one and reported at hour four is a memory, not a
    verification. Report a `SKIP` as a skip with its reason; folding one into a
    pass is the dominant unattended failure. Lead the final report with the
    residual questions and the assumption taken for each, so the owner's first
    read is a diff against intent rather than a reconstruction. None of this
    licenses proceeding through a genuinely unsafe ambiguity, and where
    authorisation was given conditionally ("merge it after verifying your own
    changes"), the gate *is* the condition — run it and report it.
    _(added 2026-09-15, from `verification-gate-for-unattended-autonomous-runs`)_

98. A checker scoped to one source cannot certify a consumer fed by several,
    and more generally a check that *cannot* fail is not a check.
    A clean result means "nothing I was able to look for is wrong", which is a
    far weaker claim than it reads as — and the output format is identical
    either way. Three shapes of the same defect, all on 2026-09-15: a drift
    checker that enumerates its own toolkit's `baselines/` reported clean while
    nine duplicated blocks owned by a *second* toolkit sat in the same three
    files at the same tier, because they were never candidates; `git log --all
    --not origin/main | grep <bad value>` was quoted as "every branch is clean"
    when `--not origin/main` excludes `origin/main` by construction, and the
    one bad commit was on `main`; and a propagation sweep that reads each
    project's `CLAUDE.md` reported one project needing work while every
    `AGENTS.md` and `.github/copilot-instructions.md` in the same tree sat at
    the oldest version present, having survived every prior sweep for the same
    reason. None of the three commands was wrong; each answered a narrower
    question than the one being asked of it, and each reported a *number*,
    which is arithmetic over an incomplete domain. So: name the region the
    claim covers, then read the command back and ask whether that region is
    inside what it scanned — if a flag, an ignore file or a path filter removes
    it, the command is answering a different question. Prefer an audit whose
    scope is defined by what is being checked rather than by what the checker
    knows about: enumerate the consumer's own inventory (every `BEGIN` marker
    in every instruction file) and account for each entry, which is
    source-agnostic by construction. Run every source's checker, not just the
    one whose repo you are standing in, and say whose checker produced a
    number. The degenerate case is worth naming separately: a query against a
    target that does not exist can report healthy inheritance and zero local
    state, which is byte-for-byte what a correct result looks like — assert the
    target exists first, and prefer a check that fails *differently* for
    "correct" and "absent".
    _(added 2026-09-15, from
    `a-per-source-checker-reports-clean-on-another-sources-content` and the
    verification half of `powershell-variable-names-are-case-insensitive`)_

99. Call a tool's own validators to build or check data for it, instead of
    reimplementing its schema from the documentation.
    When a write format is validated by the tool's own code rather than merely
    described in its docs, and that code is installed and importable locally,
    construct and verify through the real functions — especially for any field
    computed by a hash or other exact algorithm, where a transcribed
    implementation fails silently and byte-wise. Cheap, and it removes the
    whole transcription-error class. Only applies when the implementation is
    actually available locally; for a pure network API with no local library,
    the schema docs are all there is.
    _(added 2026-09-15, from
    `use-tool-native-validators-not-schema-transcription`)_

100. Read a third-party tool's actual source before installing it, in
     proportion to what it is allowed to touch.
     For anything that gets write access to real data or executes with real
     permissions — an agent plugin, a skill bundle, a hook — read the source
     for every network call site, how secrets are sourced, what write-safety
     model it uses (atomic? rollback? create-only?), and whether it has any
     explicit handling for untrusted input. A polished PRIVACY.md or
     SECURITY.md is a claim, not evidence; on the occasion this was written
     from, the claims all checked out, and the checking is what earned the
     trust. Scales with blast radius — a read-only utility holding no secrets
     does not need it.
     _(added 2026-09-15, from `vet-third-party-ai-tool-source-before-install`)_

## Priority

Apply this baseline before presenting a conclusion, a fix, or a summary of
"what's true here," but never use it to override explicit user instructions,
safety rules, privacy boundaries, or stricter repo-local instructions.

## Non-Goals

- This does not require re-verifying every trivial or already-directly-observed
  fact — it applies when a claim is inherited, paraphrased, or crosses a trust
  boundary (prior session, stale doc, another person's description).
- This does not replace domain-specific investigation techniques; it's the
  general discipline underneath them.

## Editorial note

This baseline has grown very large (97 principles as of 2026-09-15, up from
89 on 2026-09-14, 80 on 2026-09-08, 67 on 2026-09-01) across several
consolidation passes. It likely needs a structural consolidation pass —
grouping principles into sub-categories and merging near-duplicates — before
further additions. Flagging this for a future maintainer; not acted on here.

The always-on cost is bounded separately: only `adapters/CLAUDE.md.core.block`
is installed, and it is held at 13 principles. Growth in this file is growth in
a reference nobody loads mid-task, which is the trade the core/full split makes
deliberately — so a genuinely load-bearing new principle belongs in core, and
something else has to come out. On 2026-09-15 core stayed at 13 by merging the
absence-claims and negative-result principles into one and extending two others
in place.
