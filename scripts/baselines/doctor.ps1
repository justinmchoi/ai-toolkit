<#
.SYNOPSIS
    Check every known drift invariant in this toolkit. Exits non-zero if any is violated.

.DESCRIPTION
    Drift is what happens when one fact has two representations and nothing forces them equal.
    Every drift this toolkit has actually suffered has that shape:

      pack.json version   vs  baseline.md Version   vs  adapter markers
      the three full adapters                       vs  each other
      the core adapter                              vs  pack.json
      a skill in a toolkit                          vs  its installed copy
      a domain that exists on disk                  vs  the docs that list domains
      apply's supported targets                     vs  remove's

    Each is stated below as an invariant and checked. The point is not that these are the only
    possible drifts -- it is that a drift, once found, becomes a permanent check here rather than
    a lesson someone has to remember.
#>
[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$problems = @()
$checked = 0

function Add-Problem($Invariant, $Detail) { $script:problems += [pscustomobject]@{ Invariant = $Invariant; Detail = $Detail } }
function Note($Text) { if (-not $Quiet) { Write-Host $Text } }

# --- 1. a pack's version is stated in four places and they must agree ---------------------------
Note "checking pack version coherence..."
foreach ($packDir in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "baselines") -Directory)) {
    $name = $packDir.Name
    $packJson = Join-Path $packDir.FullName "pack.json"
    $baselineMd = Join-Path $packDir.FullName "baseline.md"
    if (-not (Test-Path -LiteralPath $packJson)) { Add-Problem "pack structure" "${name}: no pack.json"; continue }
    $checked++
    $version = (Get-Content -LiteralPath $packJson -Raw | ConvertFrom-Json).version

    if (Test-Path -LiteralPath $baselineMd) {
        $m = [regex]::Match((Get-Content -LiteralPath $baselineMd -Raw), "(?m)^Version:\s*(?<v>\S+)")
        if (-not $m.Success) { Add-Problem "version coherence" "${name}: baseline.md has no 'Version:' line" }
        elseif ($m.Groups["v"].Value -ne $version) { Add-Problem "version coherence" "${name}: baseline.md v$($m.Groups['v'].Value) != pack.json v$version" }
    }

    $escaped = [regex]::Escape($name)
    foreach ($adapter in (Get-ChildItem -LiteralPath (Join-Path $packDir.FullName "adapters") -Filter "*.block" -ErrorAction SilentlyContinue)) {
        $am = [regex]::Match((Get-Content -LiteralPath $adapter.FullName -Raw), "<!-- BEGIN baseline:$escaped v(?<v>[^ >]+)(?: \((?<variant>[a-z]+)\))? -->")
        if (-not $am.Success) { Add-Problem "adapter marker" "$name/$($adapter.Name): no recognisable BEGIN marker"; continue }
        if ($am.Groups["v"].Value -ne $version) { Add-Problem "version coherence" "$name/$($adapter.Name): marker v$($am.Groups['v'].Value) != pack.json v$version" }
        $isCoreFile = $adapter.Name -like "*.core.block"
        $isCoreMarker = $am.Groups["variant"].Value -eq "core"
        if ($isCoreFile -and -not $isCoreMarker) { Add-Problem "core tagging" "$name/$($adapter.Name): core adapter is not tagged (core); apply cannot tell it from the full block" }
        if ((-not $isCoreFile) -and $isCoreMarker) { Add-Problem "core tagging" "$name/$($adapter.Name): full adapter is tagged (core)" }
    }

    # the three full adapters are maintained as one edit copied three ways
    $trio = @("CLAUDE.md.block","AGENTS.md.block","copilot-instructions.md.block") |
        ForEach-Object { Join-Path $packDir.FullName "adapters/$_" } | Where-Object { Test-Path -LiteralPath $_ }
    if ($trio.Count -eq 3) {
        # .NET rather than Get-FileHash: the cmdlet is not present in every host this runs in.
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $hashes = $trio | ForEach-Object { [BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($_))) }
        if (($hashes | Select-Object -Unique).Count -ne 1) {
            Add-Problem "adapter parity" "${name}: the three full adapters are not identical (they have been byte-identical by convention)"
        }
    }
}

