# Repo Context Grounding

Status: active
Version: 0.7.0

Before meaningful work in an existing repository:

- Start from local instructions: read repo-level agent instructions, README, and linked docs that define setup, boundaries, ownership, or workflow.
- Inspect current state: check the active branch, working tree, and relevant recent changes before edits, pulls, commits, rebases, or pushes.
- Discover native workflows: find build, test, lint, format, run, and verification commands from repo files and docs before inventing commands.
- Respect boundaries: identify generated files, private data, external configuration, vendored code, and ownership boundaries before editing.
- Follow local patterns: match existing architecture, naming, dependency choices, test style, and documentation style before introducing new structure.
- Ask after checking available context: do not ask the user to restate repo background until local instructions and visible project context have been inspected.
- Verify at the right level: run the smallest meaningful repo-native check first, then broaden verification when changes touch shared behavior or public interfaces.
- Before proposing new process, tooling, or a new skill/repo/governance layer in a repo, explicitly check whether that repo already documents a build-gate or promotion doctrine (e.g. a "pain twice, dated" rule) and evaluate the proposal against it — rather than relying on vague recollection of whether such a doctrine exists.
- Check for a local copy before asking to re-supply: when a chat or integration tool can only describe an attachment (filename, size, metadata) but cannot fetch or render its content, check whether the same file already exists on local disk before asking the user to re-supply it.
- Prefer an installed shim/wrapper command over a repo's raw tooling script path: check `Get-Command <name>` / `where <name>` for an installed CLI before falling back to `./scripts/<name>` or `.\scripts\<name>.ps1`. A repo may deliberately name its shim differently from its own script path (e.g. a prefix distinguishing it from a sibling repo's identically-structured tool) specifically so invocations don't cross-target the wrong repo — using the raw path bypasses that distinction, and any command text written into commit messages or PR descriptions inherits the same wrong name.
- When a decision hinges on which of two similar-looking folder/naming conventions is "the real one," don't infer intent from current contents (that's circular) — check the newer/less-established one's origin commit (`git log --follow --diff-filter=A`) and read its diff/message before treating the split as deliberate.
- On a large or binary-heavy unfamiliar codebase, don't assume shell `grep`/`find --exclude-dir` is fast enough — exclude flags filter what's reported, not what's scanned. Default to a purpose-built, traversal-aware search tool instead when one is available.
- Before code-archaeology on an unfamiliar adjacent repo, read its root CLAUDE.md/AGENTS.md/README first — it often already answers scope, consumers, and status.
- When a task references an external repo/tool by name whose path isn't in the working directory, memory, or visible context, ask the user for the path before running a broad/unscoped filesystem search (a whole-home-dir `find`, a recursive search across unrelated trees) — a scoped guess (a likely parent folder) is fine, but an open-ended sweep outside the working directory is both slow and likely to get declined. Doesn't apply to searches scoped to the current working directory or its known subdirectories.
- Before writing a new setup/admin script for a task a repo likely already has a runbook for, search the repo's documentation/runbook folders for an existing canonical procedure first, and mirror its exact conventions — don't improvise a shape that merely satisfies constraints, even for "throwaway" work, since deviations get silently baked into reusable scripts.
- On Windows, when a Bash tool's (git-bash) `which`/`command -v` reports a documented, user- or repo-installed CLI shim as "not found," that is not proof the shim is missing — git-bash's PATH can differ from the Windows user PATH a shim installer wrote to. Check `Get-Command <name>` in PowerShell (or `cmd.exe /c where <name>`) before concluding a documented tool isn't installed. Doesn't apply when nothing is found in either shell, or on non-Windows environments with only one shell/PATH to check.
- On Windows, even under Git Bash, don't assume `/tmp` exists — don't target it for ad hoc scratch files (content staged for a CLI's `@file`/piped argument). Write directly to the session's existing scratchpad directory instead of attempting `/tmp` first and falling back after a failure.
- To browse or read source files in a third-party (non-local) GitHub repo, skip `WebFetch` (it reliably 404s on `raw.githubusercontent.com` and `github.com/.../tree/...` URLs) and go straight to `gh api repos/{owner}/{repo}/contents/{path}` (list a directory) plus `--jq '.content' | base64 -d` (read a file) — only when `gh` is installed/authenticated and the target is GitHub-hosted; for arbitrary non-GitHub pages `WebFetch` remains the right tool.
- A newly-configured MCP server won't appear mid-session no matter how many times a tool search retries — the running client process needs a full restart, not just a reconnect, to pick it up.
- Before answering any "does X exist / is X implemented / what does the current code do" question from a git-tracked repo, check `git status --short --branch` first; if the question is about the default branch and the checkout is on something else, read via `git show origin/<default-branch>:<path>` rather than the working tree. On a monorepo, resolve "where does component X live" with `git ls-tree -r --name-only origin/<default-branch>` *before* any working-tree search — a missing whole module directory reads far more convincingly as "doesn't exist" than a missing file does, and a repo's own root instructions can be stale about layout, so trust `git ls-files` over prose when they disagree. _(added 2026-09-09, from `reopened-verify-against-origin-default-branch-not-local-checkout`)_

## Priority

This baseline is a startup and context-grounding habit. It does not replace
repo-specific instructions, project-specific setup docs, or triggered workflow
skills, and it never overrides explicit user instructions, safety rules, or
privacy boundaries.
