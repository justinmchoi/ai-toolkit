param(
    [Parameter(Position = 0)]
    [string] $Command = "list",

    [Parameter(Position = 1)]
    [string] $Name = "",

    [string] $TargetRepo = (Get-Location).Path,

    [string] $Pack = "",

    [string[]] $Tools = @("all"),

    # For 'status': comma-separated repo paths, for the multi-repo dashboard view.
    [string] $Repos = "",

    # For 'status': path to a text file listing one repo path per line (# comments, blank lines ignored).
    [string] $ReposFile = "",

    # For 'status': filter the pack table down to one preset's packs instead of every pack.
    [string] $Preset = "",

    # Which rendering of a pack to install. auto keeps whatever is already there.
    [ValidateSet("auto", "core", "full")]
    [string] $Variant = "auto",

    # For 'doctor': shorthand for -Repos . (the current working directory).
    [switch] $Here,

    # For 'doctor': suppress per-check progress lines.
    [switch] $Quiet,

    # For 'audit': act on the safe parts instead of only reporting.
    [switch] $Apply,

    [switch] $CreateMissing,

    [switch] $SkipMissing,

    [switch] $DryRun,

    [string] $InstallDir = "",

    [string] $ShimAction = "",

    [switch] $AddToUserPath
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$baselinesRoot = Join-Path $repoRoot "baselines"
$targetRepoWasProvided = $PSBoundParameters.ContainsKey("TargetRepo")
$toolsWereProvided = $PSBoundParameters.ContainsKey("Tools")

function Show-Usage {
    Write-Output @"
Usage:
  baseline list
  baseline show [pack|all]
  baseline apply <pack|all> [-Tools codex,claude,copilot|all] [-TargetRepo <path>] [-DryRun] [-SkipMissing]
  baseline remove <pack|all> [-Tools codex,claude,copilot|all] [-TargetRepo <path>] [-DryRun]
  baseline verify [pack|all] [-Tools codex,claude,copilot|all] [-TargetRepo <path>]
  baseline apply-all [-Tools codex,claude,copilot|all] [-TargetRepo <path>] [-DryRun] [-SkipMissing]
  baseline apply-preset <preset-name> [-Tools codex,claude,copilot|all] [-TargetRepo <path>] [-DryRun] [-SkipMissing]
  baseline presets
  baseline status [-TargetRepo <path>]
  baseline status -Preset <preset-name>
  baseline status -Repos <path1,path2,...>
  baseline status -ReposFile <path-to-txt-listing-one-repo-per-line>
  baseline shim install|verify|remove [-AddToUserPath] [-InstallDir <path>]
  baseline help

Compatibility:
  -Pack and -Tools are still supported.
  -Variant auto|core|full selects a pack's rendering; auto (default) preserves
  whatever is already installed, so apply never silently swaps core for full.
  -Tools claude-rule writes the full rendering to .claude/rules/<pack>.md with
  paths: frontmatter from pack.json, so it loads only when a matching file is read.

  doctor [-Repos <list>] [-Here] [-Quiet]
    Checks every drift invariant and exits non-zero on any. -Repos also sweeps
    installed state in other repos; entries may be a path, a glob ending in *,
    or "." / "cwd" for the current directory. -Here is shorthand for -Repos .
  -Pack accepts a comma-separated list of pack names, or 'all'.
  When -Tools is omitted, commands use all supported tools: codex, claude, copilot.
  Missing target instruction files are created unless -SkipMissing is passed.
  -CreateMissing is still accepted for older scripts, but is no longer needed.

status accounts for how Claude Code actually resolves instructions: repo-local
files, every parent directory up to the filesystem root, and user-level
~/.claude/CLAUDE.md / ~/.claude/rules/. A pack applied only at the user level
shows as in effect even where it was never locally applied. Codex (AGENTS.md)
and Copilot have no documented equivalent inheritance model, so those two are
reported as local-file-only.
"@
}

function Write-FriendlyError($Message) {
    [Console]::Error.WriteLine("baseline: $Message")

    if ($Message -like "Unknown portable baseline pack:*") {
        [Console]::Error.WriteLine("Suggestion: run 'baseline list' to see available packs.")
    } elseif ($Message -like "Multiple portable baseline packs are available:*") {
        [Console]::Error.WriteLine("Suggestion: pass a pack name, for example 'baseline show karpathy-principles'.")
    } elseif ($Message -like "Unsupported tool*") {
        [Console]::Error.WriteLine("Suggestion: use -Tools codex,claude,copilot or -Tools all.")
    } elseif ($Message -like "Both baseline and legacy portable-agent-baseline blocks exist*") {
        [Console]::Error.WriteLine("Suggestion: remove one duplicate managed block manually, then rerun the command.")
    } elseif ($Message -like "Preset not found:*") {
        [Console]::Error.WriteLine("Suggestion: run 'baseline list' or check presets/ for available preset files.")
    } elseif ($Message -like "Unknown command:*") {
        [Console]::Error.WriteLine("Suggestion: run 'baseline help'.")
    } elseif ($Message -like "Unknown shim action:*") {
        [Console]::Error.WriteLine("Suggestion: use 'baseline shim install', 'baseline shim verify', or 'baseline shim remove'.")
    } elseif ($Message -like "Choose either -SkipMissing or -CreateMissing*") {
        [Console]::Error.WriteLine("Suggestion: omit both to create missing instruction files, or pass -SkipMissing to leave them absent.")
    } elseif ($Message -like "Repos file not found:*") {
        [Console]::Error.WriteLine("Suggestion: pass -ReposFile with a path to a text file listing one repo path per line.")
    }
}

function Invoke-BaselineCommand {
    if ($Command -eq "apply-all") {
        $Command = "apply"
        if (-not $Pack) {
            $script:Pack = "all"
        }
    }

    $validCommands = @("list", "show", "apply", "remove", "verify", "apply-preset", "presets", "status", "shim", "doctor", "audit", "help", "--help", "-h")
    if ($validCommands -notcontains $Command) {
        throw "Unknown command: $Command"
    }

    if (@("help", "--help", "-h") -contains $Command) {
        Show-Usage
        return
    }

    if ($SkipMissing -and $CreateMissing) {
        throw "Choose either -SkipMissing or -CreateMissing, not both."
    }

    if (@("show", "apply", "remove", "verify") -contains $Command) {
        if ($Name -and -not $Pack) {
            $script:Pack = $Name
        }
    }

    if ($Command -eq "audit") {
        if (-not $Repos -and -not $Here) { throw "audit needs -Repos <path|glob|.> (or -Here)" }
        $spec = if ($Here) { "." } else { $Repos }
        & (Join-Path $scriptDir "baselines/audit.ps1") -Repos $spec -Apply:$Apply
        return
    }

    if ($Command -eq "doctor") {
        & (Join-Path $scriptDir "baselines/doctor.ps1") -Repos $Repos -Here:$Here -Quiet:$Quiet
        return
    }

    if ($Command -eq "shim") {
        if ($Name) {
            $script:ShimAction = $Name
        } elseif (-not $ShimAction) {
            $script:ShimAction = "install"
        }
    }

function Read-Utf8Text($Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-PackRoot($Name) {
    return Join-Path $baselinesRoot $Name
}

function Read-PackJson($Name) {
    $packPath = Join-Path (Get-PackRoot $Name) "pack.json"
    if (-not (Test-Path -LiteralPath $packPath)) {
        throw "Unknown portable baseline pack: $Name"
    }
    return (Read-Utf8Text $packPath | ConvertFrom-Json)
}

function Get-PackNames {
    if (-not (Test-Path -LiteralPath $baselinesRoot)) {
        throw "Missing baselines directory: $baselinesRoot"
    }

    return @(Get-ChildItem -LiteralPath $baselinesRoot -Directory | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.FullName "pack.json")
    } | ForEach-Object {
        $_.Name
    })
}

function Resolve-PackNames($Name) {
    if ($Name) {
        if ($Name -eq "all") {
            return @(Get-PackNames)
        }

        $requested = @($Name -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        foreach ($p in $requested) {
            $null = Read-PackJson $p
        }
        return $requested
    }

    $packNames = @(Get-PackNames)
    if ($packNames.Count -eq 0) {
        throw "No portable baseline packs found in: $baselinesRoot"
    }
    if ($packNames.Count -eq 1) {
        return @($packNames[0])
    }

    throw "Multiple portable baseline packs are available: $($packNames -join ', '). Pass -Pack <name>, a comma-separated list, or 'all'."
}

function Normalize-Tools($ToolValues) {
    # "all" deliberately excludes claude-rule: a path-scoped rule is only correct for packs that
    # declare globs, so it has to be asked for by name rather than swept in.
    $allTools = @("codex", "claude", "copilot")
    $namedOnlyTools = @("claude-rule")
    $normalized = @()
    foreach ($toolValue in $ToolValues) {
        foreach ($tool in ($toolValue -split ",")) {
            $trimmed = $tool.Trim()
            if (-not $trimmed) {
                continue
            }

            if ($trimmed -eq "all") {
                foreach ($toolName in $allTools) {
                    if ($normalized -notcontains $toolName) {
                        $normalized += $toolName
                    }
                }
                continue
            }

            if (($allTools -notcontains $trimmed) -and ($namedOnlyTools -notcontains $trimmed)) {
                throw "Unsupported tool '$trimmed'. Supported tools: $(($allTools + $namedOnlyTools) -join ', '), all"
            }

            if ($normalized -notcontains $trimmed) {
                $normalized += $trimmed
            }
        }
    }

    return $normalized
}

function Get-ToolMap {
    return @{
        claude = "CLAUDE.md"
        codex = "AGENTS.md"
        copilot = ".github/copilot-instructions.md"
    }
}

function Test-BaselineInstalled($ResolvedTargetRepo, $PackName, $ToolName) {
    $toolMap = Get-ToolMap
    if (-not $toolMap.ContainsKey($ToolName)) {
        return $false
    }

    $targetPath = Join-Path $ResolvedTargetRepo $toolMap[$ToolName]
    if (-not (Test-Path -LiteralPath $targetPath)) {
        return $false
    }

    $text = Read-Utf8Text $targetPath
    $escapedPack = [regex]::Escape($PackName)
    return (
        [regex]::IsMatch($text, "<!-- BEGIN baseline:$escapedPack v[^>]+ -->") -or
        [regex]::IsMatch($text, "<!-- BEGIN portable-agent-baseline:$escapedPack v[^>]+ -->")
    )
}

function Format-StatusCell($ToolName, $Installed) {
    $marker = if ($Installed) { "+" } else { " " }
    return ("[{0} {1}]" -f $ToolName, $marker)
}

# -- Status: inheritance-aware visibility -------------------------------------
#
# Claude Code concatenates instruction files rather than overriding them:
# user-level (~/.claude/CLAUDE.md, ~/.claude/rules/*.md) applies to every
# project; it also walks every parent directory from the target repo up to
# the filesystem root looking for CLAUDE.md / CLAUDE.local.md. A pack can be
# "in effect" for a repo without being applied to that repo's own files.
# Codex (AGENTS.md) and Copilot's instructions file have no documented
# equivalent, so those two are reported as local-file-only, not inheritance-aware.

function Get-BlockVersionInFile($FilePath, $PackName) {
    if (-not (Test-Path -LiteralPath $FilePath)) { return $null }
    $text = Read-Utf8Text $FilePath
    $escapedPack = [regex]::Escape($PackName)
    foreach ($marker in @("baseline", "portable-agent-baseline")) {
        # Variant suffix is optional: "v1.2.3 -->" is the historical (full) form,
        # "v1.2.3 (core) -->" marks a slim always-on rendering. Report it alongside the
        # version so `status` can distinguish a core install from a full one.
        $m = [regex]::Match($text, "<!-- BEGIN ${marker}:${escapedPack} v(?<v>[^ >]+)(?: \((?<variant>[a-z]+)\))? -->")
        if ($m.Success) {
            if ($m.Groups["variant"].Success) { return "$($m.Groups['v'].Value) ($($m.Groups['variant'].Value))" }
            return $m.Groups["v"].Value
        }
    }
    return $null
}

function Get-ParentDirs($StartPath) {
    $dirs = @()
    $current = Split-Path -Parent $StartPath
    while ($current) {
        $dirs += $current
        $parent = Split-Path -Parent $current
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
    return $dirs
}

function New-ClaudeSource($Location, $FilePath, $Version) {
    return [PSCustomObject]@{ Location = $Location; File = $FilePath; Version = $Version }
}

function Get-ClaudeSources($RepoPath, $PackName) {
    $sources = @()

    foreach ($rel in @("CLAUDE.md", "CLAUDE.local.md", (Join-Path ".claude" "CLAUDE.md"))) {
        $ver = Get-BlockVersionInFile (Join-Path $RepoPath $rel) $PackName
        if ($ver) { $sources += New-ClaudeSource "local" $rel $ver }
    }

    $projectRulesDir = Join-Path $RepoPath (Join-Path ".claude" "rules")
    if (Test-Path -LiteralPath $projectRulesDir) {
        $ruleFiles = Get-ChildItem -LiteralPath $projectRulesDir -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($rf in $ruleFiles) {
            $ver = Get-BlockVersionInFile $rf.FullName $PackName
            if ($ver) { $sources += New-ClaudeSource "local-rule" $rf.Name $ver }
        }
    }

    foreach ($dir in (Get-ParentDirs $RepoPath)) {
        foreach ($rel in @("CLAUDE.md", "CLAUDE.local.md")) {
            $ver = Get-BlockVersionInFile (Join-Path $dir $rel) $PackName
            if ($ver) { $sources += New-ClaudeSource "parent" "$dir/$rel" $ver }
        }
    }

    if ($HOME) {
        $userClaudeFile = Join-Path (Join-Path $HOME ".claude") "CLAUDE.md"
        $ver = Get-BlockVersionInFile $userClaudeFile $PackName
        if ($ver) { $sources += New-ClaudeSource "user" "~/.claude/CLAUDE.md" $ver }

        $userRulesDir = Join-Path (Join-Path $HOME ".claude") "rules"
        if (Test-Path -LiteralPath $userRulesDir) {
            $ruleFiles = Get-ChildItem -LiteralPath $userRulesDir -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue
            foreach ($rf in $ruleFiles) {
                $ver = Get-BlockVersionInFile $rf.FullName $PackName
                if ($ver) { $sources += New-ClaudeSource "user-rule" $rf.Name $ver }
            }
        }
    }

    return $sources
}

function Format-SourceDetail($Sources) {
    if ($Sources.Count -eq 0) { return "-" }
    $parts = $Sources | ForEach-Object { "$($_.Location):$($_.File) v$($_.Version)" }
    return ($parts -join "; ")
}

function Format-SourceCompact($Sources) {
    if ($Sources.Count -eq 0) { return "-" }
    $parts = $Sources | ForEach-Object { "$($_.Version) ($($_.Location))" }
    return ($parts -join ", ")
}

function Resolve-RepoPath($RepoPath) {
    try { return (Resolve-Path -LiteralPath $RepoPath).Path } catch { return $RepoPath }
}

function Get-AvailablePresetNames {
    $presetsRoot = Join-Path $repoRoot "presets"
    if (-not (Test-Path -LiteralPath $presetsRoot)) { return @() }
    return @(Get-ChildItem -LiteralPath $presetsRoot -Filter "*.txt" -ErrorAction SilentlyContinue |
        ForEach-Object { $_.BaseName } | Sort-Object)
}

function Get-PresetContents($Name) {
    if (-not $Name) {
        throw "Usage: baseline apply-preset <preset-name> [-Tools ...] [-TargetRepo <path>] [-DryRun] [-SkipMissing]"
    }
    $presetsRoot = Join-Path $repoRoot "presets"
    $presetFile = Join-Path $presetsRoot "$Name.txt"
    if (-not (Test-Path -LiteralPath $presetFile)) {
        $available = @(Get-AvailablePresetNames)
        $availableMsg = if ($available.Count -gt 0) { "; available: $($available -join ', ')" } else { "" }
        throw "Preset not found: $Name$availableMsg"
    }
    $presetBaselines = [System.Collections.Generic.List[string]]::new()
    $presetHooks = [System.Collections.Generic.List[string]]::new()
    $inHooks = $false
    foreach ($line in [System.IO.File]::ReadAllLines($presetFile, [System.Text.Encoding]::UTF8)) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -eq '[hooks]') { $inHooks = $true; continue }
        if ($inHooks) { $presetHooks.Add($trimmed) } else { $presetBaselines.Add($trimmed) }
    }
    return [PSCustomObject]@{ Baselines = @($presetBaselines); Hooks = @($presetHooks) }
}

function Invoke-PresetsList {
    $presetNames = @(Get-AvailablePresetNames)
    if (-not $presetNames) {
        Write-Output "No presets found in $(Join-Path $repoRoot 'presets')"
        return
    }

    Write-Output ""
    Write-Output "Available presets"
    Write-Output ""
    foreach ($presetName in $presetNames) {
        $contents = Get-PresetContents $presetName
        Write-Output "$presetName  ($($contents.Baselines.Count) packs)"
        foreach ($pack in $contents.Baselines) {
            $version = "?"
            $note = ""
            try { $version = (Read-PackJson $pack).version } catch { $note = "  [pack not found - preset needs updating]" }
            Write-Output ("  {0,-38} v{1}{2}" -f $pack, $version, $note)
        }
        if ($contents.Hooks.Count -gt 0) {
            Write-Output "  Hooks:"
            foreach ($hook in $contents.Hooks) { Write-Output "    $hook" }
        }
        Write-Output ""
    }
}

function Invoke-Status {
    $packs = Get-PackNames
    if ($Preset) { $packs = (Get-PresetContents $Preset).Baselines }
    if (-not $packs) { Write-Output "No packs found in $baselinesRoot"; return }

    $resolvedTarget = Resolve-RepoPath $TargetRepo

    $titleSuffix = ""
    if ($Preset) { $titleSuffix = " (preset: $Preset)" }
    Write-Output ""
    Write-Output "Claude Code status for $resolvedTarget$titleSuffix"
    Write-Output "(effective = concatenated across all layers; Claude combines rather than overrides)"
    Write-Output "Multiple sources for one pack = active at more than one layer at once - Claude has no"
    Write-Output "'most specific wins' rule, both blocks are literally in context; worth reconciling if they differ."
    Write-Output ""
    Write-Output ("{0,-38} {1,-9} {2}" -f "Pack", "Effective", "Sources")
    Write-Output ("{0,-38} {1,-9} {2}" -f ("-" * 38), ("-" * 9), ("-" * 40))
    foreach ($pack in $packs) {
        $sources = @(Get-ClaudeSources $resolvedTarget $pack)
        $effective = "NO"
        if ($sources.Count -gt 0) { $effective = "YES" }
        $sourceText = Format-SourceDetail $sources
        Write-Output ("{0,-38} {1,-9} {2}" -f $pack, $effective, $sourceText)
    }

    Write-Output ""
    Write-Output "Codex (AGENTS.md) - local file only, no documented inheritance model"
    foreach ($pack in $packs) {
        $ver = Get-BlockVersionInFile (Join-Path $resolvedTarget "AGENTS.md") $pack
        $mark = "NO"
        if ($ver) { $mark = "YES (v$ver)" }
        Write-Output ("  {0,-38} {1}" -f $pack, $mark)
    }

    Write-Output ""
    Write-Output "Copilot (.github/copilot-instructions.md) - local file only, no documented inheritance model"
    foreach ($pack in $packs) {
        $ver = Get-BlockVersionInFile (Join-Path $resolvedTarget ".github/copilot-instructions.md") $pack
        $mark = "NO"
        if ($ver) { $mark = "YES (v$ver)" }
        Write-Output ("  {0,-38} {1}" -f $pack, $mark)
    }
    Write-Output ""
}

function Get-RepoListFromParams($ReposParam, $ReposFileParam) {
    $list = @()
    if ($ReposParam) {
        $list += @($ReposParam -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    if ($ReposFileParam) {
        if (-not (Test-Path -LiteralPath $ReposFileParam)) { throw "Repos file not found: $ReposFileParam" }
        foreach ($line in [System.IO.File]::ReadAllLines($ReposFileParam, [System.Text.Encoding]::UTF8)) {
            $trimmed = $line.Trim()
            if (-not $trimmed -or $trimmed.StartsWith("#")) { continue }
            $list += $trimmed
        }
    }
    return $list
}

function Invoke-StatusMulti($RepoPaths) {
    $packs = Get-PackNames
    if ($Preset) { $packs = (Get-PresetContents $Preset).Baselines }
    if (-not $packs) { Write-Output "No packs found in $baselinesRoot"; return }

    $resolved = @()
    foreach ($r in $RepoPaths) { $resolved += Resolve-RepoPath $r }

    # Precompute every cell (avoids re-scanning the filesystem when sizing columns)
    # and track each column's widest cell so nothing gets truncated.
    $cellText = @{}
    $colWidth = @{}
    foreach ($rp in $resolved) {
        $colWidth[$rp] = (Split-Path -Leaf $rp).Length
    }
    foreach ($pack in $packs) {
        foreach ($rp in $resolved) {
            $sources = @(Get-ClaudeSources $rp $pack)
            $text = Format-SourceCompact $sources
            $cellText["$pack|$rp"] = $text
            if ($text.Length -gt $colWidth[$rp]) { $colWidth[$rp] = $text.Length }
        }
    }

    $nameWidth = 38
    foreach ($pack in $packs) { if ($pack.Length -gt $nameWidth) { $nameWidth = $pack.Length } }
    $nameWidth += 2

    $titleSuffix = ""
    if ($Preset) { $titleSuffix = " (preset: $Preset)" }
    Write-Output ""
    Write-Output "Claude Code status across $($resolved.Count) repo(s)$titleSuffix"
    Write-Output "'-' = not active. Otherwise: version (layer), e.g. '0.4.1 (local)'."
    Write-Output "layer: local (repo's own files) / local-rule (.claude/rules) / parent (an ancestor"
    Write-Output "directory's CLAUDE.md) / user (~/.claude/CLAUDE.md) / user-rule (~/.claude/rules)."
    Write-Output "Multiple entries in one cell = active at more than one layer at once - Claude"
    Write-Output "concatenates all of them, there is no 'most specific wins'; worth reconciling if they differ."
    Write-Output "Run 'baseline status -TargetRepo <path>' on one repo for the full file-path breakdown."
    Write-Output ""

    $header = "{0,-$nameWidth}" -f "Pack"
    foreach ($rp in $resolved) {
        $label = Split-Path -Leaf $rp
        $w = $colWidth[$rp] + 2
        $header += (" {0,-$w}" -f $label)
    }
    Write-Output $header

    foreach ($pack in $packs) {
        $row = "{0,-$nameWidth}" -f $pack
        foreach ($rp in $resolved) {
            $w = $colWidth[$rp] + 2
            $row += (" {0,-$w}" -f $cellText["$pack|$rp"])
        }
        Write-Output $row
    }
    Write-Output ""
}

if (@("show", "apply", "remove", "verify") -contains $Command) {
    if ($Command -eq "verify" -and -not $Pack) {
        $Pack = "all"
    }
    $Packs = Resolve-PackNames $Pack
    $Tools = Normalize-Tools $Tools
}
if ($Command -eq "apply-preset") {
    $Tools = Normalize-Tools $Tools
}

switch ($Command) {
    "list" {
        $resolvedTarget = (Resolve-Path -LiteralPath $TargetRepo).Path
        $listTools = if ($toolsWereProvided) { Normalize-Tools $Tools } else { @("claude", "codex", "copilot") }

        Write-Output "Available packs  (target: $resolvedTarget)"
        Write-Output ""
        Get-PackNames | ForEach-Object {
            $packName = $_
            $packInfo = Read-PackJson $packName
            $cells = @()
            foreach ($tool in $listTools) {
                $cells += Format-StatusCell $tool (Test-BaselineInstalled $resolvedTarget $packName $tool)
            }
            Write-Output ("{0,-40} v{1,-8} {2}" -f $packInfo.name, $packInfo.version, ($cells -join "  "))
        }
        Write-Output ""
        Write-Output "Legend: [+ applied]  [ absent]"
    }
    "show" {
        foreach ($packName in $Packs) {
            $packInfo = Read-PackJson $packName
            $baselinePath = Join-Path (Get-PackRoot $packName) "baseline.md"
            Write-Output "# $($packInfo.name) $($packInfo.version) [$($packInfo.status)]"
            Write-Output ""
            Write-Output $packInfo.description
            Write-Output ""
            Write-Output "Adapters:"
            $packInfo.adapters.PSObject.Properties | ForEach-Object {
                Write-Output "- $($_.Name): $($_.Value)"
            }
            Write-Output ""
            Write-Output (Read-Utf8Text $baselinePath).Trim()
            Write-Output ""
        }
    }
    "apply" {
        $applyScript = Join-Path $scriptDir "baselines/apply.ps1"
        foreach ($packName in $Packs) {
            & $applyScript -TargetRepo $TargetRepo -Pack $packName -Tools $Tools -Variant $Variant -CreateMissing:$CreateMissing -SkipMissing:$SkipMissing -DryRun:$DryRun
        }
    }
    "remove" {
        $removeScript = Join-Path $scriptDir "baselines/remove.ps1"
        foreach ($packName in $Packs) {
            & $removeScript -TargetRepo $TargetRepo -Pack $packName -Tools $Tools -DryRun:$DryRun
        }
    }
    "verify" {
        $verifyScript = Join-Path $scriptDir "baselines/verify.ps1"
        foreach ($packName in $Packs) {
            $verifyArgs = @{
                Pack = $packName
                Tools = $Tools
            }
            $currentDir = (Resolve-Path -LiteralPath (Get-Location).Path).Path
            $resolvedRepoRoot = (Resolve-Path -LiteralPath $repoRoot).Path
            if ($targetRepoWasProvided -or ($currentDir -ne $resolvedRepoRoot)) {
                $verifyArgs.TargetRepo = $TargetRepo
            }

            & $verifyScript @verifyArgs
        }
    }
    "apply-preset" {
        $contents = Get-PresetContents $Name
        $applyScript = Join-Path $scriptDir "baselines/apply.ps1"
        foreach ($packName in $contents.Baselines) {
            & $applyScript -TargetRepo $TargetRepo -Pack $packName -Tools $Tools -CreateMissing:$CreateMissing -SkipMissing:$SkipMissing -DryRun:$DryRun
        }
        if ($contents.Hooks.Count -gt 0) {
            Write-Output ""
            Write-Output "Hooks to install - run these commands from inside ${TargetRepo}:"
            foreach ($hook in $contents.Hooks) {
                Write-Output "  hooks apply $hook"
            }
        }
        Write-Output ""
        $resolvedTargetMsg = try { (Resolve-Path -LiteralPath $TargetRepo).Path } catch { $TargetRepo }
        Write-Output "Done. Applied $($contents.Baselines.Count) baseline(s) from preset '$Name' to $resolvedTargetMsg."
    }
    "presets" { Invoke-PresetsList }
    "status" {
        if ($Repos -or $ReposFile) {
            Invoke-StatusMulti (Get-RepoListFromParams $Repos $ReposFile)
        } else {
            Invoke-Status
        }
    }
    "shim" {
        if (@("install", "verify", "remove") -notcontains $ShimAction) {
            throw "Unknown shim action: $ShimAction. Use install, verify, or remove."
        }

        if ($IsMacOS -or $IsLinux) {
            $shimScript = Join-Path $scriptDir "baselines/install-shim.sh"
            $bashArgs = @()
            if ($InstallDir) { $bashArgs += "--install-dir"; $bashArgs += $InstallDir }
            if ($ShimAction -eq "verify") { $bashArgs += "--verify-only" }
            if ($ShimAction -eq "remove") { $bashArgs += "--remove" }
            & bash $shimScript @bashArgs
        } else {
            $shimScript = Join-Path $scriptDir "baselines/install-shim.ps1"
            $shimArgs = @{}
            if ($InstallDir) { $shimArgs.InstallDir = $InstallDir }
            if ($AddToUserPath) { $shimArgs.AddToUserPath = $true }
            if ($ShimAction -eq "verify") { $shimArgs.VerifyOnly = $true }
            if ($ShimAction -eq "remove") { $shimArgs.Remove = $true }
            & $shimScript @shimArgs
        }
    }
}
}

try {
    Invoke-BaselineCommand
} catch {
    Write-FriendlyError $_.Exception.Message
    exit 1
}
