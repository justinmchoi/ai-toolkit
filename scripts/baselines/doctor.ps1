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
param(
    [switch] $Quiet,

    # Repos to check installed state in, beyond the user tier. Comma-separated. Accepts:
    #   .   or  cwd            the current working directory
    #   <path>\*               every immediate subdirectory (glob)
    #   an explicit path
    [string] $Repos = "",

    # Shorthand for -Repos .
    [switch] $Here,

    # Repair the unambiguous problems instead of only reporting them:
    #   stale install   -> re-apply from source (source is truth, no judgment needed)
    #   orphaned rule   -> delete the rule file (its pack no longer declares paths, so it
    #                      now loads eagerly, which is strictly worse than absent)
    # Deliberately NOT fixed: duplicate tier. Which tier should own a pack is a real decision
    # -- usually the inherited copy is newer and the local one should go, but a repo may pin an
    # older or stricter variant on purpose, and a tool that silently deletes instruction blocks
    # will eventually delete something someone meant.
    [switch] $Fix
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$problems = @()
$advisories = @()
$fixes = @()
$checked = 0

function Resolve-RepoTargets([string] $Spec, [switch] $IncludeCwd) {
    $out = @()
    if ($IncludeCwd) { $out += (Get-Location).Path }
    foreach ($raw in ($Spec -split ",")) {
        $s = $raw.Trim()
        if (-not $s) { continue }
        if ($s -eq "." -or $s -eq "cwd") { $out += (Get-Location).Path; continue }
        if ($s.Contains("*")) {
            $out += (Get-ChildItem -Path $s -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
            continue
        }
        if (Test-Path -LiteralPath $s) { $out += (Resolve-Path -LiteralPath $s).Path }
        else { Add-Problem "bad -Repos entry" "$s does not exist" }
    }
    return ($out | Select-Object -Unique)
}

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
# A presence regex proves those characters appear; it cannot tell "valid" from "so malformed
# nothing can read it", and both come back green. One unquoted `key: value` inside a value
# invalidates the WHOLE block -- name, description, scope and maintainer all unreadable, the
# skill matching on its filename alone -- and a regex-only check passes it. So: parse first,
# then check the keys against the parsed result. Added 2026-09-15 after exactly that shape had
# been live in a sibling repo for an unknown period behind two regex-only checks.
foreach ($skill in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Recurse -Filter "SKILL.md" -File)) {
    $checked++
    $text = Get-Content -LiteralPath $skill.FullName -Raw
    $name = $skill.Directory.Name

    $m = [regex]::Match($text, "(?s)\A---\r?\n(.*?)\r?\n---\r?\n")
    if (-not $m.Success) {
        Add-Problem "skill frontmatter" "${name}: no YAML frontmatter block delimited by --- ... ---"
        continue
    }

    # Parse the block properly. Each line must be `key: value`, a continuation of the previous
    # value, or a list item -- and a bare `: ` inside an unquoted scalar is what breaks real
    # parsers, so reject it here rather than matching on the key alone.
    $fields = @{}
    $lastKey = $null
    $bad = $null
    foreach ($line in ($m.Groups[1].Value -split "\r?\n")) {
        if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }
        if ($line -match '^\s+' -or $line -match '^\s*-\s') {
            if ($null -eq $lastKey) { $bad = "indented line before any key: '$line'" ; break }
            continue
        }
        $kv = [regex]::Match($line, '^([A-Za-z0-9_-]+):(?:\s(.*))?$')
        if (-not $kv.Success) { $bad = "line is not `key: value`: '$line'" ; break }
        $lastKey = $kv.Groups[1].Value
        $value = $kv.Groups[2].Value
        if ($value -and $value -notmatch '^\s*["'']' -and $value -match ':\s') {
            $bad = "unquoted value for '$lastKey' contains ': ' -- this invalidates the entire frontmatter block, not just this key"
            break
        }
        $fields[$lastKey] = $value
    }
    if ($bad) {
        Add-Problem "skill frontmatter unparseable" "${name}: $bad"
        continue
    }

    foreach ($field in @("name","description","maintainer","status")) {
        if (-not $fields.ContainsKey($field)) {
            Add-Problem "skill frontmatter" "${name}: missing '$field'"
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

# --- 5b. every canonical skill must have a project adapter under .claude/skills ------------------
# The repo is itself a Claude Code project, so .claude/skills/<name> is how a skill added here
# becomes invokable for anyone working in this clone. Nothing in the commit gate used to check it:
# six skills went adapter-less for up to seven weeks (eli5, improvement-extraction,
# project-structure, session-closeout, verification-coverage, verify-concurrent-session-changes)
# while `verify.sh` -- the one checker that did cover it -- was never wired into the gate.
Note "checking project skill adapters..."
$adapterRoot = Join-Path $repoRoot ".claude/skills"
foreach ($categoryDir in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Directory)) {
    foreach ($skillDir in (Get-ChildItem -LiteralPath $categoryDir.FullName -Directory)) {
        $checked++
        $adapter = Join-Path $adapterRoot $skillDir.Name
        $expected = "../../skills/$($categoryDir.Name)/$($skillDir.Name)"
        if (-not (Test-Path -LiteralPath $adapter)) {
            Add-Problem "missing project skill adapter" "$($skillDir.Name): no .claude/skills/$($skillDir.Name) -- the skill is not invokable from this repo"
            continue
        }
        if (Test-Path -LiteralPath $adapter -PathType Leaf) {
            $pointer = (Get-Content -LiteralPath $adapter -Raw).Trim()
            if ($pointer -ne $expected) {
                Add-Problem "wrong project skill adapter" "$($skillDir.Name): points at '$pointer', expected '$expected'"
            }
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

# --- 7. a skill must not reference files that do not exist -------------------------------------
Note "checking skill file references..."
foreach ($skill in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Recurse -Filter "SKILL.md" -File)) {
    $text = Get-Content -LiteralPath $skill.FullName -Raw
    # backticked relative paths that look like real files this skill ships or calls
    foreach ($m in [regex]::Matches($text, "``(?<p>(?:scripts|references|assets)/[A-Za-z0-9._/-]+\.(?:md|ps1|sh|py|json))``")) {
        $checked++
        $rel = $m.Groups["p"].Value
        if (-not (Test-Path -LiteralPath (Join-Path $skill.Directory.FullName $rel))) {
            Add-Problem "skill references a missing file" "$($skill.Directory.Name): $rel"
        }
    }
}

# --- 8. a flow's graph must be well formed and agree with its pack.json -------------------------
Note "checking flow graphs..."
$flowsRoot = Join-Path $repoRoot "flows"
if (Test-Path -LiteralPath $flowsRoot) {
    foreach ($flowDir in (Get-ChildItem -LiteralPath $flowsRoot -Directory)) {
        $flowMd = Join-Path $flowDir.FullName "flow.md"
        $flowJson = Join-Path $flowDir.FullName "pack.json"
        if (-not (Test-Path -LiteralPath $flowMd)) { Add-Problem "flow structure" "$($flowDir.Name): no flow.md"; continue }
        if (-not (Test-Path -LiteralPath $flowJson)) { Add-Problem "flow structure" "$($flowDir.Name): no pack.json"; continue }
        $checked++
        $meta = Get-Content -LiteralPath $flowJson -Raw | ConvertFrom-Json
        $md = Get-Content -LiteralPath $flowMd -Raw
        $mm = [regex]::Match($md, '(?s)```mermaid\s*(?<g>.*?)```')
        if (-not $mm.Success) { Add-Problem "flow graph" "$($flowDir.Name): flow.md has no mermaid block, so the graph is not the source of truth"; continue }
        $graph = $mm.Groups["g"].Value
        $edges = [regex]::Matches($graph, '(?m)^\s*(?<from>[A-Za-z_][A-Za-z0-9_]*|\[\*\])\s*-->\s*(?<to>[A-Za-z_][A-Za-z0-9_]*|\[\*\])')
        if ($edges.Count -eq 0) { Add-Problem "flow graph" "$($flowDir.Name): mermaid block declares no transitions"; continue }
        $nodes = @{}
        $targets = @{}
        foreach ($e in $edges) { $nodes[$e.Groups["from"].Value] = $true; $nodes[$e.Groups["to"].Value] = $true; $targets[$e.Groups["to"].Value] = $true }
        if ($meta.entry -and -not $nodes.ContainsKey($meta.entry)) {
            Add-Problem "flow graph" "$($flowDir.Name): pack.json entry '$($meta.entry)' is not a node in the diagram"
        }
        foreach ($term in @($meta.terminals)) {
            if (-not $targets.ContainsKey($term)) {
                Add-Problem "flow graph" "$($flowDir.Name): terminal '$term' is declared but unreachable -- no transition leads to it"
            }
        }
    }
}

# --- 9. this repo is personal: it must carry no company-identifying content ---------------------
if ((Split-Path -Leaf $repoRoot) -eq "ai-toolkit") {
    Note "checking personal-repo boundary..."
    $forbidden = @("iQmetrix","Rogers","Fido","Likewize","Cricket","Verizon","EpinServer","CarrierIntegrationServer","TradeInServer")
    $pattern = "(?i)\b(" + ($forbidden -join "|") + ")\b"
    foreach ($f in (Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Include *.md,*.json,*.txt,*.ps1,*.sh -ErrorAction SilentlyContinue)) {
        $segments = $f.FullName.Split([char]92)
        if ($segments | Where-Object { @("_Improvements",".git","node_modules","bookshelf","archives","__pycache__") -contains $_ }) { continue }
        # the checker necessarily names the terms it looks for
        if ($f.FullName -eq $PSCommandPath) { continue }
        $checked++
        $hit = [regex]::Match((Get-Content -LiteralPath $f.FullName -Raw), $pattern)
        if ($hit.Success) {
            $relPath = $f.FullName.Substring($repoRoot.Length + 1)
            Add-Problem "company content in the personal repo" "${relPath}: '$($hit.Value)'"
        }
    }
}

# --- 10. installed state: stale versions, duplicate tiers, orphaned rule files ------------------
Note "checking installed state..."
$userClaude = Join-Path $HOME ".claude/CLAUDE.md"
if (Test-Path -LiteralPath $userClaude) {
    $userText = Get-Content -LiteralPath $userClaude -Raw
    foreach ($m in [regex]::Matches($userText, "<!-- BEGIN baseline:(?<p>[A-Za-z0-9._-]+) v(?<v>[^ >]+)(?: \((?<variant>[a-z]+)\))? -->")) {
        $checked++
        $pk = $m.Groups["p"].Value
        $srcJson = Join-Path $repoRoot "baselines/$pk/pack.json"
        if (-not (Test-Path -LiteralPath $srcJson)) {
            # Owned by another toolkit -- this checker cannot judge its version, and silently
            # skipping is how a sweep reports clean on nine duplicates it never enumerated.
            # Name it instead: an absent question is now a visible one.
            $advisories += "$pk v$($m.Groups['v'].Value) is installed at the user tier but is not a pack this toolkit owns -- check the other source's own checker"
            continue
        }
        $srcVer = (Get-Content -LiteralPath $srcJson -Raw | ConvertFrom-Json).version
        if ($m.Groups["v"].Value -ne $srcVer) {
            if ($Fix) {
                $variant = if ($m.Groups["variant"].Success) { $m.Groups["variant"].Value } else { "auto" }
                & (Join-Path (Split-Path -Parent $PSScriptRoot) "baseline.ps1") apply $pk -Tools claude -Variant $variant -TargetRepo (Join-Path $HOME ".claude") *>$null
                $fixes += "re-applied $pk at the user tier (was v$($m.Groups['v'].Value), source v$srcVer, variant $variant)"
            } else {
                Add-Problem "stale install" "user tier has $pk v$($m.Groups['v'].Value) but source is v$srcVer -- re-apply (or run -Fix)"
            }
        }
    }
}
$userRules = Join-Path $HOME ".claude/rules"
if (Test-Path -LiteralPath $userRules) {
    foreach ($rf in (Get-ChildItem -LiteralPath $userRules -Filter "*.md" -File)) {
        $checked++
        $pk = [System.IO.Path]::GetFileNameWithoutExtension($rf.Name)
        $srcJson = Join-Path $repoRoot "baselines/$pk/pack.json"
        if (-not (Test-Path -LiteralPath $srcJson)) { continue }
        $meta = Get-Content -LiteralPath $srcJson -Raw | ConvertFrom-Json
        if (-not ($meta.PSObject.Properties.Name -contains "paths")) {
            if ($Fix) {
                Remove-Item -LiteralPath $rf.FullName -Force
                $fixes += "deleted $($rf.Name) (its pack no longer declares paths, so the rule loaded eagerly)"
                continue
            }
            Add-Problem "orphaned rule" "$($rf.Name): installed as a path-scoped rule but the pack no longer declares paths, so it now loads eagerly (or run -Fix)"
        }
        $ruleText = Get-Content -LiteralPath $rf.FullName -Raw
        if ($ruleText -notmatch "(?s)^---\s*\r?\npaths:") {
            Add-Problem "orphaned rule" "$($rf.Name): missing paths: frontmatter -- it loads on every turn"
        }
        # A rule file carries its own BEGIN marker, so it can go stale exactly like an always-on
        # block -- but the always-on loop above only reads ~/.claude/CLAUDE.md and never sees this
        # tier. Two path-scoped packs were bumped on 2026-09-15 and doctor reported nothing, which
        # is the "a check that cannot fail is not a check" shape in this repo's own tool.
        $rm = [regex]::Match($ruleText, "<!-- BEGIN baseline:$([regex]::Escape($pk)) v(?<v>[^ >)]+)")
        if ($rm.Success -and $rm.Groups["v"].Value -ne $meta.version) {
            if ($Fix) {
                & (Join-Path (Split-Path -Parent $PSScriptRoot) "baseline.ps1") apply $pk -Tools claude-rule -TargetRepo (Join-Path $HOME ".claude") *>$null
                $fixes += "re-applied $pk at the rule tier (was v$($rm.Groups['v'].Value), source v$($meta.version))"
            } else {
                Add-Problem "stale install" "rule tier has $pk v$($rm.Groups['v'].Value) but source is v$($meta.version) -- re-apply with -Tools claude-rule (or run -Fix)"
            }
        } elseif (-not $rm.Success) {
            Add-Problem "orphaned rule" "$($rf.Name): no BEGIN baseline:$pk marker -- its version cannot be checked, so it can never be reported stale"
        }
        # a pack installed BOTH always-on and as a rule is in context twice
        if ((Test-Path -LiteralPath $userClaude) -and ((Get-Content -LiteralPath $userClaude -Raw) -match "BEGIN baseline:$([regex]::Escape($pk)) ")) {
            Add-Problem "duplicate tier" "$pk is installed both in ~/.claude/CLAUDE.md and as a path-scoped rule -- both are in context"
        }
    }
}

# --- 11. per-repo installed state: duplicate tiers and stale local copies ----------------------
$repoTargets = Resolve-RepoTargets -Spec $Repos -IncludeCwd:$Here
if ($repoTargets.Count -gt 0) {
    Note "checking installed state in $($repoTargets.Count) repo(s)..."
    $statusScript = Join-Path (Split-Path -Parent $PSScriptRoot) "baseline.ps1"
    foreach ($repo in $repoTargets) {
        $out = & $statusScript status -TargetRepo $repo 2>&1 | Out-String
        foreach ($line in ($out -split "`r?`n")) {
            # a pack resolving from more than one layer is literally in context twice
            if ($line -match "^(?<pack>[A-Za-z0-9._-]+)\s+YES\s+(?<sources>.+)$") {
                $checked++
                $pack = $Matches["pack"]
                $srcField = $Matches["sources"]
                if (($srcField -split ";").Count -gt 1) {
                    # Two blocks in context is the finding, but not the whole finding: WHY they
                    # differ decides what to do about it. Version equality is not content
                    # equality -- two toolkits version the same pack name independently, so a
                    # name can resolve at v0.4.0 from both sources with different text in each.
                    # That case is invisible to every marker-based check, so compare content.
                    $blocks = @()
                    foreach ($src in ($srcField -split ";")) {
                        $s = $src.Trim()
                        if ($s -notmatch "^(?<tier>[a-z-]+):(?<loc>.+?)\s+v(?<ver>[0-9][0-9A-Za-z.\-]*)") { continue }
                        $loc = $Matches["loc"].Trim()
                        $ver = $Matches["ver"]
                        $tierName = $Matches["tier"]
                        # if/elseif, not switch -Wildcard: PowerShell's switch runs EVERY
                        # matching branch, so "~/.claude/CLAUDE.md" matched both "~/*" and
                        # "*.md" and the last one won, resolving it under the repo.
                        $path = $null
                        if ($loc.StartsWith("~/"))          { $path = Join-Path $HOME ($loc -replace "^~/", "") }
                        elseif ($loc -match "^[A-Za-z]:[\/]") { $path = $loc }
                        elseif ($tierName -eq "user-rule")  { $path = Join-Path $HOME ".claude/rules/$loc" }
                        elseif ($loc -match "\.md$")        { $path = Join-Path $repo $loc }
                        $text = $null
                        if ($path -and (Test-Path -LiteralPath $path)) {
                            $all = Get-Content -LiteralPath $path -Raw
                            $m = [regex]::Match($all, "<!-- BEGIN baseline:$([regex]::Escape($pack)) v.*?<!-- END baseline:$([regex]::Escape($pack)) -->", "Singleline")
                            if ($m.Success) {
                                # normalise the marker itself out, so only the principle text compares
                                $text = ($m.Value -replace "<!-- BEGIN baseline:[^>]*-->", "") -replace "\s+", " "
                            }
                        }
                        $blocks += [pscustomobject]@{ Tier = $loc; Version = $ver; Text = $text }
                    }
                    $versions = @($blocks.Version | Select-Object -Unique)
                    $texts    = @($blocks | Where-Object { $_.Text } | ForEach-Object { $_.Text } | Select-Object -Unique)
                    $detail = if ($versions.Count -gt 1) {
                        $pairs = ($blocks | ForEach-Object { "$($_.Tier) v$($_.Version)" }) -join " vs "
                        "stale copy -- $pairs; the older text is in context alongside the newer"
                    } elseif ($texts.Count -gt 1) {
                        "CONFLICT -- both say v$($versions[0]) and their content DIFFERS, so no version check can see this; diff them"
                    } else {
                        "redundant -- same version and identical text, so this costs context only"
                    }
                    Add-Problem "duplicate tier" "$(Split-Path -Leaf $repo): $pack resolves from more than one layer -- $detail"
                }
            }
        }
    }
}

# --- 12. ADVISORY: a loop that was never captured as a flow ------------------------------------
# Not a failure -- whether something deserves a flow is a judgment call. But a skill that both
# loops AND names another skill is the shape a flow is for, and those are exactly the ones that
# stay invisible because nothing lists them.
Note "looking for uncaptured loops..."
$flowMembers = @{}
$flowsDir = Join-Path $repoRoot "flows"
if (Test-Path -LiteralPath $flowsDir) {
    foreach ($fj in (Get-ChildItem -LiteralPath $flowsDir -Recurse -Filter "pack.json" -File)) {
        foreach ($s in @((Get-Content -LiteralPath $fj.FullName -Raw | ConvertFrom-Json).skills)) { $flowMembers[$s] = $true }
    }
}
$allSkillNames = @{}
foreach ($sk in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Recurse -Filter "SKILL.md" -File)) {
    $allSkillNames[$sk.Directory.Name] = $true
}
foreach ($sk in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Recurse -Filter "SKILL.md" -File)) {
    $me = $sk.Directory.Name
    if ($flowMembers.ContainsKey($me)) { continue }
    $body = Get-Content -LiteralPath $sk.FullName -Raw
    $loops = [regex]::IsMatch($body, "(?i)\b(until (zero|no more|it|the|every|all)|re-?run|repeat until|loop back|iterate until|retry)\b")
    if (-not $loops) { continue }
    $named = @($allSkillNames.Keys | Where-Object { $_ -ne $me -and $body -match "\b$([regex]::Escape($_))\b" })
    if ($named.Count -gt 0) {
        $advisories += "$me loops and names other skills ($($named -join ', ')) but belongs to no flow"
    }
}

# --- 13. every preset entry must resolve to something that exists ------------------------------
# A preset naming a pack that was renamed or removed fails only at apply-preset time, on someone
# else's machine. Deleting 15 packs from the sibling toolkit left its preset pointing at 12 that
# no longer existed, and nothing caught it.
Note "checking presets..."
$presetsDir = Join-Path $repoRoot "presets"
if (Test-Path -LiteralPath $presetsDir) {
    foreach ($preset in (Get-ChildItem -LiteralPath $presetsDir -Filter "*.txt" -File)) {
        $section = "baselines"
        foreach ($rawLine in (Get-Content -LiteralPath $preset.FullName)) {
            $line = $rawLine.Trim()
            if (-not $line -or $line.StartsWith("#")) { continue }
            if ($line.StartsWith("[") -and $line.EndsWith("]")) {
                $section = $line.Trim("[", "]")
                if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $section))) {
                    Add-Problem "preset" "$($preset.Name): section [$section] is not a domain in this repo"
                }
                continue
            }
            $checked++
            if (-not (Test-Path -LiteralPath (Join-Path $repoRoot (Join-Path $section $line)))) {
                Add-Problem "preset" "$($preset.Name): '$line' does not exist under $section/ -- apply-preset would fail"
            }
        }
    }
}

