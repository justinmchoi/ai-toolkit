# AI Toolkit

Agent skills and instructions tend to stay locked to whichever tool they were
written for. This repo keeps reusable agent behavior in one MIT-licensed
source tree, currently 17 invocable skills and 12 always-on baseline packs,
and exposes it to Claude Code, Codex, and Copilot through explicit adapters,
managed instruction blocks, and deterministic install, apply, and verify
scripts.

## Layout

```text
.
├── AGENTS.md
├── CLAUDE.md
├── CONTEXT.md
├── .claude/
│   └── skills/
├── Glossary/
├── baselines/
├── bookshelf/
├── flows/
├── hooks/
├── presets/
├── docs/
│   ├── adr/
│   ├── agents/
│   ├── how-to/
│   ├── reference/
│   └── specs/
├── scripts/
│   ├── baselines/
│   ├── compat/
│   ├── skills/
│   └── lib/
└── skills/
    ├── engineering/
    └── media/
```

Planned future source trees:

```text
agents/
templates/
```

> `workflows/` used to be listed here. It shipped as **`flows/`** — same concept, realized name.
> There is no separate `workflows/` tree and there should not be one.

### Domains, by when they load

The axis that decides most placement questions is not *what* an artifact is but *when it costs you
context*.

| Domain | What it is | Loads |
|---|---|---|
| `baselines/` | always-on context packs | every turn (see the core/full split) |
| `skills/` | on-demand procedures | on invocation; only name + description stay always-on |
| `hooks/` | mechanical enforcement | on a tool event |
| `flows/` | a methodology spanning several skills, as a state graph | referenced by its entry skill |
| `Glossary/` | this toolkit's own vocabulary, one file per term | read on demand |
| `presets/` | named subsets of baseline packs | n/a |

**Core / full split.** An always-on pack may ship two renderings: `adapters/CLAUDE.md.block` (the
full, append-only reference) and `adapters/CLAUDE.md.core.block` (slim, target under 15 lines,
tagged `(core)` in its marker). `apply` installs core by default when one exists and **preserves
whatever is already installed**; `-Variant core|full` chooses explicitly. This bounds always-on cost
by construction instead of by deleting rules.

**Path-scoped rules.** A pack whose rules are file-type-specific declares `paths` in `pack.json` and
installs with `-Tools claude-rule`, writing `.claude/rules/<pack>.md` with `paths:` frontmatter so it
loads only when a matching file is read. `-Tools all` does not include it — it is opt-in by name.

**Commit gate.** `.githooks/pre-commit` runs the drift check on every commit, and the test suites
whenever `scripts/` is touched. It is **not** active in a fresh clone — `core.hooksPath` is local
config, so run this once:

```sh
git config core.hooksPath .githooks
```

Bypass deliberately with `git commit --no-verify` when you mean to.

**`AGENTS.md` and `.github/copilot-instructions.md` in consuming repos are knowingly
unmanaged.** Only Claude inherits instruction files, so a baseline block in one of those two is the
*only* copy Codex or Copilot gets — correct, not redundant. Many repos therefore carry blocks there
at versions of packs that no longer exist upstream. **This is a deliberate hold, not an oversight:**
they are stale, `audit` reports them as such and never edits them, and bringing them current is a
separate decision that depends on whether those tools are actually in use. Do not "fix" them as part
of a Claude-side cleanup — deleting them removes the only guidance those tools have.

**Drift checking.** `baseline doctor` verifies every invariant this repo has actually broken before:
version coherence across `pack.json` / `baseline.md` / adapter markers, the three full adapters being
identical, core tagging, apply/remove target parity, skill frontmatter, every canonical skill having
a `.claude/skills/` project adapter that points at it, installed skills being links rather than
copies, and every on-disk domain appearing above. `-Repos` also sweeps installed state
in other repos (a path, a glob ending in `*`, or `.`/`cwd`); `-Here` is shorthand for `-Repos .`.
It also prints **advisories** — judgment calls that do not fail the build, such as a skill that
loops and names other skills but belongs to no flow.

`-Fix` repairs the two unambiguous problems: a **stale install** (re-applied from source, preserving
the installed variant) and an **orphaned rule** (deleted — its pack no longer declares `paths`, so
it had started loading eagerly, which is worse than absent). It deliberately does **not** fix a
**duplicate tier**: which tier should own a pack is a real decision, and a tool that silently deletes
instruction blocks will eventually delete one someone meant. Use `baseline remove <pack>` in the
repo that should give it up.

`scripts/tests/baseline-tests.ps1` (13 cases) covers the CLI; `scripts/tests/install-tests.sh`
(4 cases) covers skill installation. Both are mutation-tested.


## Source Trees

- `skills/` owns invoked workflow skills.
- `baselines/` owns always-on managed instruction packs.
- `bookshelf/` owns unprocessed external resource pointers (skill repos,
  tools, articles) — one note per resource, indexed in `bookshelf/INDEX.md`.
- `flows/` owns multi-skill methodologies declared as state graphs. This is what the
  long-planned `workflows/` tree became — one concept, one directory. Do not add a
  `workflows/` tree alongside it.
