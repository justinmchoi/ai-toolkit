---
name: staff-level-review
description: Read-only engineering review with a fixed findings/verdict output contract. Use when the review needs that contract, a review context bundle, or a non-GitHub diff source (e.g. Azure DevOps, a patch file, a bounded set of repos and docs). For routine review of a local diff or GitHub PR, prefer the built-in /code-review or /review instead.
maintainer: justin.choi
status: stable
---

# Staff-Level Review

Use this as a read-only engineering review checkpoint. Produce findings and a
verdict; do not edit files, push changes, or post PR comments unless the user
explicitly switches to a separate review-fix or posting workflow.

If `docs/specs/0004-staff-level-review.md` exists in the current repo, it is
the fuller definition and takes precedence. If it does not exist, this file is
self-contained — do not go looking for the spec elsewhere.

## Inputs

Review any bounded diff source:

- PR number, URL, branch, or local diff
- provided patch or diff file
- review context bundle
- changed files plus related docs, ADRs, CONTEXT files, and CI/test signals

If the diff source is ambiguous, ask before reviewing.

## Preflight

Before reviewing, decide whether to proceed:

```text
proceed: yes | no | needs-info
reason:
required_context:
suggested_next_action:
```

Stop instead of forcing a low-confidence review when the PR is closed/merged,
the diff is too large, requirements are missing, context is insufficient, or
extra repositories are needed but not approved.

## Review Scope

Review for high-signal issues across:

- correctness and regressions
- architecture and responsibility boundaries
- security and privacy
- performance and unbounded work
- test quality and missing behavior coverage
- maintainability and naming
- API/interface design
- breaking changes and migration risk
- operability, rollout, observability, and rollback
- requirement compliance

Apply a false-positive filter before reporting: skip issues that are
pre-existing, covered elsewhere, already verified by tests/CI, intentionally
documented, or merely preference without a clear better alternative.

## Test Policy

Do not run broad build or test commands by default.

Allowed by default:

- read CI status or provided test output
- read relevant tests
- reason about missing coverage

Run targeted tests, typecheck, or lint only when the command is known, scoped,
and allowed by the user or calling workflow.

## Severity And Verdict

Use this severity vocabulary:

- `BLOCKING`: must be fixed before merge
- `SUGGESTION`: important improvement worth discussing
- `QUESTION`: intent is unclear and blocks review confidence
- `NIT`: minor issue that should not block merge

Verdict is driven by findings:

- `Request changes`: at least one `BLOCKING`
- `Needs clarification`: confidence-blocking `QUESTION`
- `Approve with suggestions`: no `BLOCKING`, but meaningful suggestions
- `Approve`: no blocking or confidence-blocking findings

## Output Format

Findings come first. If there are no findings, say so explicitly. Specific,
evidence-backed positives may appear only after findings.

```markdown
# Staff-Level Review

## Findings

[BLOCKING] Short title

- Issue:
- Why it matters:
- Evidence:
- Recommendation:
- Location:

[SUGGESTION] Short title

- Issue:
- Why it matters:
- Evidence:
- Recommendation:
- Location:

[QUESTION] Short title

- Question:
- Why it matters:
- Evidence:
- What would resolve it:
- Location:

[NIT] Short title

- Issue:
- Recommendation:
- Location:

## Verdict

Approve | Approve with suggestions | Request changes | Needs clarification

## Summary

...

## What's Working Well

- ...

## Verification

- Diff source:
- Context inspected:
- Commands run:
- Checks reviewed:
- Not run:

## Review Constraints

- Read-only:
- Extra repos:
- Disallowed paths:
- Sensitivity:
```

## External References

External or legacy `staff-review` material may be used as reference only after
source and license verification. Do not import external material into this repo
unless it has been grilled against `docs/specs/0004-staff-level-review.md` and
the required source registry / notices are updated.