# --- 2. a pack declaring path globs must be installable as a rule -------------------------------
Note "checking rule-capable packs..."
foreach ($packDir in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "baselines") -Directory)) {
    $packJson = Join-Path $packDir.FullName "pack.json"
    if (-not (Test-Path -LiteralPath $packJson)) { continue }
    $meta = Get-Content -LiteralPath $packJson -Raw | ConvertFrom-Json
    if ($meta.PSObject.Properties.Name -contains "paths") {
        $checked++
        if (-not (Test-Path -LiteralPath (Join-Path $packDir.FullName "adapters/CLAUDE.md.block"))) {
            Add-Problem "rule pack" "$($packDir.Name): declares paths but has no CLAUDE.md.block to install as a rule"
        }
    }
}

# --- 3. apply and remove must agree on which targets exist --------------------------------------
Note "checking apply/remove target parity..."
$checked++
$applyText = Get-Content -LiteralPath (Join-Path $PSScriptRoot "apply.ps1") -Raw
$removeText = Get-Content -LiteralPath (Join-Path $PSScriptRoot "remove.ps1") -Raw
foreach ($tool in @("codex","claude","copilot","claude-rule")) {
    $inApply = $applyText -match [regex]::Escape($tool)
    $inRemove = $removeText -match [regex]::Escape($tool)
    if ($inApply -and -not $inRemove) { Add-Problem "apply/remove parity" "'$tool' is a target in apply.ps1 but not remove.ps1 -- it could be installed and never cleaned up" }
}

# --- 4. every skill carries the frontmatter the team CI requires --------------------------------
Note "checking skill frontmatter..."
foreach ($skill in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Recurse -Filter "SKILL.md" -File)) {
    $checked++
    $text = Get-Content -LiteralPath $skill.FullName -Raw
    foreach ($field in @("name","description","maintainer","status")) {
        if ($text -notmatch "(?m)^${field}:") {
            Add-Problem "skill frontmatter" "$($skill.Directory.Name): missing '$field'"
        }
    }
}

# --- 5. an installed skill must be a link, never a copy -----------------------------------------
Note "checking installed skill links..."
$installRoot = Join-Path $HOME ".claude/skills"
if (Test-Path -LiteralPath $installRoot) {
    foreach ($entry in (Get-ChildItem -LiteralPath $installRoot -Directory -Force)) {
        $checked++
        $item = Get-Item -LiteralPath $entry.FullName -Force
        if (-not $item.LinkType) {
            Add-Problem "installed skill is a copy" "$($entry.Name): a real directory, so edits on either side drift silently and a reinstall destroys them"
        }
    }
}

# --- 6. a domain that exists on disk must be listed in the docs that enumerate domains ----------
Note "checking domain documentation..."
$domainDocs = @("README.md","CLAUDE.md","AGENTS.md","CONTEXT.md") |
    ForEach-Object { Join-Path $repoRoot $_ } | Where-Object { Test-Path -LiteralPath $_ }
$docText = ($domainDocs | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
foreach ($domain in @("baselines","skills","hooks","flows","Glossary","presets")) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $domain))) { continue }
    $checked++
    # match the domain as a path token so "flows/" does not match "workflows/"
    if ($docText -notmatch "(?<![A-Za-z-])$([regex]::Escape($domain))/") {
        Add-Problem "undocumented domain" "$domain/ exists on disk but no top-level doc lists it"
    }
}

# --- report -------------------------------------------------------------------------------------
Write-Host ""
if ($problems.Count -eq 0) {
    Write-Host "doctor: $checked invariants checked, no drift found"
    exit 0
}
Write-Host "doctor: $checked invariants checked, $($problems.Count) problem(s)"
foreach ($group in ($problems | Group-Object Invariant | Sort-Object Name)) {
    Write-Host ""
    Write-Host ("  " + $group.Name)
    foreach ($p in $group.Group) { Write-Host ("    - " + $p.Detail) }
}
Write-Host ""
exit 1
