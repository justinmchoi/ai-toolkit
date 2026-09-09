# Repo Agent Guide

## Communication

- Use traditional Chinese to reply unless the user explicitly asks for another language.
- Prefer concise, direct engineering communication.
- If the repo is missing context, inspect first and create the minimum viable scaffolding before coding.

## Roadmap

Before planning work related to methodology intake, engineering skills, agent
workflows, staff-level review, or external workflow intake, read the canonical
roadmap in this repo:

```text
docs/ROADMAP.md
```

Use it as the current source of truth for priorities and for deciding which
workflows are still being grilled before becoming formal skills. The former
ecosystem-wide roadmap at `../ai-ops-ecosystem-spec/spec/ROADMAP.md` is frozen
historical reference; do not treat it as current.

## Repository Design

- Recommended repo name: `ai-toolkit`.
- `skills/` is the canonical source for reusable skills.
- `baselines/` is the canonical source for always-on agent baseline packs.
- `workflows/`, `agents/`, and `templates/` are planned source trees for
  reusable workflow definitions, role packs, and supporting templates.
- `.claude/skills/` is the Claude Code project adapter.
- `scripts/skills.ps1` is the public skill CLI.
- `scripts/baseline.ps1` is the public baseline CLI.
- Personal installs use symlinks by default through
  `~/.local/share/ai-toolkit/current`. On Windows, use Git Bash
  with real symlink support, such as elevated Git Bash plus
  `MSYS=winsymlinks:nativestrict`. `--copy` is only an explicit fallback.
  After moving or renaming the repo, run `scripts/skills-setup/repair-personal-links.sh`.
- The upstream engineering skills are imported from `mattpocock/skills`; do not present them as original work from this repo.
- Local companion skills are `grill-spec`, `methodology-intake`,
  `setup-agent-team`, `staff-level-review`, `client-flow-diagrams`, and
  `query-azure-devops`. (`capture-input-note` migrated to
  `../ai-second-brain/skills/` on 2026-07-03; capture skills live in the
  capture layer. `ship-vertical-slice` and `diagnose-regression` were retired
  on 2026-07-03 as thin duplicates of `tdd` and `diagnose`; see
  `docs/adr/0002-no-parallel-thin-skill-variants.md`.)
- Reusable candidate skills may live in `skills/engineering/`. Record their
  lifecycle metadata in `docs/skills-inventory.yaml` (this repo's skills
  only; the skillops repo is frozen).
- Preserve `NOTICE.md` when changing or refreshing imported skills.
- Update `docs/upstream-sources.md` before importing or refreshing external skill material.
- Read `docs/reference/repo-layout.md` and
  `docs/specs/0001-cross-tool-skills-repo.md` before changing layout or install
  behavior.
- Read `docs/specs/0005-capture-input-note-vs-methodology-intake.md` before
  changing methodology-adoption behavior; the capture side
  (`capture-input-note`) now lives in `../ai-second-brain`.

## Delivery Loop

1. Clarify the request with `grill-spec` when no concrete plan exists yet; use `grill-with-docs` to challenge an existing plan against docs.
2. Update `CONTEXT.md` when a domain term or relationship is clarified.
3. Record an ADR only when the decision is hard to reverse, surprising without context, and the result of a real trade-off.
4. Implement with `tdd`: one behavior, one test, one slice at a time.
5. If behavior is broken or regressed, switch to `diagnose`.
6. End substantial work with a short verification summary and next-step risks.

## Repo Docs

- `CONTEXT.md`: glossary only. No implementation notes, no scratch planning.
- `docs/adr/`: architecture decision records and templates.
- `docs/agents/issue-tracker.md`: where work items live and how to create them.
- `docs/agents/triage-labels.md`: canonical triage states.
- `docs/agents/domain.md`: where agents should read domain context from.
- `docs/how-to/`: current operational guides.
- `docs/reference/`: current repo contracts and compatibility notes.
- `docs/intake.md`: repo-level queue of unprocessed notes and captures to grill later.
- `skills/`: repo-local skills that define reusable workflows.
- `baselines/`: repo-local always-on baseline packs with managed-block adapters.
- `.claude/skills/`: Claude Code adapter for project-local skill discovery.
- `scripts/`: deterministic install and verification commands.

## Default Engineering Standards

- Prefer small public interfaces with deep implementations.
- Tests should verify behavior through public interfaces, not implementation details.
- Prefer vertical slices over horizontal task splitting.
- Prefer deterministic scripts and explicit commands over vague instructions.
- Keep naming aligned with `CONTEXT.md`.
- Keep portable baselines distinct from skills: baseline packs are always-on
  managed instruction blocks; skills are triggered workflows.

