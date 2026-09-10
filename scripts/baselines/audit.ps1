<#
.SYNOPSIS
    Audit a consuming repo: what baselines are effective, what its stack suggests, what to change.

.DESCRIPTION
    `doctor` checks THIS toolkit's own invariants. This checks a repo that CONSUMES it, which is a
    different question: given what this repo is made of, is the right guidance actually reaching a
    session working in it — and is anything reaching it twice?

    Read-only. It prints a plan; it changes nothing. Pass -Apply to act on the safe parts.

    The judgment it encodes:
      - Stack packs belong at the user tier as PATH-SCOPED RULES, not as blocks in a repo. Lazy,
        universal, and no edit to a file the team owns.
      - Behavioural packs (git hygiene, verification, PR/commit conventions) belong always-on at the
        user tier.
      - Company packs belong at the workspace tier.
      - Therefore a consuming repo usually needs NO local blocks at all, and local blocks that
        duplicate an inherited pack are worse than nothing: both land in context, silently, often at
        different versions.
      - A TRACKED instruction file is a team artifact. Never edit it without a PR.

    Run:  pwsh -File scripts/baselines/audit.ps1 -Repos "C:\path\to\repo"
          pwsh -File scripts/baselines/audit.ps1 -Repos "C:\repos\*" -Apply
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Repos,
    # Act on the safe parts: remove local blocks that duplicate an inherited pack, but only from
    # UNTRACKED instruction files. Tracked files are always reported, never touched.
    [switch] $Apply
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cli = Join-Path (Split-Path -Parent $PSScriptRoot) "baseline.ps1"

# stack marker -> the pack that covers it
$StackPacks = [ordered]@{
    "dotnet"     = @{ Globs = @("*.csproj","*.sln","*.slnx");            Packs = @("dotnet-conventions","oop-extension-safety","startup-config-validation") }
    "sql"        = @{ Globs = @("*.sql","*.dacpac");                      Packs = @("sql-server-safety") }
    "powershell" = @{ Globs = @("*.ps1","*.psm1");                        Packs = @("powershell-conventions") }
    "python"     = @{ Globs = @("*.py","pyproject.toml");                 Packs = @("python-conventions") }
    "tests"      = @{ Globs = @("*Test*.cs","*.test.ts","*.spec.ts","*_test.py"); Packs = @("testing-practices") }
}

function Resolve-Targets([string] $Spec) {
    $out = @()
    foreach ($raw in ($Spec -split ",")) {
        $s = $raw.Trim(); if (-not $s) { continue }
        if ($s -eq "." -or $s -eq "cwd") { $out += (Get-Location).Path; continue }
        if ($s.Contains("*")) { $out += (Get-ChildItem -Path $s -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }); continue }
        if (Test-Path -LiteralPath $s) { $out += (Resolve-Path -LiteralPath $s).Path }
        else { Write-Host "  (skipping, not found: $s)" }
    }
    return ($out | Select-Object -Unique)
}

function Get-Stack([string] $Repo) {
    $found = @()
    foreach ($k in $StackPacks.Keys) {
        foreach ($g in $StackPacks[$k].Globs) {
            $hit = & git -C $Repo ls-files $g "**/$g" 2>$null | Select-Object -First 1
            if ($hit) { $found += $k; break }
        }
    }
    return ($found | Select-Object -Unique)
}

function Get-InstructionFiles([string] $Repo) {
    $out = @()
    foreach ($rel in @("CLAUDE.md","AGENTS.md",".github/copilot-instructions.md")) {
        $p = Join-Path $Repo $rel
        if (-not (Test-Path -LiteralPath $p)) { continue }
        # --error-unmatch exits non-zero for an untracked path, which is a terminating error under
        # ErrorActionPreference=Stop. Ask for the listing instead and check whether it came back.
        $listed = & git -C $Repo ls-files -- $rel 2>$null
        $tracked = [bool]$listed
        $packs = [regex]::Matches((Get-Content -LiteralPath $p -Raw), "<!-- BEGIN baseline:(?<p>[A-Za-z0-9._-]+) v(?<v>[^ >]+)") |
                 ForEach-Object { [pscustomobject]@{ Pack = $_.Groups["p"].Value; Version = $_.Groups["v"].Value } }
        $out += [pscustomobject]@{ Rel = $rel; Path = $p; Tracked = $tracked; Packs = @($packs) }
    }
    return $out
}

