# PowerShell Conventions Baseline

Status: active
Version: 0.5.0

Always-on PowerShell correctness rules for scripts that must behave the same
way across PowerShell versions (Windows PowerShell 5.1 and `pwsh` 7+) and, for
scripts that claim cross-platform support, across operating systems (Windows,
macOS, Linux). Distilled from two 2026-07 incident notes captured during
`ai-toolkit`/`es-ai-toolkit` `baseline.ps1` work, where PowerShell's own
silent-coercion behavior masked a bug that only surfaced on a different
runtime or OS than the one used during development.

## Principles

1. Wrap any PowerShell function call that can return zero, one, or many items
   in `@(...)` at every call site.
   Do not rely on the function's own `return $collection` statement to
   guarantee array-typed output at the call site — PowerShell silently
   unwraps a single-element array to a scalar across a function-return
   boundary, string or object alike. `pwsh` 7+ adds a synthetic
   `.Count`/`.Length` convenience to scalar objects (a lone returned object
   reports `.Count -eq 1` instead of having no `.Count` property at all), so
   a bug of this shape can pass silently under `pwsh` and only surface under
   real Windows PowerShell 5.1, which has no such convenience. Never treat
   "works under `pwsh`" as evidence a script works under 5.1 for any code
   path with scalar-vs-array ambiguity — test collection-count edge cases
   (0, 1, many) under every PowerShell version the script needs to support.
   This matters only for functions whose result count is genuinely variable;
   a function documented to always return a fixed shape doesn't need the
   wrap, but it costs nothing when in doubt.

2. Never embed a literal backslash inside a single string argument that
   stands in for multiple path segments, in any script meant to run under
   `pwsh` on more than one OS.
   Code like `Join-Path $repoRoot "baselines\$Pack"` works on Windows only by
   accident, because backslash happens to be the native separator there. On
   macOS/Linux `pwsh`, .NET Core's path handling treats a backslash inside a
   string as a literal character, not a path separator, so the call produces
   one malformed path component instead of the intended two segments, and the
   file or directory is never found. Use forward slash (`/`, accepted by both
   Windows and POSIX filesystems) or pass each segment as its own `Join-Path`
   argument, nesting 2-arg calls if the environment doesn't support the
   3+-arg form. A script whose compatibility contract says "Windows only"
   doesn't need this discipline, but forward slashes cost nothing there
   either and remove the bug class for free if that contract ever changes.

3. Quote a literal `@`-prefixed string argument passed to a PowerShell
   command.
   Unquoted, it's parsed as splatting syntax and the argument is silently
   dropped rather than passed through.

4. On Windows via git-bash/MSYS, `ln -s` to create a new symlink can
   silently no-op.
   No error is thrown, and a sandbox override does not help. Use
   PowerShell's `New-Item -ItemType SymbolicLink` instead, and confirm
   success with `Get-Item <path> | Select LinkType` rather than trusting the
   no-error exit code.

5. `switch` falls through: every matching branch runs, not the first.
   PowerShell's `switch` is not C#. With `-Wildcard` and overlapping
   patterns, a single input runs every branch it matches and the last
   assignment wins — `~/.claude/CLAUDE.md` matches both `"~/*"` and
   `"*.md"`, so a user-tier path resolved under the repo instead and every
   lookup afterwards failed with a "cannot find path" naming a directory
   that never existed. For overlapping patterns where exactly one should
   win, use `if`/`elseif`, or end every branch with `break`; order the
   patterns most-specific-first either way. Fall-through is occasionally
   what you want (one input, several side effects) — the trap is using
   `switch` as a first-match-wins *expression*, which is how it reads to
   anyone arriving from another language.
   _(added 2026-09-15, from `powershell-switch-wildcard-runs-every-matching-branch`;
   replaced the git-bash `MSYS_NO_PATHCONV` principle, which moved to
   `repo-context-grounding` because this pack's `**/*.ps1` scoping meant it
   could never load at the moment it was needed)_

6. Route a command name that other tools or scripts will also invoke
   through a PATH-based shim (a real executable on `PATH`), not a shell
   alias.
   Shell aliases only expand in an interactive shell session. A
   non-interactive or scripted invocation — another script, a tool that
   shells out, a CI job — calls the command name directly, never sees the
   alias, and silently falls through to the original command instead of
   the intended override. A PATH-based shim is a real, executable file on
   `PATH` under the target name, so every caller, interactive or scripted,
   resolves to it the same way.

7. PowerShell variable names are case-insensitive, so `$P` and `$p` are one
   variable.
   A `foreach ($p in ...)` loop running inside a scope that holds `$P`
   overwrites it on the first iteration. On 2026-09-15 that turned
   `-TargetRepo $P` into `-TargetRepo 'karpathy-principles'`, and the failure
   surfaced as three `Cannot find path` lines naming a pack — which reads as a
   bad argument, not as a destroyed path variable. Name loop variables for
   what they iterate (`$pack`, `$repo`, `$file`) so the collision is
   impossible rather than unlikely, and never distinguish two live variables
   by case alone. The verification half generalises past PowerShell and lives
   in `verification-epistemics`: the follow-up `status -TargetRepo $P` then
   ran against a directory that did not exist and reported every pack
   `Effective = YES` from the user tier — which is exactly what success looks
   like.
   _(added 2026-09-15, from `powershell-variable-names-are-case-insensitive`.
   Note this pack's `**/*.ps1` scoping: the incident happened inline in a
   PowerShell tool call, not in a `.ps1` file, so this rule would not have
   loaded. The authoring-direction habit in `repo-context-grounding` is what
   has to carry it.)_

## Priority

Apply this baseline before ordinary PowerShell scripting habits, but never use
it to override explicit user instructions, safety rules, privacy boundaries,
or stricter repo-local instructions.

## Non-Goals

- This does not cover general PowerShell style (naming, formatting,
  comment-based help, error-handling idioms) — only the two cross-version and
  cross-platform correctness traps above.
- This does not require or forbid Pester or any other specific test
  framework; it describes correctness properties the agent's PowerShell
  output should have, however the repo chooses to verify them.