## Local Issue Workflow

- Default tracker: local markdown issues under `.scratch/issues/`.
- File naming: `NNNN-short-kebab-title.md`.
- Each issue should describe user-visible behavior, scope, acceptance checks, and out-of-scope items.

## Safety

- 禁止批量刪除文件或目錄。
- 不要使用 `del /s`、`rd /s`、`rmdir /s`、`Remove-Item -Recurse`、`rm -rf`。
- 如需刪除文件，只能一次刪除一個明確路徑的文件。
- 如果需要批量刪除，停止並請用戶手動處理。

<!-- BEGIN baseline:karpathy-principles v0.2.0 -->
## Portable Agent Baseline: Karpathy Principles

- Think before coding: state assumptions, surface ambiguity, and ask when the safe interpretation is unclear.
- Simplicity first: prefer the smallest design that satisfies the request; avoid speculative abstractions or extra configuration.
- Surgical changes: touch only files and lines needed for the task, match local style, and mention unrelated concerns instead of editing them.
- Goal-driven execution: turn open-ended work into success criteria and verify the result with tests, scripts, inspection, or another concrete check.

This baseline takes precedence over ordinary implementation habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions.
<!-- END baseline:karpathy-principles -->


<!-- BEGIN baseline:layered-ownership v0.2.0 -->
## Portable Agent Baseline: Layered Ownership

- Each repo or layer records its own decisions, status, and roadmap; do not write another layer's decisions into this repo's documents.
- Cross-layer references are pointers, not ownership: link to the owning repo's artifact instead of duplicating or governing it.
- Before recording a status or decision entry, identify which layer owns the affected asset and record it in that layer's own documents.
- Do not create or grow a central governance hub; if a document starts mirroring another repo's changes, stop and move the content to its owner.

This baseline takes precedence over ordinary documentation habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions.
<!-- END baseline:layered-ownership -->

<!-- BEGIN baseline:process-vs-work-doctrine v0.2.0 -->
## Portable Agent Baseline: Process-vs-Work Doctrine（何時加流程、何時直接做事）

流程的預設答案是「不要」。想建新 repo、skill、spec、自動化或治理層時，先過以下七關；過不了就直接做事。引用本準則擋下違規提案是正當行為。

1. 痛先於流程：同一種失敗有兩次日期可指之前，不建流程、repo、skill 或 spec。
2. 加一層必先殺一層：新 meta 層必須指名它取代誰；meta repo 淨數不得上升（產出型 repo 不在此列）。
3. 三次使用前只准最簡形式：不得有自己的 repo、spec 目錄、install script 或 CONTEXT.md。
4. 只寫不讀即是死：持續寫入的紀錄 60 天沒被任何決策引用即預設凍結（ADR、audit、handoff 等點狀決策紀錄不在此列）。
5. 凍結就是凍結：解凍需指出今天被擋住的真實任務；「可以更完整」不是理由（只修凍結層的誤導性錯誤不算解凍）。
6. 一個 session 能做完的事，不准先搭鷹架：自動化與包裝腳本要等同樣的事第二次出現。
7. Meta 配額：連續 meta session 不得超過 1 個，開始前必須指出服務的下一個實際產出任務（執行已裁決 ticket 與例行維護不佔配額）。

全文與快速判斷表見 ai-toolkit `baselines/process-vs-work-doctrine/baseline.md`。

This baseline takes precedence over ordinary planning habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions.
<!-- END baseline:process-vs-work-doctrine -->

<!-- BEGIN baseline:code-doc-sync v0.5.0 -->
## Portable Agent Baseline: Code-Doc Sync