$targets = Resolve-Targets $Repos
if ($targets.Count -eq 0) { Write-Host "no repos resolved"; exit 1 }

foreach ($repo in $targets) {
    $name = Split-Path -Leaf $repo
    Write-Host ""
    Write-Host "=== $name ==="

    if (-not (Test-Path -LiteralPath (Join-Path $repo ".git"))) { Write-Host "  not a git repo -- skipped"; continue }

    $stack = Get-Stack $repo
    $stackLabel = if ($stack) { $stack -join ", " } else { "(none detected)" }
    Write-Host "  stack:     $stackLabel"

    # what is actually reaching a session here, and from where
    $statusOut = & $cli status -TargetRepo $repo 2>&1 | Out-String
    $effective = @{}
    foreach ($line in ($statusOut -split "`r?`n")) {
        if ($line -match "^(?<pack>[A-Za-z0-9._-]+)\s+YES\s+(?<src>.+)$") { $effective[$Matches["pack"]] = $Matches["src"].Trim() }
    }

    # stack packs this repo should have, and whether it does
    $wanted = @()
    foreach ($k in $stack) { $wanted += $StackPacks[$k].Packs }
    $wanted = $wanted | Select-Object -Unique
    $missing = @($wanted | Where-Object { -not $effective.ContainsKey($_) })
    if ($missing.Count -gt 0) {
        Write-Host "  MISSING for this stack (install as a lazy user rule, covers every repo at once):"
        foreach ($m in $missing) { Write-Host "    - $m   ->  baseline apply $m -Tools claude-rule -TargetRepo `"`$HOME\.claude`"" }
    } else {
        Write-Host "  stack coverage: complete"
    }

    # Local blocks that duplicate something already inherited.
    #
    # Only CLAUDE.md can duplicate: Claude is the one tool that inherits, so a pack in a repo's
    # CLAUDE.md *and* at the user/parent tier lands in context twice. AGENTS.md and
    # copilot-instructions.md have no inheritance at all, so a local block there is the ONLY copy
    # those tools get -- correct, not redundant, and reported as such.
    #
    # The test is "status lists more than one source for the pack" (its source field is
    # semicolon-separated). Asking whether the single reported source is non-local gets this exactly
    # backwards: when a pack is installed locally AND inherited, the field starts with "local", so a
    # naive check hides every real duplicate.
    foreach ($f in (Get-InstructionFiles $repo)) {
        if ($f.Packs.Count -eq 0) { continue }
        $inherits = ($f.Rel -eq "CLAUDE.md")
        $dupes = if ($inherits) {
            @($f.Packs | Where-Object { $effective.ContainsKey($_.Pack) -and ($effective[$_.Pack] -split ";").Count -gt 1 })
        } else { @() }
        $tag = if ($f.Tracked) { "TRACKED - team file, needs a PR" } else { "untracked - local only" }
        $dupeNote = if ($inherits) { "$($dupes.Count) also inherited (in context twice)" } else { "KNOWINGLY UNMANAGED - no inheritance for this tool, so local is the only copy" }
        Write-Host ("  " + $f.Rel + ": " + $f.Packs.Count + " local block(s), " + $dupeNote + "  [" + $tag + "]")
        foreach ($d in ($dupes | Select-Object -First 4)) {
            Write-Host ("      ~ " + $d.Pack + "  ->  " + $effective[$d.Pack])
        }
        if ($dupes.Count -gt 4) { Write-Host ("      ~ ... and " + ($dupes.Count - 4) + " more") }

        if ($Apply -and $dupes.Count -gt 0) {
            if ($f.Tracked) {
                Write-Host "      -> NOT changed: tracked file. Removing team-visible blocks needs a PR."
            } elseif ($f.Rel -eq "CLAUDE.md") {
                foreach ($d in $dupes) { & $cli remove $d.Pack -Tools claude -TargetRepo $repo *>$null }
                Write-Host ("      -> removed " + $dupes.Count + " duplicate block(s) from this untracked file")
            } else {
                Write-Host "      -> left alone by design. Codex/Copilot do not inherit, so this is their only copy."
                Write-Host "         These blocks are often stale (packs at versions no longer upstream). That is a"
                Write-Host "         deliberate hold, not an oversight -- bringing them current depends on whether those"
                Write-Host "         tools are in use, and deleting them removes the only guidance they have."
            }
        }
    }
}

Write-Host ""
if (-not $Apply) { Write-Host "read-only. re-run with -Apply to remove duplicates from untracked CLAUDE.md files." }
