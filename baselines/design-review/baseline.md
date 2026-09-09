# Design Review Baseline

Status: active
Version: 0.2.0

Always-on discipline for critiquing a *design proposal* before or during
implementation — tracing whether a claimed guarantee actually holds, whether
a change silently reverses an established principle, and whether a fix or
decision has been propagated everywhere it needs to be. This is a distinct
concern from `verification-epistemics` (which is about treating an
inherited/paraphrased *factual claim* as unverified until checked against
ground truth) and from `oop-extension-safety` (which is about inheritance
extension-point bugs specifically). Design review is about the correctness
of a proposed design itself, independent of whether any code has been
written yet.

Distilled from a single intense one-shot design-feedback session (EpinServer
T&C reliability hardening) where the same reviewing move — "does this
guarantee actually hold under a second-order failure?" — recurred across
several independent findings.

## Principles

1. Before re-implementing a persistence/failure-ordering decision a second
   time, confirm the tradeoff in prose first.
   When a design decision involves an ordering/timing tradeoff across a
   persistence or transaction boundary ("must this happen before or after
   the row is saved," "does this value need to survive across an await
   gap"), and the decision is challenged a second time on the same
   underlying question after a full, passing implementation already exists,
   stop before re-implementing: write the causal sequence (call order, what
   data is available at each point, what breaks if reordered) in prose only,
   get explicit confirmation, then implement once. A repeated "why is X
   needed" about a just-shipped design is a signal the tradeoff wasn't
   explained clearly enough the first time, not a cue to immediately
   rebuild. Doesn't apply to first-pass design discussion or small tweaks
   that don't touch a persistence/failure-propagation boundary.

2. When a new proposal reverses an established design principle, name what's
   being reversed before implementing it.
   When implementing a request that structurally reverses a previously
   established, deliberate design principle — even one the person asking is
   fully entitled to change — don't comply silently. Name the specific
   principle being reversed, state the concrete new risk it reopens, and
   propose a mitigation if one exists, before or alongside implementing. The
   person may still want the reversal; the point is that the tradeoff gets
   made consciously, not smuggled in as a side effect of a request that
   didn't ask for it directly. Only worth this for a principle that was
   itself deliberate and documented, not for routine feature requests with
   no prior stated invariant to check against.

3. When a design claims to eliminate a risk "by construction," check its own
   failure mode and whether it compounds under retry.
   A design change that claims to eliminate a bug/risk "by construction"
   needs two specific second-order checks before the claim is accepted: (a)
   what happens if the mitigation/compensating action *itself* fails — does
   the original guarantee still hold, or does a nested failure reopen a
   narrower version of the same problem; (b) does the underlying risk reset
   after one attempt, or does it compound independently on every retry (a
   caller retrying N times may not just fail N times, but incur a real side
   effect N times). "The happy path is now clean" answers neither question —
   both require explicitly tracing the failure-of-the-fix and repeat-attempt
   paths. Worth this scrutiny specifically when the design involves an
   external, potentially irreversible side effect (a real third-party call,
   a real charge, a real issued resource); for purely internal/reversible
   state, a failed mitigation or a retried attempt rarely compounds into a
   real-world consequence worth the check.

4. Give each piece of state its own durability guarantee — don't apply one
   uniform persistence policy to all of it.
   When a feature involves both a reusable/shared cache (where a miss or
   staleness is tolerable, since it self-heals) and a per-operation
   authoritative record (where partial/incomplete state is never
   acceptable), decide each independently rather than giving both the same
   persistence guarantee by default: the cache can be best-effort and
   non-blocking; the authoritative record should be atomic — complete or
   absent, never partial — even if that means co-locating what would
   otherwise be two separate writes into one. Only worth the explicit split
   when the two pieces of state genuinely have different tolerance for
   staleness/incompleteness.

5. A fix found via one representation of a design must be propagated to
   every parallel representation, not just the one where it surfaced.
   When the same design/logic exists in more than one parallel
   representation (a summary and a detailed diagram, a quick-reference doc
   and a full spec, a UI mock and a data model), a correction found via one
   representation needs to be checked against every other representation
   before considering the fix done — don't assume "I fixed the one I was
   shown" is sufficient. Explicitly re-scan the other copies for the same
   class of gap. Only applies when the representations are meant to describe
   the *same* underlying design and are expected to stay consistent; doesn't
   apply when two documents deliberately diverge (a historical record vs. a
   living spec) or one is a strict subset with no room for the same gap.

6. A cancel/refund/reversal path must not unconditionally assume the forward
   action it's reversing actually happened.
   Before writing (or trusting an existing) cancel/refund/rollback/
   compensating code path, check whether it assumes the forward action it's
   reversing always fully completed. If the forward action has any
   conditional branch where it can be skipped or partially applied, the
   reversal path needs its own explicit check for whether that specific side
   effect actually happened, rather than inferring it from a coarser status
   flag ("activated," "processed") that doesn't capture the full state.
   Applies to any compensating-transaction pattern where the forward action
   has more than one possible sub-outcome; doesn't apply when the forward
   action is genuinely all-or-nothing.

7. Two structurally similar flows enforcing "the same" precondition can
   silently differ in enforcement order — trace the call order in each, not
   just whether the steps are present.
   When two or more code paths are structurally similar and each is
   supposed to enforce the same precondition ("confirm before committing,"
   "validate before publishing"), don't assume the rule holds just because
   the same steps are present in both — explicitly trace the *call order* in
   each path and compare side by side. Parallel implementations of the same
   rule can silently drift in ordering even when neither individually looks
   wrong. Worth this explicit check specifically for precondition/gating
   rules with a real consequence if skipped (billing, authorization, an
   irreversible external call).

8. A sibling method's idempotency guard (or its absence) is evidence of
   whether a method was meant to be called more than once.
   When deciding whether it's safe to call an operation a second time
   (retry, refresh, re-request), check whether it — or a structurally
   similar sibling method in the same interface/provider — has an explicit
   idempotency guard already. A sibling that has one and a target that
   doesn't is itself signal about design intent: the guarded one was built
   to tolerate repetition, the unguarded one likely wasn't. Don't treat "no
   guard exists yet" as "safe by default, just add one" — treat it as
   evidence the second call needs external confirmation before it's
   attempted at all. This is circumstantial evidence, not proof — still
   worth confirming with the actual authoritative source before relying on
   it for anything with real consequences (duplicate side effects, financial
   impact).

9. Grep every implementer and call site before judging a shape-consistency
   refactor's risk — don't reason abstractly.
   Before recommending for or against a shape-consistency refactor (widening
   a method/interface return type, adding a parameter "to match" a sibling),
   grep every implementer and call site first and let that empirical count
   drive the risk call, not intuition about how big the change feels.
   Exactly one implementer and one call site is low-risk almost by
   definition (the compiler catches every site), even when an earlier,
   less-scoped version of the same idea was correctly rejected as premature.
   Doesn't override YAGNI when the counts are actually large or unbounded —
   the empirical check is what *decides* whether YAGNI applies here, not a
   replacement for applying it.

10. Check the sibling write endpoint for the same missing-scope bug found on
    a read endpoint.
    When investigating a bug caused by a missing uniqueness/scoping
    invariant on a shared key, proactively check the corresponding
    write/update code path for the same missing invariant as a standard next
    step — don't wait to be asked. A write-side counterpart of a read-side
    ambiguity bug tends to be strictly more severe (corruption vs. a
    stale/wrong read) and is easy to overlook once the read-path finding
    feels "done." Distinct from checking both cardinality directions at a
    single call site — this is specifically about a sibling endpoint, not
    the same call site's own two paths.

11. Derive a synthetic version key from a content hash, never a timestamp.
    When a source system provides no native version/change-tracking field
    but a cache or sync pipeline needs one to detect real content changes
    and skip no-op writes, derive the version from a content hash of the
    cached value — never from a wall-clock timestamp or run identifier,
    since those always register as "changed" independent of actual content
    drift.

12. For a genuinely speculative, unbuilt design, offer labeled options with
    a tradeoff comparison instead of a single confident answer.
    When presenting a design that is genuinely speculative — nothing has
    been built yet to verify it against — offer 2-3 labeled options with an
    explicit tradeoff comparison between them, and mark exactly one as
    recommended, rather than asserting a single answer as if it were already
    validated. A lone recommendation with nothing built to check it against
    tends to get corrected repeatedly, one round at a time, as gaps surface
    one by one, instead of the real alternatives being weighed once up
    front. Doesn't apply once a design has been implemented or otherwise
    verified against reality — at that point converge on a single
    recommendation instead of re-opening options that a build has already
    settled.

13. Reordering two workflow steps to eliminate a known failure risk usually
    substitutes a new, structurally different risk — name it explicitly.
    When a proposed fix reorders two workflow steps to eliminate a known
    failure risk (e.g. moving an irreversible external call to after a
    payment completes), treat that reorder as trading one risk for a
    different one, not as eliminating risk outright. Explicitly name the new
    risk the reorder introduces and design remediation for it, verified
    against the actual system's code or state machine — not asserted from
    general principle. Don't present the reorder as simply "safer" without
    doing this trace; a reorder that isn't checked this way often just moves
    the failure mode somewhere less visible rather than removing it.

## Priority

Apply this baseline when proposing, reviewing, or implementing a design
decision — before writing the code that embodies it, and again when a
follow-up challenges an already-implemented one — but never use it to
override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions.

## Non-Goals

- This does not cover verifying an inherited factual claim against ground
  truth — see `verification-epistemics`.
- This does not cover inheritance/virtual-dispatch extension-point bugs —
  see `oop-extension-safety`.
- This does not mandate a specific design-review process, template, or
  meeting cadence; it describes what to check once a design is on the table.