- Check docs before closing: when a repo has architecture docs and a task changes externally observable behavior or a contract other code depends on (a public API, a documented flow, a class relationship that appears in diagrams), check the docs that describe the changed behavior and decide explicitly whether each needs updating; skipping the check is not acceptable even for bug fixes. Purely internal changes with no observable-behavior or contract impact do not require it.
- Show the concrete runtime type: in flow diagrams and call traces involving virtual or abstract methods, use the concrete class name that executes at runtime, not the abstract declaration site — writing the base class name hides the polymorphism the diagram is meant to explain.
- Check the target repo's own decision records (ADRs, RFCs, a decision-records folder) before recommending a pattern seen working well in a sibling repo — a prior recorded decision may have deliberately picked the more manual or explicit option for a tradeoff the automatic option reintroduces. Where no decision records exist, this reduces to ordinary judgment.
- Scope each ADR to exactly one decision: write one file per genuinely independent decision, not one file per feature, PR, or component, even when several decisions touch the same component — this keeps Context/Alternatives/Consequences honest to a single choice.
- In a mixed current-state/target-design doc, tag each individual claim, arrow, or box as confirmed-in-code, designed-not-built, or unverified rather than relying on uniform notation for both, so a reader can trust what's current without redoing the investigation.
- Before repeating a documented "gap"/"stub"/"not yet implemented" claim as current fact, check whether earlier work in this same session (in this repo or a sibling repo/branch) already closed it, and fix the doc immediately the moment it's found stale — this is the inverse trigger of the check-docs-before-closing bullet above (that fires when you change behavior and must check docs; this fires when you're about to assert a doc's existing claim as true and must check your own prior session work first).
- When resolving an ambiguity produces a manually-enforced cross-system invariant (two independently-created values that must be kept identical, with nothing automated checking it), add a call-out to the operational onboarding template/script that actually creates the value, in the same pass as writing the decision record — not as a follow-up, even when the triggering event was a zero-code-diff decision.
- Before committing a change to an embedded Mermaid diagram, render it with mermaid-cli to catch parse-breaking syntax errors — visual inspection of the diagram source misses syntax that only fails at render time.
- For a rename/reshape of a field or method used across multiple projects and referenced in a linked doc (ADR/test plan), run it as one deterministic checklist instead of reconstructing it by hand each time: grep all usage sites first, fix production code, fix tests, build each touched project incrementally, full-solution build, update linked docs to match, a final stale-reference grep, then `git status`.

These principles are folder-name-agnostic. If the repo specifies where documentation lives (in CLAUDE.md, README, or a project-specific section), read that first. If no documentation is found, these principles fire on nothing — that is acceptable.

This baseline takes precedence over ordinary implementation habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions.
<!-- END baseline:code-doc-sync -->

<!-- BEGIN baseline:git-collaboration-hygiene v0.11.0 -->
## Portable Agent Baseline: Git Collaboration Hygiene