# --- 14. a retired domain name must not come back -----------------------------------------------
# `workflows/` was a planned tree for years and shipped as `flows/`. Two directories for one concept
# is how a codebase ends up with a lagging duplicate, so the decision is enforced rather than
# recorded: if someone (or some future session) creates workflows/, this fails and points at flows/.
Note "checking retired domain names..."
$checked++
if (Test-Path -LiteralPath (Join-Path $repoRoot "workflows")) {
    Add-Problem "retired domain name" "workflows/ exists -- that concept shipped as flows/. Move its contents there and delete it; two trees for one concept is how a lagging duplicate starts."
}

# --- report -------------------------------------------------------------------------------------
Write-Host ""
function Write-Fixes {
    if ($fixes.Count -eq 0) { return }
    Write-Host ""
    Write-Host "  repaired"
    foreach ($f in $fixes) { Write-Host ("    + " + $f) }
}

function Write-Advisories {
    if ($advisories.Count -eq 0) { return }
    Write-Host ""
    Write-Host "  advisories (judgment calls, not failures)"
    foreach ($a in $advisories) { Write-Host ("    ~ " + $a) }
}

if ($problems.Count -eq 0) {
    Write-Host "doctor: $checked invariants checked, no drift found"
    Write-Fixes
    Write-Advisories
    exit 0
}
Write-Host "doctor: $checked invariants checked, $($problems.Count) problem(s)"
foreach ($group in ($problems | Group-Object Invariant | Sort-Object Name)) {
    Write-Host ""
    Write-Host ("  " + $group.Name)
    foreach ($p in $group.Group) { Write-Host ("    - " + $p.Detail) }
}
Write-Fixes
Write-Advisories
Write-Host ""
exit 1