- `agents/` will own reusable role or agent profiles when the contract is
  proven.
- `scripts/` owns deterministic install, apply, remove, verify, and shim
  commands.

Skill lifecycle status, confidence, evidence, and promotion decisions for this
repo's skills are tracked in `docs/skills-inventory.yaml`.

## Quickstart

Verify skills and adapters:

```powershell
./scripts/skills.ps1 verify
```

List and inspect skills:

```powershell
./scripts/skills.ps1 list
./scripts/skills.ps1 show diagnose
```

Install personal skill adapters:

```powershell
./scripts/skills.ps1 install user codex -Copy
./scripts/skills.ps1 install user claude -Copy
```

Install a project skill profile for Claude Code from a downstream repo:

```powershell
skills install repo query-azure-devops claude
skills list repo claude
skills verify repo claude
```

Project-scope installs copy selected skills into `.claude/skills/` and record
the intended set in `.ai-toolkit/skills.json`. They do not create project
symlinks.

List and apply baselines:

```powershell
./scripts/baseline.ps1 list
./scripts/baseline.ps1 show karpathy-principles
./scripts/baseline.ps1 apply karpathy-principles -DryRun
./scripts/baseline.ps1 apply karpathy-principles,git-collaboration-hygiene   # ad hoc subset
./scripts/baseline.ps1 apply-all -DryRun
./scripts/baseline.ps1 status                                               # what's in effect here, and from where
./scripts/baseline.ps1 help
```

`baseline list` shows each pack plus whether it is already present in the
current target repo's Claude, Codex, or Copilot instruction file — a simple
local-file check. `baseline status` is inheritance-aware: it also checks
parent directories and `~/.claude/` (user-level), since Claude Code
concatenates instructions from all of those rather than only reading the
current repo. See [`baselines/README.md`](baselines/README.md) for the full
CLI reference, including `apply-preset` for named reusable pack subsets and
`status -Repos`/`-ReposFile` for a multi-repo dashboard.

`skills list` shows each skill plus whether it is installed for the selected
personal or project runtime target.

List and apply hooks:

```powershell
./scripts/hooks.ps1 list
./scripts/hooks.ps1 show ensure-vercel-cli
./scripts/hooks.ps1 apply ensure-vercel-cli -TargetRepo <path> -DryRun
./scripts/hooks.ps1 help
```

`hooks list` shows each pack plus whether it is already applied for the selected tool and scope.

Install the optional `hooks` command shim:

```powershell
./scripts/hooks.ps1 shim install -AddToUserPath
```

Install optional command shims:

```powershell
./scripts/baseline.ps1 shim install -AddToUserPath
./scripts/skills.ps1 shim install -AddToUserPath
```

## Docs

- [Install Guide](docs/how-to/install.md): personal skill install, shims,
  symlink/copy behavior, and platform notes.
- [Repo Layout](docs/reference/repo-layout.md): current source trees, script
  folders, and ownership rules.
- [Compatibility](docs/reference/compatibility.md): legacy repo name, legacy
  paths, legacy baseline markers, and migration behavior.
- [CLI Comparison](docs/reference/cli-comparison.md): command vocabulary,
  parameter names, scope values, and per-tool settings files across the
  baseline, skills, and hooks CLIs.
- [Upstream Sources](docs/upstream-sources.md): source and license records for
  imported material.
- [Bookshelf](bookshelf/INDEX.md): unprocessed external resources (skill
  repos, tools, articles) worth remembering, one note per resource.
- [Specs](docs/specs/): accepted and draft workflow/design specs.
- [Context](CONTEXT.md): glossary and stable domain language.

## Current Contents

Imported engineering skills from `mattpocock/skills` are kept here with
attribution in `NOTICE.md` and `docs/upstream-sources.md`.

Local companion skills include `grill-spec`, `methodology-intake`,
`setup-agent-team`, `staff-level-review`, `client-flow-diagrams`,
`query-azure-devops`, `improvement-extraction`, and `session-closeout`. Media
skills include `social-live-photo-card`.
(`capture-input-note` lives in `../ai-second-brain`; `ship-vertical-slice`
and `diagnose-regression` were retired as thin duplicates of `tdd` and
`diagnose` — see `docs/adr/0002-no-parallel-thin-skill-variants.md`.)

Current baseline packs include `karpathy-principles`,
`git-collaboration-hygiene`, `repo-context-grounding`,
`oop-extension-safety`, `code-doc-sync`, `layered-ownership`,
`vercel-operations`, and `supabase-operations`.

## Development

After editing skills or adapters:

```powershell
./scripts/skills.ps1 verify
```

After editing baseline packs:

```powershell
./scripts/baseline.ps1 verify
```

Keep each `SKILL.md` concise. Move long references, examples, or scripts into
supporting files inside the skill directory.

Keep maintenance metadata in `SKILL.md` frontmatter rather than companion
metadata files. Runtime fields `name` and `description` are required; new local
skills should put `status`, `problem`, `when-not-to-use`, and `maintainer` under
a `metadata:` map when known.