- Inspect repository state before changing or committing: check the active branch and working tree when Git is available, especially before edits, staging, commits, pulls, merges, rebases, or pushes.
- Protect user and peer work: treat uncommitted or unfamiliar changes as user-owned unless proven otherwise; do not overwrite, revert, restage, or reformat unrelated work.
- Stage and commit deliberately: prefer explicit-path staging, review the staged diff before committing, and keep commit messages focused on the behavior or documentation change.
- Keep remote operations consent-based: do not push, force-push, publish branches, rewrite history, or open PRs unless the user or repo workflow has authorized it.
- Treat failures and conflicts as evidence: read CI, test, merge, and conflict output before changing code; do not blindly resolve conflicts.
- Base new work on an up-to-date remote base: before creating a branch or opening a PR, fetch and fast-forward the base branch (e.g. `main`) to its remote tip so work starts from current state rather than a stale local ref — a local base branch can lag the remote even after its own PR has merged.
- Squash an abandoned mid-work detour before the branch's first push (`git reset --soft` + recommit) so pushed history reflects the final approach — never rewrite history that's already been pushed.
- Redo push-readiness checks (fetch, test-merge against current base, build/lint) immediately before the push itself, not earlier in the session — shared branches move.
- Before `gh pr create` or any similar authenticated write, verify the CLI's authenticated account matches the target repo's owner/org — a successful `git push` (SSH) doesn't guarantee a separately-authenticated tool targets the right account.
- Before opening a new branch/PR, check whether one already exists for the same story/ticket and extend it instead, unless the new work genuinely needs independent review. Use `git worktree` to add commits to an existing PR's branch without disturbing an unrelated in-progress checkout.
- When a merge conflict is modify/delete against an unrelated large rewrite (module migration, language port, big rename), read that rewrite's diff and new conventions before writing any port code, rather than porting the old logic in as-is.
- When a destructive command is blocked by the safety classifier, look for a non-destructive path to the same end state (e.g. `git branch -f <branch> <ref>` instead of a hard reset on a non-checked-out branch; `git rm` + `git reset --soft` instead of a hard reset when squashing).
- If the user just corrected a related action, restate a merge's direction ("merge X into Y" vs. "merge Y into X" have very different blast radii) before running the next merge-shaped command.
- Cross-diff overlapping branches against each other during review, not just each against base: when reviewing a PR while holding or knowing about a second concurrently open, unmerged branch that touches the same file, class, or config/data surface, diff the overlapping files from the two branches directly against each other — this surfaces semantic conflicts that a base-only diff never shows, since both branches can look individually clean in isolation.
- Reconstruct cross-host PR history from local clones via `git log --all --grep` on merge commits instead of paginating each host's API: when a repo is already cloned locally and the hosting platform's PR-listing API only supports listing/pagination rather than full-text search, filter merge commits by keyword instead — this works identically across GitHub, Azure DevOps, and other hosts that embed the PR title in the merge commit message, though it breaks down for squash-merge or rebase-only workflows with no distinct merge commit.
- Verify via `git log` and `git merge-base --is-ancestor` against the actual remote, not memory, whether a prior round's related work has merged before branching for follow-up work: if that related work is still unmerged (an open PR, an unreviewed branch), branch from that unmerged branch instead of the default base branch.
- Consider a long-lived, never-merged notes/diagrams branch when the team already has that convention, mirroring its existing structure rather than inventing a new one.
- Before scoping a work item that is one of several siblings under a shared parent, check every sibling's assignee and state: in any hierarchical issue tracker (Jira, Linear, GitHub Projects, Azure DevOps, etc.), query the parent's other child items before committing to a scope, and narrow your own scope rather than duplicating overlapping work a sibling is already actively covering.
- Reference a work item's own ID in commit messages and branch names, not its parent's: in a hierarchical tracker, referencing the wrong level causes the tracker's auto-link to attach the change to the parent instead of the child, making the real item look untouched in status reports and dashboards.
- Before pushing additional commits to an already-open PR branch, verify the PR is still open: a reviewer can merge it while you're still working, and pushing to a since-merged branch just strands the commits outside `main` rather than failing loudly — if it's merged, branch fresh from an updated `main`, cherry-pick the stranded commits, and open a new PR instead of force-pushing into a closed one.
- After `git checkout <ref> -- <path>` (or a similarly-scoped restore) to pull one file, immediately run `git diff` to confirm no uncommitted edit to that file was silently clobbered — the command overwrites, it does not merge.
- When resuming a stale, never-pushed local branch whose base has diverged heavily via unrelated churn, check whether the branch's own changed files were touched upstream since the branch point; if not, recreate the branch from the current base and cherry-pick the original commits rather than rebasing through the noise.
- Before requesting review, and after any commit that reverses or removes a feature the PR title/description claims, resync the title/description against the branch's actual current diff, not just its original scope.
- Before merging a stacked PR chain, check the repo's `deleteBranchOnMerge` setting; if false, plan manual base-retargeting (e.g. `gh pr edit <n> --base <target>`) after each merge instead of assuming auto-cascade.
- When describing results of a local-only/speculative git operation (dry-run merge, preview, not-yet-pushed fix), state explicitly up front that nothing is pushed/visible remotely yet, before describing what was found or resolved.
- Before declaring a branch/PR merge-ready or reporting work as pushed, run `git rev-list --count origin/<branch>..HEAD` (or equivalent) rather than trusting recollection of prior `git push` calls in the conversation.
- Before committing/pushing directly to a repo reached through an indirect path (symlink chain, generated worktree, submodule), run `git remote -v` to confirm whether it's personally owned or a shared/team-owned repo; treat any non-personal remote as requiring the same review process as a teammate's PR, not a direct push.
- When verifying a multi-branch integration/merge is complete, build it in a disposable integration worktree (merge N branches, resolve conflicts, build+test) and preview any predicted-but-unseen conflict on a throwaway branch first; then verify completeness by partitioning files into single-owner (cheap byte-diff) vs. shared (added-line diff) rather than one flat loop over all files times all branches.
- Set up `.gitattributes`/`.gitignore` before the first commit on a repo meant for multi-machine sync, and audit that first commit's staged file list for tool-generated local config that slipped in.
- Don't set a path-filtered CI check as a required merge gate: PRs that don't touch the filtered paths never trigger it and get stuck waiting forever — keep it informational, or make the job always run and early-exit-success when irrelevant.
- Use `git rebase --onto`, not a plain rebase, when a branch is stacked on one that gets squash-merged into the base: a plain rebase onto the new base replays the now-squashed lower commits under stale hashes — use `git rebase --onto <new-base> <old-base> <branch>` and verify with `git range-diff` that only the upper branch's unique commits were carried.
- Don't require N approvals in branch protection on a solo/near-solo-maintainer repo: most platforms disallow self-approval, so the rule locks the maintainer out of their own PRs — require PRs and block force-push/deletion, but set required approvals to 0 until there are enough people to expect a reviewer.
- Scope `git stash -u` to explicit paths (`git stash push -u -- <paths>`) when moving work between branches, so untracked scratch/staging folders aren't swept along with it.
- When two independent PRs both need to edit the same line of a shared file, don't edit it in both: merge one first, then rebase the other and add the shared-line edit as a follow-up commit.
- Once a PR has a reviewer attached, treat push as a costly notification-triggering action: batch related changes, run full local verification, then push once, rather than pushing on every micro-edit. On a PR already under active review, ask whether it's OK to push now rather than batching silently — a new push can force the author to re-request a teammate's approval, a workflow cost invisible without being told.
- When a reviewer's requested change conflicts with a decision the task owner already explicitly approved, don't resolve it unilaterally — present the conflict to the owner and wait for a re-decision before proceeding.
- When a push is rejected because the remote has commits you don't have, fetch and merge them in rather than force-pushing — those remote commits may be someone else's real work, not just a stale ref.
- Before concluding a hierarchical tracker's child item has no activity, also check whether the parent (or a sibling) has a misattached PR/commit — the detection-side companion to always referencing the child's own ID: the same wrong-level-reference mistake, made by someone else, is what you're checking for here.
- Before pushing new commits to an already-approved review request, confirm whether the push resets approval (most tools do) and check with the decision-maker first rather than assuming approval carries forward.
- Before committing to a multi-commit split, check whether the concerns are actually separable at the file/hunk level, not just conceptually distinct — if they're woven through the same file's hunks and there's no `git add -p`/`-i` available, default to one commit with each decision labeled in the message body rather than a risky manual patch-level split.
- Write a multi-line commit message likely to contain an apostrophe or contraction to a file via a single-quoted heredoc and commit with `git commit -F <file>` — an inline `-m "..."` can break shell quoting mid-commit and produce confusing pathspec errors.
- Default to a git worktree (`git worktree add -b <branch> ../<repo>-wt-<slug> <base>`) when starting new, unrelated work while the current branch is dirty, instead of stashing in place or switching branches — it fully isolates the new work from the other branch's live state.
- Before scoping a change to a shared/multi-referenced structure (an in-use fallback list, a priority sequence), search git log/history for whether this exact class of change was done before anywhere in the codebase, even a one-off throwaway migration, before re-deriving constraints from current-state code alone.
- When a file referenced by a ticket/doc can't be found via normal search, search all git history (`git log --all --oneline -- <path>`) before concluding it doesn't exist — if found on a non-ancestor commit, read it directly with `git show <ref>:<path>` rather than checking out that branch.
- After renaming a cross-referenced tracked file, grep the whole repo/project for the old filename before declaring the rename complete, rather than relying on memory of which files reference it.

