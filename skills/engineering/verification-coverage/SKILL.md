---
name: verification-coverage
description: Audit a drafted conclusion, report, review, or plan for load-bearing claims that were never actually checked — classify each as verified/inferred/assumed, run the cheap falsifying command for the unverified ones, correct what turns out wrong, and report a coverage figure. Use before delivering an output someone will act on, or when asked "how do we know this is right?", "how confident are you?", "check your claims", or "did you verify that?".
status: trial
problem: Wrong conclusions in practice are almost never reasoning errors — they are existence and absence claims asserted from partial evidence when one cheap command would have settled them. Nothing makes the difference between a checked and an unchecked claim visible in a finished output, so both read identically to the reader.
when-not-to-use: Not for ordinary conversation, exploratory thinking-out-loud, or outputs nobody will act on. Not a substitute for the `verification-epistemics` baseline, which is the always-on discipline this audit only backstops — if that pack is not installed, install it first; auditing after the fact is the weaker lever.
maintainer: Justin Choi
---

# Verification Coverage

An audit pass over a **drafted, not yet delivered** output. It does not make claims
true. It makes unverified claims *visible*, which is the part that is currently
invisible: in a finished document, a fact confirmed by running a command and a fact
assumed from a code comment look exactly the same.

## Why this targets absence claims specifically

Reviewing real sessions, the errors cluster hard. They are not bad reasoning, bad
judgment, or bad domain knowledge. They are overwhelmingly **existence and absence
claims made from having looked in one place**:

| Claim asserted | What would have falsified it |
|---|---|
| "there are no hooks in the toolkit" | `ls <toolkit>/hooks` |
| "that module doesn't exist in the repo" | `git ls-tree -r --name-only origin/main` |
| "the installed copy is missing its script" | `readlink -f` |
| "this field is handed to the downstream service" | grep the consumer |

Each cost one command. None was run before asserting.

This is a tractable target because **negative and universal claims are exactly the
ones that are mechanically falsifiable**, and the ones most likely to be made from
partial evidence — you assert a positive because you just saw the thing, but you
assert an absence because you *didn't* see it, which is a much weaker warrant.

## Procedure

### 1. Extract the load-bearing claims

A claim is load-bearing if the reader would **do something different** were it
false. Recommendations, blockers, "X causes Y", counts, and anything that gates a
decision. Skip prose, framing, and restatements of what the user already said.

Expect 5-20 in a substantial output. If you find 60, you are auditing sentences
rather than claims — re-read for what actually drives the conclusion.

### 2. Classify each one

- **Verified** — a command was run *this session* and its output supports the
  claim. Cite the command. Something you "know" is not verified.
- **Inferred** — follows from something verified, by a step you can state out loud.
- **Assumed** — neither. Includes anything taken from a code comment, a doc, a
  ticket, an earlier session, or a teammate's description.

Being assumed is not a defect. Silently *presenting* an assumed claim as settled is.

### 3. Sort by falsifiability, not by importance

Do the cheap falsifiable ones first, in this order:

1. **Absence / universal claims** — "no X exists", "the only", "nothing reads this",
   "always", "never", "every". Highest hit rate, lowest cost.
2. **Existence and location claims** — "X lives at Y", "this is on branch Z".
3. **Cross-boundary behaviour claims** — "A hands this to B". Verify at **B**; a
   comment at A cannot be evidence about B, and goes stale silently because nothing
   at A breaks when B changes.
4. **Quantities** — counts, versions, sizes. Cheap to re-run, easy to go stale.

### 4. Run the checks

One command per claim, aimed at *falsifying* it rather than confirming it. Search
where the thing would be if the claim were wrong: the remote tree as well as the
working tree, the sibling repo as well as the open one, the consumer as well as the
producer.

Stop when the remaining unverified claims are genuinely expensive to check — that is
a real boundary, and step 6 reports it rather than hiding it.

### 5. Correct the output

Anything the checks disproved gets fixed in the draft **before delivery**, and if it
was already stated to the user in an earlier turn, corrected explicitly rather than
quietly amended. Anything still assumed gets marked as assumed, in the text, where
the claim is made.

### 6. Report coverage

State it plainly: verified / load-bearing total, then list what remains unverified
and why.

> Verification coverage: 11/14. Unverified: iQ Hub host-side registration
> (outside this repo), whether the receipt line matters to the client (needs a
> human), the `es` locale requirement (unanswered).

**Do not report a confidence percentage.** A self-assessed confidence number from a
model is not calibrated and gives false comfort. Coverage is different: it is
mechanically checkable by the reader, and it makes the *absence* of verification
countable rather than invisible. That is the whole value — a low coverage figure
honestly reported is a useful output; a high confidence score is not.

## Boundary

- **This is the backstop, not the discipline.** The always-on habit lives in the
  `verification-epistemics` baseline. An audit at the end catches less, later, than
  the habit catches continuously. If that pack is not installed at a tier the work
  inherits, installing it beats running this.
- **Coverage is not correctness.** A verified claim can still be verified against
  the wrong thing — checking the working tree when the question was about `main`
  produces a confidently wrong "verified".
- **Do not pad the count.** Auditing 40 trivial claims to reach a flattering ratio
  defeats the purpose. The denominator is load-bearing claims only.

## Doctrine note

Built 2026-09-09. Per `process-vs-work-doctrine` rule 1, the underlying pain is
amply dated — 2026-08-12 (state asserted from the wrong git ref, twice in one day),
2026-09-09 (four unverified absence claims in one session), and the ~90 accumulated
bullets in `verification-epistemics` are themselves a record of the same failure
recurring. The gate is cleared.

Per rule 3 this stays a **single file** until a third real use. No scripts, no
spec directory, no supporting scaffolding — the procedure above is deliberately
runnable by hand, and it should stay that way until using it proves otherwise.
