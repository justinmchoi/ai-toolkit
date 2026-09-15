# PR Description Baseline

Status: active
Version: 0.5.0

This is a tool-neutral always-on baseline for AI coding agents that open pull
requests in a repository. It sets the *content* of the PR: a title a reviewer
can scan, and a body that answers what changed, why, how it was verified, and
what the risk is — so review starts from context instead of a blank diff.

It governs the human-facing PR body, not the commit message. It shares the
[Conventional Commits](https://www.conventionalcommits.org/) title form with the
`commit-conventions` baseline (many repositories squash-merge, so the PR title
becomes the commit subject). It is kept generic so it applies to work and
personal repositories alike.

## Defer to the repository's template first

If the repository provides a PR template — `.github/PULL_REQUEST_TEMPLATE.md`,
a file under `.github/PULL_REQUEST_TEMPLATE/`, `docs/`, or the Azure DevOps
equivalent — **fill that template out** rather than replacing it with the
structure below. The template is the repo-local instruction and wins. Use the
structure here only when no template exists, and to decide what to write in a
template's freeform sections.

## Title

Write the PR title in Conventional Commits form, exactly as a commit subject:

    <type>(<optional scope>): <description>

Present-tense imperative, 72 characters or fewer, no trailing period. This keeps
the title meaningful after a squash-merge. See the `commit-conventions`
baseline for the type vocabulary.

## Body structure

When there is no template, cover these in order. Keep each section short; omit a
section only when it genuinely does not apply.

1. **Summary** — what changed, in one to three sentences. Describe behavior and
   intent, not a file-by-file restatement of the diff.
2. **Why** — the **business problem, before any technical detail**: the request
   in a real person's words, with any domain noun it leans on defined in one
   clause. "Also sell this existing pin through the dealer price list" motivates
   a change; "there was no endpoint for it" restates the diff. Follow it with
   the job the change enables — the workaround it replaces, ideally as a
   before/after table — then only the constraints that actually shaped the
   design, and what the change deliberately refuses and why refusing beats
   guessing. The test is not whether the description is accurate but **whether
   the author can explain the change to someone else from the description
   alone**: on 2026-09-14 an accurate, entirely technical description left its
   own author saying "even myself after reading it, I cannot understand and
   explain it to others", and re-opening with the support request it answers
   fixed it. The business-problem opener earns its place when the PR adds or
   changes a *capability* — a new endpoint, a new screen, a changed workflow;
   pure refactors, dependency bumps and build fixes have no business problem,
   and inventing one is worse than omitting it.
   _(added 2026-09-15, from `pr-description-opens-with-the-business-problem`)_
3. **Testing** — how the change was verified: commands run, cases covered,
   manual steps, screenshots for UI. Say plainly if something was not tested.
4. **Risk / rollback** — blast radius, migrations or config changes, feature
   flags, and how to revert if needed. Omit only for genuinely low-risk changes.

## Rules

1. Reference tracking items and related PRs with the platform's own syntax.
   - **Work item / issue:** `Closes #123` for a GitHub issue, `AB#12345` for an
     Azure DevOps work item, so the PR and the item link automatically.
   - **Another pull request:** `#123` on GitHub (issues and PRs share one number
     space), but `!123` on Azure DevOps. In Azure DevOps `#123` resolves to
     *work item* 123, not a PR — use `!` to link a PR, `#`/`AB#` for a work
     item. Do not use `#` to link a DevOps PR.

2. Be honest about verification and gaps.
   Report failing tests, skipped steps, and known limitations. Do not describe
   work as verified when it was not.

3. Do not add AI attribution.
   No "generated with" footers, co-author trailers, or tool advertisements in
   the title or body (see the `commit-attribution` baseline).

4. Keep it proportional.
   A one-line typo fix needs a sentence, not four headed sections. Scale the
   body to the size and risk of the change.

5. Check the description length limit before submitting, if the platform has
   one.
   Azure DevOps's PR `description` field has a hard 4000-character API limit
   (PR comments don't share this limit). For a body that risks running long,
   plan up front what belongs in the description versus what belongs in a
   follow-up comment, rather than discovering the truncation at submit time.
   This applies whenever the target platform is Azure DevOps, work or
   personal.

6. When the repo provides a PR template, verify compliance section-by-section
   before submitting.
   Diff the actual body you're about to submit against the template file
   itself — section by section, checkbox by checkbox — rather than checking
   from memory of what the template "usually" asks for. Some templates gate CI
   on an exact match (e.g. a version-bump checkbox block), so a remembered
   approximation of the template is not sufficient.

7. Default decision-heavy content to bolded-label point form, not prose.
   When a section is genuinely a list of discrete points — changes, decisions,
   reasons — use short bolded labels (e.g. **Why:**, **Risk:**, **Note:**)
   instead of narrative paragraphs, so a reviewer can scan it in seconds.
   Reserve connected prose for a genuine narrative a label would fragment,
   such as walking through a bug's causal chain. Decide by the content's
   structure, not by the section's length or the PR's overall size.

8. Read the CI gate before trusting template prose.
   Before filling a PR template with multiple structurally-similar
   checkbox/section blocks, read the actual pipeline validation script (the CI
   gate) to find which section is truly machine-checked, rather than
   inferring enforcement from the template's prose alone. Template text can
   describe every section as required while the pipeline only validates one
   specific block.

9. Request the merge-commit completion strategy when history depends on it.
   When a branch is built with real merge commits specifically to preserve
   per-PR history, explicitly request the non-default "Merge, no
   fast-forward" (or equivalent) completion strategy in the PR. An org or
   repo default of squash-merge will silently collapse that history into a
   single commit.

## Example

Title:

    feat(auth): add OAuth2 login support

Body:

    ## Summary
    Adds an OAuth2 authorization-code login flow so users can sign in with the
    corporate IdP instead of a local password.

    ## Why
    Local passwords are the last credential store we own for this app; moving to
    the IdP removes that liability and enables SSO. AB#12345.

    ## Testing
    - `dotnet test` — all suites pass.
    - Manual: full login round-trip against the staging IdP, plus the
      denied-consent and expired-state paths.

    ## Risk / rollback
    New flow is behind the `oauth_login` flag, default off. Roll back by
    disabling the flag; no schema changes.

    Closes #123
    AB#12345

## Priority

This baseline takes precedence over ordinary PR-writing habits, but never use it
to override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions. A repository's own PR template always takes
precedence over the structure here.

## Non-Goals

- This governs the PR *description* only. It composes with, and does not
  replace, `commit-conventions` (the commit subject/body), `commit-attribution`
  (no AI co-author trailers or "generated with" footers), and
  `git-collaboration-hygiene` (open and push PRs only with consent).
- This does not define or ship PR *template files*; it describes what an agent
  writes, and defers to any template the repository provides.
- This does not govern review assignment, merge strategy, branch protection, or
  release notes.