This baseline takes precedence over ordinary Git habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions.
<!-- END baseline:git-collaboration-hygiene -->

<!-- BEGIN baseline:oop-extension-safety v0.4.0 -->
## Portable Agent Baseline: OOP Extension Safety

- Complete the template method: when a base class introduces a `protected abstract` or `virtual` hook, every code path in the base class that involves that decision must route through the hook — a direct field call bypasses virtual dispatch silently.
- Prefer primitive hook parameters: abstract and virtual hook methods should accept the smallest set of primitives needed, not a whole aggregate object; aggregate parameters tie the hook to one caller shape and force bypass code paths when a second caller exists.
- Mock the most-specific injected type: test doubles should mock the exact concrete class or interface registered in DI, not a base class — mocking a base class can satisfy the injection site while hiding that the production code injects the wrong subtype.
- Declare concrete delegate types at the class level: when a class varies only in which concrete types it delegates to (not in algorithms), express that variation through type parameters or equivalent declaration-level constructs rather than constructor parameters alone — a constructor parameter silently accepts any assignable subtype, while a type parameter is visible in every diff and review.
- Prefer a DI-wired subclass hook over an inline caller-type check: when a shared class needs different behavior for a specific caller, prefer a `protected virtual` hook overridden by a DI-wired subclass over checking the caller's concrete type inline — the caller-specific coupling becomes visible at the constructor/DI level instead of buried in logic that reads as caller-agnostic.

This baseline takes precedence over ordinary implementation and test-writing habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions.
<!-- END baseline:oop-extension-safety -->

