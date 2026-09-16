# Commit Conventions Baseline

Status: active
Version: 0.3.0

This is a tool-neutral always-on baseline for AI coding agents that write
commits in a repository. It sets the *format* of the commit message: every
commit follows the [Conventional Commits](https://www.conventionalcommits.org/)
specification, with an imperative subject, a body that explains the "why," and
machine-readable footers for tracking references.

It is intentionally generic so it applies to work and personal repositories
alike. Conventional Commits is a public standard, so nothing here is
project-specific; the footer examples simply cover both GitHub issues and Azure
DevOps work items.

## Format

    <type>(<optional scope>): <description>

    [optional body]

    [optional footer(s)]

## Allowed types

- `feat` — a new feature
- `fix` — a bug fix
- `docs` — documentation only
- `style` — formatting, whitespace, no logic change
- `refactor` — a code restructure that is neither a fix nor a feature
- `test` — adding or correcting tests
- `chore` — build process, tooling, or dependency updates
- `ci` — CI/CD configuration changes

## Rules

1. Use present-tense imperative mood.
   "add feature", not "added feature" or "adds feature".

2. Keep the subject line to 72 characters or fewer.
   No trailing period. Scope is optional but encouraged in larger codebases.

3. Explain the why in the body.
   When the change is not self-evident, add a body after one blank line and
   wrap prose at roughly 72 columns. Describe intent and consequences, not a
   restatement of the diff.

4. Reference tracking items in the footer — when the commit delivers them.
   `Closes #123` for a GitHub issue, `AB#12345` for an Azure DevOps work item.
   That syntax is **an action, not a reference**: where the tracker has a
   commit/PR integration, it writes a link and changes what the work item
   appears to have delivered. Use it only when this change delivers that item's
   scope. When naming a work item as *provenance, evidence or background* —
   "this rule came from what we learned on X", "the precedent is Y" — drop the
   sigil (`AB 378454`, or "work item 378454") so the integration does not match
   it. Do not rely on backticks or code fences to suppress it; these
   integrations scan raw message text.
   Every linking surface links independently — commit message, PR/MR title, PR
   description, branch name — so removing the ID from one leaves the others
   attached. Once a commit message is pushed the only fixes are a history
   rewrite or unlinking in the tracker's UI, which makes *before the first push*
   the cheap moment. File content is safe and is the better home for provenance:
   an id inside a committed source or doc file does not auto-link.
   _(added 2026-09-14, from `tracker-autolink-syntax-is-a-write-not-a-citation`)_

5. Where the repo's platform has its own subject convention, compose rather
   than choose - and say which yields if they cannot.
   The format above is this baseline's default, not a universal. A
   tracker-integrated platform often wants its work-item sigil leading the
   subject, so that the squash-merge commit built from the PR title carries
   the link; a repo can also have an established house style that is neither.
   These compose more often than they conflict: `<REF>: <type>(<scope>):
   <description>` satisfies both, and on the repos checked on 2026-09-15 it is
   what the best-received recent merges actually use, alongside plenty of
   bare-Conventional and bare-sigil subjects. Read the repo's recent merged
   subjects before picking a form rather than applying either rule blind. Where
   they genuinely cannot compose, the repo's live convention wins and this
   baseline yields. Note the interaction with rule 4: a sigil in the subject
   *is* the tracker link, so it carries the same "only when the commit delivers
   that item" constraint, and a provenance-only reference still has to drop it.
   _(added 2026-09-15, from the portable half of
   `abandoned-branch-holds-uncovered-ado-pr-conventions`; the company-specific
   literal form belongs in a company toolkit, not here)_

6. Flag breaking changes explicitly.
   Append `!` after the type/scope (`feat(api)!: ...`) or add a
   `BREAKING CHANGE:` footer describing the break.

## Examples

    feat(auth): add OAuth2 login support
    fix(api): handle null response from upstream service
    docs: update README with setup instructions
    chore(deps): bump typescript from 5.3 to 5.4
    refactor(orders)!: remove deprecated pricing export

    BREAKING CHANGE: LegacyPricing is no longer exported; use PricingV2.

## Priority

This baseline takes precedence over ordinary commit habits, but never use it to
override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions. If a repository already defines and follows
its own commit convention, follow that instead.

## Non-Goals

- This governs message *format* only. It composes with, and does not replace,
  the `git-collaboration-hygiene` baseline (stage explicit paths, review the
  staged diff, keep remote operations consent-based) and the
  `commit-attribution` baseline (no AI co-author trailers or "generated with"
  footers).
- This does not govern branch naming (see the `branch-naming` baseline), PR
  descriptions (see the `pr-description` baseline), changelogs, release notes,
  or versioning policy.
- This does not require or forbid any specific commit-linting tooling; it
  describes the message the agent should write.
