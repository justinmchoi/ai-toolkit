# Portable Baselines

Portable baselines are reusable always-on instruction packs for AI coding
agents. They are lighter than skills: a baseline changes the agent's default
posture in every chat, while a skill defines a triggered workflow with inputs,
steps, outputs, verification, and stop conditions.

Use this directory for baseline packs that should be easy to copy into a repo,
review in a diff, update by marker, and remove later without touching unrelated
repo-specific instructions.

## Catalog

| Pack | Status | Purpose |
|---|---|---|
| `repo-context-grounding` | active | Apply default startup habits for existing repositories: read local instructions, inspect context, discover workflows, respect boundaries, and verify with repo-native checks. |
| `git-collaboration-hygiene` | active | Apply default Git collaboration safety: inspect status, protect user changes, stage explicit paths, review diffs, base new work on an up-to-date remote base, avoid unsafe remote or conflict handling, cross-diff overlapping branches during review, verify prior related work is merged before branching, and (in any hierarchical issue tracker) check sibling work items before scoping and reference a work item's own ID rather than its parent's. |
| `commit-conventions` | active | Write every commit in the Conventional Commits format: `<type>(scope): description` with an imperative <=72-char subject, a body that explains why, and issue/work-item footer references. |
| `commit-attribution` | active | Keep AI attribution out of commit trailers: no `Co-Authored-By` AI trailer, no "Generated with" footer; mention AI assistance in at most one short prose line if at all, and keep the change itself the headline. |
| `branch-naming` | active | Name every new branch `<type>/<optional-tracking-id>-<short-kebab-description>`, sharing the Conventional Commits type vocabulary so branches and commit subjects rhyme; bare tracking id, lowercase kebab-case, single slash. |
| `pr-description` | active | Fill a repo's PR template when present, else write a Conventional Commits title and a body covering what, why, testing, and risk; platform-correct linking (`!` for a PR on Azure DevOps), bolded-label point form for decision-heavy content, and no AI attribution. |
| `karpathy-principles` | active | Apply four default engineering principles: think before coding, simplicity first, surgical changes, and goal-driven execution. |
| `oop-extension-safety` | active | Guards for OOP extension points: complete template methods, prefer primitive hook parameters, and mock concrete injected types in tests. |
| `code-review-reporting` | active | Conduct and report a review honestly: diff a candidate finding against sibling implementations before calling it a finding, verify prior resolved threads against current source before scoping them out, convert a fix blocked on an unmade product decision into a confirmed defect with branched fixes when current behaviour satisfies no candidate answer, and read a new package's `scripts` block as its CI coverage declaration before reading the diff. |
| `code-doc-sync` | active | Scan for adjacent architecture docs before closing any behavior-changing task; show concrete runtime types in flow diagrams rather than abstract declaration sites; check the target repo's own decision records before recommending a sibling-repo pattern; scope each ADR to one decision; tag verification status on claims in mixed current/target-design docs. |
| `layered-ownership` | active | Keep decision records in the layer that owns them: cross-layer references are pointers not ownership, and no repo becomes a central governance hub. |
| `process-vs-work-doctrine` | active | Adjudication gate for adding process versus doing the work: pain before process, kill a layer to add a layer, minimal form before third real use, write-only records die, frozen means frozen, meta-session quota. |
| `vercel-operations` | active | Operational habits for projects deployed to Vercel: use CLI for observability, check logs before reporting errors, know the production-branch API shape, stable per-branch preview domain approach, Deployment Protection default, and vercel link file variants. |
| `supabase-operations` | active | Operational habits for projects using Supabase: diagnose read-only first, never write to shared data without explicit authorization, check process env before editing config, magic-link allowlist requirements, Auth password storage model. |
| `sql-server-safety` | active | SQL Server correctness for diagnostic/verification/data-fix scripts: NOLOCK exceptions (LOB columns, verification queries), CTEs are not a materialization boundary, sargable diagnostics, read-only-must-not-mutate, shared validate/mutate predicate, reassess design at new scale. |
| `dotnet-conventions` | active | .NET/C# DI registration traps (`TryAdd*` dedup, typed-`HttpClient` static base URL) and treating an unexpected codegen/scaffold diff as pre-existing drift, not something you caused. |
| `startup-config-validation` | active | Validate all required config at service startup with `?? throw` (connection strings, API URLs, credentials, Key Vault names), checking presence only, not content, and excluding values with safe in-code defaults, so a missing value fails fast instead of surfacing as a confusing runtime error. |
| `verification-epistemics` | active | Don't act on an inherited/paraphrased claim without re-verifying against ground truth: schema-not-prose for ambiguous domain terms, `git log -S` pickaxe, empirical repro before a "no mechanism found" verdict, re-read the original ask, diff-before-bulk-accept. |
| `handoff-doc-discipline` | active | Lifecycle discipline for a living (in-place-edited) handoff/resume/plan document: archive the prior version before overwriting, re-read linearly for self-contradiction before dispatching. |
| `powershell-conventions` | active | `@()`-wrap any call to a function returning a variable-count collection at every call site; never embed a literal backslash inside a joined PowerShell path string meant to run cross-platform. |
| `python-conventions` | active | Raw strings/forward slashes for Windows paths interpolated into one-liners; `json.JSONDecoder().raw_decode()` for "Extra data" JSON files; forced UTF-8 plus file-redirected re-fetch verification for Python-backed CLIs on Windows consoles; plain ASCII punctuation instead of HTML entities in scripted Azure CLI ticket updates. |
| `agent-orchestration` | active | Dispatch/coordination mechanics for AI sub-agents and background agents: verify worktree-isolation scope before trusting it in another repo, hand continuation dispatches concrete already-discovered specifics, post labeled partial syntheses from parallel agents, stop (don't route around) IAM/secret-adjacent classifier blocks, and grep a shared log for ordinal collisions immediately before writing. |
| `documentation-craft` | active | Documentation structure/mechanics/prose discipline: track cross-file edit recommendations as actions, verify link integrity by script after moves/renames, treat a cross-unit follow-up as a new information-grain category, place general system knowledge in the producer's repo, default user-facing docs to minimum-necessary wording, and keep bug-fix comments short with audit evidence moved elsewhere. |
| `testing-practices` | active | General testing-practice discipline: keep tests self-contained instead of depending on external mutable config, pick the coverage layer that already verifies a behavior before adding a more expensive one, treat shared remote/E2E environments as reflecting their currently deployed build rather than local code, and localize uniform batch test failures to the shared harness before assuming the product has many independent bugs. |

## Pack Shape

Each pack should contain:

```text
baselines/<pack-name>/
  pack.json
  baseline.md
  adapters/
    AGENTS.md.block
    CLAUDE.md.block
    copilot-instructions.md.block
```

Add adapters only when the target runtime has a stable project-level
instruction surface.

## Sunset Review

Always-on rules cannot be counted per use, so packs use sunset reviews
instead. A pack's `review_by` date in `pack.json` marks the next review. At
review, ask one question per rule: which concrete session in the past 90
days did this rule visibly change? Keep the rules that have an example, cut
the ones that do not, then set the next `review_by`. Packs without a
`review_by` yet inherit the date of the next repo-wide review.

## Adapter Contract

Each `.block` adapter is the complete runtime behavior contract for that
target instruction surface. Keep it minimal, but include every rule, exception,
priority note, and term definition the agent needs to make the same decisions
without reading `baseline.md`.

Use `baseline.md` for the fuller human-maintained source: rationale,
provenance, examples, non-goals, and revision context. Do not rely on an agent
to discover or read `baseline.md` at runtime unless the adapter explicitly
instructs it to do so.

## Managed Block Rule

Adapters must be bounded by clear markers:

```markdown
<!-- BEGIN baseline:<pack-name> vX.Y.Z -->
...
<!-- END baseline:<pack-name> -->
```

Downstream repos may remove a baseline by deleting only the marked block. Future
installer scripts should replace only the matching marked block and should not
rewrite surrounding repo instructions.

Legacy downstream blocks using `portable-agent-baseline:<pack-name>` remain
valid for verification and removal. Running `baseline apply` on a target with a
legacy block replaces it in place with the current `baseline:<pack-name>`
marker instead of appending a duplicate block.

## Baseline Versus Skill

- Use a portable baseline for always-on judgment principles that should apply
  before tool-specific or repo-specific instructions.
- Use a skill for a repeatable workflow with trigger criteria, required inputs,
  steps, outputs, verification, and stop conditions.
- Do not turn every baseline into a skill; that makes always-on behavior depend
  on runtime skill discovery and invocation.
- Do not turn every skill into a baseline; that makes ordinary chats too heavy
  and hides workflow-specific entry criteria.

## Team Reuse

For a team skills repo, copy this directory shape first. Start with one baseline
pack, one adapter, and one verification script before adding profiles or
composition. Composition should be a thin profile that lists packs, not a second
copy of the baseline text.

## CLI

Use `scripts/baseline.ps1` as the human-friendly entrypoint:

```powershell
./scripts/baseline.ps1 list
./scripts/baseline.ps1 show karpathy-principles
./scripts/baseline.ps1 apply karpathy-principles -TargetRepo C:\path\to\repo -DryRun
./scripts/baseline.ps1 apply karpathy-principles,git-collaboration-hygiene -TargetRepo C:\path\to\repo   # ad hoc subset
./scripts/baseline.ps1 apply-all -TargetRepo C:\path\to\repo -DryRun
./scripts/baseline.ps1 apply-preset supabase-vercel-site -TargetRepo C:\path\to\repo -DryRun              # named, reusable subset
./scripts/baseline.ps1 presets                                                                            # list available presets and each one's packs
./scripts/baseline.ps1 remove karpathy-principles -TargetRepo C:\path\to\repo -DryRun
./scripts/baseline.ps1 verify karpathy-principles -TargetRepo C:\path\to\repo
./scripts/baseline.ps1 status                                                                             # what's in effect here, and from where
./scripts/baseline.ps1 status -Preset dotnet-service                                                      # same, filtered to one preset's packs
./scripts/baseline.ps1 status -Repos C:\repos\a,C:\repos\b                                                # same, across several repos
./scripts/baseline.ps1 status -ReposFile C:\repos\my-repos.txt
./scripts/baseline.ps1 help
```

`list` is a simple local-file check. `status` is inheritance-aware: it
accounts for how Claude Code actually resolves instructions — repo-local
files, every parent directory up to the filesystem root, and user-level
`~/.claude/CLAUDE.md` / `~/.claude/rules/`. A pack applied only at the user
level shows as in effect everywhere, even where it was never locally
applied — `list` alone would misreport that repo as missing it. Codex
(`AGENTS.md`) and Copilot's instructions file have no documented equivalent
inheritance model, so `status` reports those two as local-file-only.

When called from inside the target repo, omit `-TargetRepo`; it defaults to the
current directory.

`list` shows the available packs and whether each pack is already present in
the target repo's `CLAUDE.md`, `AGENTS.md`, or Copilot instruction file.

When exactly one pack exists, the CLI infers it. Once multiple packs exist,
`show`, `apply`, `remove`, and `verify` require an explicit pack name or
`all`. `apply-all` applies every baseline pack. `-Pack` remains supported for
existing scripts. When `-Tools` is omitted, commands use every supported tool:
`codex`, `claude`, and `copilot`.

Missing instruction files are created by default. Pass `-SkipMissing` on
PowerShell or `--skip-missing` on the shell entrypoint to update only files
that already exist.

On macOS or Linux, the native shell entrypoint is:

```bash
./scripts/baseline list
./scripts/baseline show karpathy-principles
./scripts/baseline apply karpathy-principles --dry-run
./scripts/baseline apply-all --dry-run
./scripts/baseline help
```

## Global Shim

Install a reversible command shim when you want to run `baseline` from
any repo.

Windows PowerShell or CMD:

```powershell
./scripts/baseline.ps1 shim install -AddToUserPath
baseline list
./scripts/baseline.ps1 shim remove
```

macOS or Linux:

```bash
./scripts/baselines/install-shim.sh
baseline list
./scripts/baselines/install-shim.sh --remove
```

The shim writes only one command wrapper into the selected bin directory. It
forwards to this repo's CLI and does not copy packs or write assistant runtime
state. Installing it also removes older matching `p-baseline` or
`portable-baseline` shims from the same install directory.