<!-- BEGIN baseline:repo-context-grounding v0.6.0 -->
## Portable Agent Baseline: Repo Context Grounding

- Start from local instructions: read repo-level agent instructions, README, and linked docs that define setup, boundaries, ownership, or workflow.
- Inspect current state: check the active branch, working tree, and relevant recent changes before edits, pulls, commits, rebases, or pushes.
- Discover native workflows: find build, test, lint, format, run, and verification commands from repo files and docs before inventing commands.
- Respect boundaries: identify generated files, private data, external configuration, vendored code, and ownership boundaries before editing.
- Follow local patterns: match existing architecture, naming, dependency choices, test style, and documentation style before introducing new structure.
- Ask after checking available context: do not ask the user to restate repo background until local instructions and visible project context have been inspected.
- Verify at the right level: run the smallest meaningful repo-native check first, then broaden verification when changes touch shared behavior or public interfaces.
- Before proposing new process, tooling, or a new skill/repo/governance layer, check whether the repo already documents a build-gate or promotion doctrine (e.g. a "pain twice, dated" rule) and evaluate against it, rather than relying on vague recollection.
- Check for a local copy before asking to re-supply: when a chat or integration tool can only describe an attachment (filename, size, metadata) but cannot fetch or render its content, check whether the same file already exists on local disk before asking the user to re-supply it.
- Prefer an installed shim/wrapper command over a repo's raw tooling script path: check `Get-Command <name>` / `where <name>` for an installed CLI before falling back to a raw script path. A repo may deliberately name its shim differently from its own script path (e.g. a prefix distinguishing it from a sibling repo's identically-structured tool) so invocations don't cross-target the wrong repo — and any command text written into commit messages or PR descriptions inherits the same wrong name if you skip this check.
- When a decision hinges on which of two similar-looking folder/naming conventions is "the real one," don't infer intent from current contents (that's circular) — check the newer/less-established one's origin commit (`git log --follow --diff-filter=A`) and read its diff/message before treating the split as deliberate.
- On a large or binary-heavy unfamiliar codebase, don't assume shell `grep`/`find --exclude-dir` is fast enough — exclude flags filter what's reported, not what's scanned. Default to a purpose-built, traversal-aware search tool instead when one is available.
- Before code-archaeology on an unfamiliar adjacent repo, read its root CLAUDE.md/AGENTS.md/README first — it often already answers scope, consumers, and status.
- When a task references an external repo/tool by name whose path isn't in context, ask the user for the path before running a broad/unscoped filesystem search (whole-home-dir `find`) — a scoped guess is fine, an open-ended sweep outside the working directory is slow and likely to get declined.
- Before writing a new setup/admin script for a task a repo likely already has a runbook for, search its documentation/runbook folders for an existing canonical procedure and mirror its exact conventions, rather than improvising a shape that merely satisfies constraints.
- On Windows, a Bash tool's (git-bash) "command not found" for a documented CLI shim is not proof it's missing — git-bash's PATH can differ from the Windows user PATH a shim installer wrote to. Check `Get-Command <name>` in PowerShell before concluding a tool isn't installed.
- On Windows, even under Git Bash, don't assume `/tmp` exists for ad hoc scratch files — write to the session's existing scratchpad directory instead.
- To browse or read source in a third-party GitHub repo, skip `WebFetch` (it 404s on raw/tree URLs) and use `gh api repos/{owner}/{repo}/contents/{path}` plus `--jq '.content' | base64 -d` instead, when `gh` is installed and authenticated.
- A newly-configured MCP server won't appear mid-session no matter how many retries — the client process needs a full restart, not just a reconnect, to pick it up.

Apply this baseline as a startup habit for existing repositories, but never use
it to override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions.
<!-- END baseline:repo-context-grounding -->

<!-- BEGIN baseline:commit-conventions v0.1.1 -->
## Portable Agent Baseline: Commit Conventions

