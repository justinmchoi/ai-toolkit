param(
    [string] $TargetRepo = (Get-Location).Path,

    [string] $Pack = "karpathy-principles",

    [string[]] $Tools = @("codex", "claude"),

    # auto  = keep whatever variant is already installed; if none, prefer core when the pack has one
    # core  = install the slim always-on rendering (fails if the pack has no core adapter)
    # full  = install the complete rendering
    [ValidateSet("auto", "core", "full")]
    [string] $Variant = "auto",

    [switch] $CreateMissing,

    [switch] $SkipMissing,

    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$packRoot = Join-Path $repoRoot "baselines/$Pack"

if (-not (Test-Path -LiteralPath $packRoot)) {
    throw "Unknown portable baseline pack: $Pack"
}

# Target and adapter per tool. `claude` additionally declares a CoreAdapter: the slim rendering
# that is the only thing worth installing always-on. `claude-rule` writes the FULL rendering to a
# path-scoped rule file instead, which Claude Code loads only when a matching file is read.
$toolMap = @{
    codex         = @{ Target = "AGENTS.md";                        Adapter = "AGENTS.md.block" }
    claude        = @{ Target = "CLAUDE.md";                        Adapter = "CLAUDE.md.block"; CoreAdapter = "CLAUDE.md.core.block" }
    copilot       = @{ Target = ".github/copilot-instructions.md";  Adapter = "copilot-instructions.md.block" }
    "claude-rule" = @{ Target = "";                                 Adapter = "CLAUDE.md.block"; IsRule = $true }
}

# The rule target is ".claude/rules/<pack>.md" relative to a REPO. At the user tier the target
# passed in is already ~/.claude, so naively prefixing produces ~/.claude/.claude/rules/<pack>.md --
# a path Claude Code never reads, i.e. a file that installs cleanly and does nothing. Detect it.
function Resolve-RuleRelativePath($ResolvedTarget, $PackName) {
    if ((Split-Path -Leaf $ResolvedTarget) -eq ".claude") { return "rules/$PackName.md" }
    return ".claude/rules/$PackName.md"
}

function Read-Utf8Text($Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8Text($Path, $Text) {
    $encoding = [System.Text.UTF8Encoding]::new($false)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

$resolvedTarget = (Resolve-Path -LiteralPath $TargetRepo).Path
$packName = [regex]::Escape($Pack)

function Get-BlockPattern($Marker, $EscapedPackName) {
    $escapedMarker = [regex]::Escape($Marker)
    return "<!-- BEGIN ${escapedMarker}:$EscapedPackName v[^>]+ -->.*?<!-- END ${escapedMarker}:$EscapedPackName -->"
}

# Reads the variant recorded in an already-installed block. Markers are
#   <!-- BEGIN baseline:<pack> v1.2.3 -->          -> full (the historical form)
#   <!-- BEGIN baseline:<pack> v1.2.3 (core) -->   -> core
function Get-InstalledVariant($Text, $EscapedPackName) {
    $m = [regex]::Match($Text, "<!-- BEGIN baseline:$EscapedPackName v[^ >]+(?: \((?<variant>[a-z]+)\))? -->")
    if (-not $m.Success) { return $null }
    if ($m.Groups["variant"].Success) { return $m.Groups["variant"].Value }
    return "full"
}

# Stamps the variant into the block's BEGIN marker so a later apply can tell what is installed.
# Without this, a core install and a full install are indistinguishable and `apply` silently
# replaces one with the other.
function Set-BlockVariant($Block, $EscapedPackName, $VariantName) {
    $suffix = if ($VariantName -eq "core") { " (core)" } else { "" }
    return [regex]::Replace(
        $Block,
        "(<!-- BEGIN baseline:$EscapedPackName v[^ >]+)(?: \([a-z]+\))?( -->)",
        "`${1}$suffix`${2}")
}

$newPattern = Get-BlockPattern "baseline" $packName
$legacyPattern = Get-BlockPattern "portable-agent-baseline" $packName

foreach ($tool in $Tools) {
    if (-not $toolMap.ContainsKey($tool)) {
        throw "Unsupported tool '$tool'. Supported tools: $($toolMap.Keys -join ', ')"
    }

    $targetRel = if ($toolMap[$tool].IsRule) { Resolve-RuleRelativePath $resolvedTarget $Pack } else { $toolMap[$tool].Target }
    $targetPath = Join-Path $resolvedTarget $targetRel
    $coreAdapterRel = $toolMap[$tool].CoreAdapter
    $hasCore = $coreAdapterRel -and (Test-Path -LiteralPath (Join-Path (Join-Path $packRoot "adapters") $coreAdapterRel))

    $current = if (Test-Path -LiteralPath $targetPath) { Read-Utf8Text $targetPath } else { $null }
    $installedVariant = if ($current) { Get-InstalledVariant $current $packName } else { $null }

    # Resolve which rendering to write.
    $useVariant = switch ($Variant) {
        "core" {
            if (-not $hasCore) { throw "Pack '$Pack' has no core adapter for '$tool'; use -Variant full." }
            "core"
        }
        "full" { "full" }
        default {
            # auto: never silently change what is already installed.
            if ($installedVariant) { $installedVariant }
            elseif ($hasCore) { "core" }
            else { "full" }
        }
    }
    if ($useVariant -eq "core" -and -not $hasCore) { $useVariant = "full" }

    $adapterRel = if ($useVariant -eq "core") { $coreAdapterRel } else { $toolMap[$tool].Adapter }
    $adapterPath = Join-Path (Join-Path $packRoot "adapters") $adapterRel
    $block = Set-BlockVariant ((Read-Utf8Text $adapterPath).Trim()) $packName $useVariant

    # A path-scoped rule needs `paths:` frontmatter; without it Claude Code loads the file eagerly,
    # which would defeat the point. The globs come from the pack's own metadata.
    if ($toolMap[$tool].IsRule) {
        $packJsonPath = Join-Path $packRoot "pack.json"
        $paths = @()
        if (Test-Path -LiteralPath $packJsonPath) {
            $meta = Get-Content -LiteralPath $packJsonPath -Raw | ConvertFrom-Json
            if ($meta.PSObject.Properties.Name -contains "paths") { $paths = @($meta.paths) }
        }
        if (-not $paths -or $paths.Count -eq 0) {
            throw "Pack '$Pack' declares no 'paths' in pack.json; a path-scoped rule without globs would load eagerly. Add paths, or apply to 'claude' instead."
        }
        $fm = "---`npaths:`n" + (($paths | ForEach-Object { "  - `"$_`"" }) -join "`n") + "`n---`n`n"
        $block = $fm + $block
    }

    $label = if ($useVariant -eq "core") { "$Pack (core)" } else { $Pack }

    if (-not $current) {
        if ($SkipMissing) {
            Write-Output "skip missing $targetRel for $tool in $resolvedTarget"
            continue
        }
        if ($DryRun) {
            Write-Output "would create $targetRel with $label for $tool"
            continue
        }
        Write-Utf8Text $targetPath ($block + [Environment]::NewLine)
        Write-Output "created $targetRel with $label for $tool"
        continue
    }

    $hasNewBlock = [regex]::IsMatch($current, $newPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $hasLegacyBlock = [regex]::IsMatch($current, $legacyPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($hasNewBlock -and $hasLegacyBlock) {
        throw "Both baseline and legacy portable-agent-baseline blocks exist for $Pack in $targetRel; resolve the duplicate manually."
    }

    if ($hasNewBlock -or $hasLegacyBlock) {
        $pattern = if ($hasNewBlock) { $newPattern } else { $legacyPattern }
        $next = [regex]::Replace($current, $pattern, { param($m) $block }, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $pastAction = if ($hasLegacyBlock) { "migrated" } else { "updated" }
        $planAction = if ($hasLegacyBlock) { "migrate" } else { "update" }
        if ($installedVariant -and $installedVariant -ne $useVariant) {
            $pastAction = "switched $installedVariant->$useVariant for"
            $planAction = "switch $installedVariant->$useVariant for"
        }
    } else {
        $next = $current.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $block + [Environment]::NewLine
        $pastAction = "added"
        $planAction = "add"
    }

    if ($DryRun) {
        Write-Output "would $planAction $label in $targetRel for $tool"
        continue
    }

    Write-Utf8Text $targetPath $next
    Write-Output "$pastAction $label in $targetRel for $tool"
}