- Write every commit message in the [Conventional Commits](https://www.conventionalcommits.org/) format: `<type>(<optional scope>): <description>`, optionally followed by a blank line, a body, and footer(s).
- Use one of these types: `feat` (new feature), `fix` (bug fix), `docs` (documentation only), `style` (formatting, no logic change), `refactor` (neither a fix nor a feature), `test` (adding or correcting tests), `chore` (build, tooling, or dependency updates), `ci` (CI/CD configuration).
- Keep the subject in present-tense imperative mood and 72 characters or fewer ("add logging", not "added logging"), with no trailing period. Scope is optional but encouraged in larger codebases.
- Put the "why" in the body when the change is not self-evident, wrapping prose at roughly 72 columns. Reference tracking items in the footer: `Closes #123` (GitHub) or `AB#12345` (Azure DevOps work item).
- Flag breaking changes with `!` after the type/scope (`feat(api)!: ...`) or a `BREAKING CHANGE:` footer.
- This governs message format only. It composes with `git-collaboration-hygiene` (stage explicit paths, review the staged diff before committing) and `commit-attribution` (no AI co-author trailers or "generated with" footers).

This baseline takes precedence over ordinary commit habits, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions (including a repository's own established commit convention).
<!-- END baseline:commit-conventions -->

<!-- BEGIN baseline:agent-orchestration v0.2.0 -->
## Portable Agent Baseline: Agent Orchestration

- Before relying on a dispatched sub-agent's `isolation: "worktree"` option to cover work in a repo other than the current session's own, don't assume it covers that other repo — verify the mechanism's actual scope, or create the worktree explicitly in the target repo yourself and hand the agent that literal path.
- When dispatching a background/sub-agent to continue work already partially investigated, include concrete already-discovered specifics (file paths, class/symbol names, ruled-out candidates, commands already tried) in the dispatch prompt rather than a cold open-ended prompt that forces the agent to re-derive them.
- When multiple parallel background agents are working toward one time-sensitive answer, post an interim synthesis of whatever is already solid as soon as it exists, explicitly labeled partial, then layer each subsequent completion on as a scoped update rather than withholding everything until the last agent finishes.
- When a safety-classifier block hits an IAM- or secret-adjacent write, stop and hand the user the exact command/value rather than routing around it via another tool or approach — and don't assume a later identical attempt will fail the same way, since classifier behavior isn't fully deterministic.
- Before appending a sequentially-numbered entry to a shared memory/log file that more than one concurrent session could touch, grep the file for that exact ordinal immediately before writing (not a value read earlier in the conversation); on collision, disambiguate explicitly rather than inventing a corrected total order.
- Before dispatching a background/sub-agent, confirm no other executor (the user's own session, another already-running agent) is already working the same target — especially when the user's phrasing about who did what is ambiguous.
- Before reapplying a fix to shared/base code in a multi-session project, check whether a prior session already tried and explicitly reverted that exact fix (commit messages, PR descriptions, prior capture notes) — a new session does not automatically inherit that history.
- An early step in a sequenced/multi-step process that narrates what a later step in the same run will do describes a plan, not a result — either move that narration to run last, or explicitly re-verify and update it against the sequence's actual final outcome before considering the run complete.

Apply this baseline before dispatching, coordinating, or reporting on sub-agent/background-agent work, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions. This does not cover which agent/model to pick, or prompt-engineering content quality — only dispatch/coordination/scope mechanics.
<!-- END baseline:agent-orchestration -->

<!-- BEGIN baseline:documentation-craft v0.5.0 -->
## Portable Agent Baseline: Documentation Craft

- **[Top-priority principle — outranks the rest below.]** Use one word if it conveys what two would; two words if they convey what more than two would; one sentence if it conveys what more than one would — apply this recursively at every level (word, phrase, clause, sentence, paragraph, section), not just once. Length is not neutral; it's the default this principle pushes back against. Does not apply to durable audit/decision records (ADRs, incident writeups, handoff docs) where completeness outweighs brevity.
- Before requesting review, if a response recommends an edit to a different file than the one being written, either make that edit immediately or explicitly track it as an open item somewhere it will be re-surfaced — a recommendation written in one document's prose is not itself a completed action.
- After moving or renaming cross-linked markdown files, verify link integrity with a script that resolves every relative link target — don't rely on memory of what was touched, and re-check every file that WAS touched (not just the ones intended to reference) for over-broad find/replace corruption of unrelated links.
- When a follow-up documentation request spans or sequences multiple existing units rather than adding depth to any single one, recognize it as a shift in information grain and create a new parallel category instead of forcing it into an existing file.
- When writing or relocating documentation that spans "how the system generally works" and "how this one tool/consumer uses it," place general system knowledge in the producer's repo (linked from the consumer) and keep only tool-specific content in the consumer's repo — decide per section (would this be equally true for a different consumer of the same system?), not by where the need first arose.
- Inline bug-fix code comments should be a short "does X — previously did Y" statement in 1-2 sentences with no duplicated phrasing or ambiguous reused terms; move full audit-trail/cross-validation evidence to a separate durable doc, never inline in the comment itself — this is the top-priority principle above, applied specifically to code comments.
- When adding content to a file in the agent's mandatory-read path (a CLAUDE.md/AGENTS.md-style file read every session), ask whether it needs to be fresh every session; if not, externalize it to its own file with a one-line pointer left in place — the mandatory-read path is a scarce attention budget, not just another place to put things.
- For a highly personalized document (a persona, a voice/style guide, a decision doctrine), elicit its content through layered guided discussion and write each layer to file as soon as it's agreed, rather than discussing everything first and writing once at the end.
- When writing any durable file, a reference must resolve to either inlined content or another durable file's path — never to ephemeral session/conversation context ("see earlier discussion"), which becomes a dead pointer the moment the session ends.
- When one underlying change must inform two audiences with genuinely different needs (a reviewer deciding whether to approve, a learner absorbing what to do differently), write two separate documents rather than forcing both purposes into one.
- When content is deliberately duplicated across multiple files (each adapted per destination), propagate a substantive correction to every copy, not just the one explicitly pointed out — check for sibling duplicates before considering a fix done.
- Default decision/change-dense technical documents in general — not only PR descriptions or review comments — to bolded-label point form when the content is structurally a list of discrete points; choose format by the content's actual structure, not by document type or length.
- After several rounds of incremental, localized edits to the same document, do one full linear read-through before finishing — per-edit review only catches whether each addition is correct in isolation, not whether the document's ordering and cross-references still hold (e.g. a conclusion that cites content added after it).
- When a resolved decision record is superseded, append a dated "superseded" block in place, preserving the original reasoning, rather than rewriting the file or forking to a new one.
- Before correcting an outdated document, classify it first: a point-in-time snapshot (annotate/point to the current source, leave the body's original reasoning unchanged) or a continuously-maintained reference (correct in place, dated) — the two natures require opposite correction strategies, and using the wrong one for either causes real problems.
- Run a comment-tightening pass as diff+grep+rebuild (extract added comment lines from the diff, group into blocks, edit, re-scan, gate on a full rebuild+tests), and never invent a shortened/paraphrased form of a referenced code identifier while tightening a comment — keep it byte-for-byte or re-verify against the declaration.
- When synthesizing a messy human source (meeting notes, a transcript) into a clean doc, flag internal contradictions found in it explicitly rather than silently picking the reading that seems more plausible — only the original author can adjudicate what they meant.
- Update a project's own knowledge folders (glossary, decision log, open-questions) when a durable fact is learned in conversation, not just when code changes — don't wait to be asked, and don't rely on a code-change-triggered doc-sync rule to cover it.
- Before publishing a Mermaid-in-HTML diagram, never rely on `<br/>` inside a `Note over` statement for a line break (use stacked `Note over` lines instead) and grep for any bare `&` not already a valid entity before every publish.
- Tag each listed mitigation as closes-at-root, reduces-odds, or detection-only — never a bare "addressed by"/"closes"/"fixes" — and re-check the rest of the document for the same overstatement once one instance is found.
- Given a false claim already found once, grep the literal text across every touched directory, classify each hit as live vs. deliberately-historical and apply the matching fix, then re-scan every document of the same genre for the same class of issue, not just the one hit.
- When trimming drafted content to a known hard platform character limit, compute the exact excess up front and make one deliberate cut sized to it, rather than iterating blind small edits with a recount after each one.
- Match the codebase's existing selective doc-comment convention (structured comments on some public members, plain comments on implementation detail) rather than defaulting to documenting everything or nothing in a pass.
- Never manually hard-wrap prose in a markdown file — write each paragraph/bullet as one continuous line and let the renderer soft-wrap; manual line breaks render as garbled mid-sentence breaks in plain-text viewers, narrow terminals, and some diff tools.
- Renumbering a markdown doc's sections after an insertion should be one scripted old→new mapping pass over headers, the TOC, and every cross-reference — not manual header-by-header edits discovered piecemeal across multiple ad hoc greps.
- When adding a markdown TOC to a doc with non-trivial headers (punctuation, dashes, backticks), generate the anchor slugs via a script implementing the real GFM slug algorithm rather than hand-typing them, and cross-check against any existing TOC in the same project.

Apply this baseline whenever writing, restructuring, relocating, or reviewing documentation, but never use it to override explicit user instructions, safety rules, privacy boundaries, or stricter repo-local instructions. This does not cover code/doc sync (see `code-doc-sync`) or living-handoff-document lifecycle (see `handoff-doc-discipline`).
<!-- END baseline:documentation-craft -->
