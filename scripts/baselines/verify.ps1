param(
    [string] $TargetRepo,

    [string] $Pack = "karpathy-principles",

    [string[]] $Tools = @("codex", "claude")
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$packRoot = Join-Path $repoRoot "baselines/$Pack"

if (-not (Test-Path -LiteralPath $packRoot)) {
    throw "Unknown portable baseline pack: $Pack"
}

$packJsonPath = Join-Path $packRoot "pack.json"
$packInfo = ([System.IO.File]::ReadAllText($packJsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)
$packVersion = $packInfo.version

function Normalize-Tools($ToolValues) {
    $normalized = @()
    foreach ($toolValue in $ToolValues) {
        foreach ($tool in ($toolValue -split ",")) {
            $trimmed = $tool.Trim()
            if ($trimmed) {
                $normalized += $trimmed
            }
        }
    }

    return $normalized
}

$Tools = Normalize-Tools $Tools

$required = @(
    "pack.json",
    "baseline.md",
    "adapters/AGENTS.md.block",
    "adapters/CLAUDE.md.block",
    "adapters/copilot-instructions.md.block"
)

# The core adapter is optional -- only always-on packs need a slim rendering. When one exists it
# must agree with pack.json, or `apply -Variant core` would install a stale version marker.
$coreAdapter = Join-Path $packRoot "adapters/CLAUDE.md.core.block"
if (Test-Path -LiteralPath $coreAdapter) {
    $coreText = [System.IO.File]::ReadAllText($coreAdapter, [System.Text.Encoding]::UTF8)
    $escapedPack = [regex]::Escape($Pack)
    $m = [regex]::Match($coreText, "<!-- BEGIN baseline:$escapedPack v(?<v>[^ >]+)(?: \((?<variant>[a-z]+)\))? -->")
    if (-not $m.Success) {
        throw "Core adapter has no recognisable BEGIN marker for $Pack"
    } elseif ($m.Groups["v"].Value -ne $packVersion) {
        throw "Core adapter marker v$($m.Groups['v'].Value) does not match pack.json v$packVersion"
    } elseif ($m.Groups["variant"].Value -ne "core") {
        throw "Core adapter marker is not tagged (core); apply could not tell it apart from the full block"
    } else {
        Write-Output "ok   core adapter present and tagged (core) at v$packVersion"
    }
}

foreach ($rel in $required) {
    $path = Join-Path $packRoot $rel
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing portable baseline file: $rel"
    }
}

$adapterFiles = @(
    (Join-Path $packRoot "adapters/AGENTS.md.block"),
    (Join-Path $packRoot "adapters/CLAUDE.md.block"),
    (Join-Path $packRoot "adapters/copilot-instructions.md.block")
)

foreach ($adapter in $adapterFiles) {
    $text = [System.IO.File]::ReadAllText($adapter, [System.Text.Encoding]::UTF8)
    if ($text -notmatch "<!-- BEGIN baseline:$([regex]::Escape($Pack)) v[^>]+ -->") {
        throw "Adapter missing BEGIN marker: $adapter"
    }
    if ($text -notmatch "<!-- END baseline:$([regex]::Escape($Pack)) -->") {
        throw "Adapter missing END marker: $adapter"
    }
}

Write-Output "pack ok: $Pack"

if ($TargetRepo) {
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetRepo).Path
    $toolMap = @{
        codex = "AGENTS.md"
        claude = "CLAUDE.md"
        copilot = ".github/copilot-instructions.md"
    }
    $newBeginPattern = "<!-- BEGIN baseline:$([regex]::Escape($Pack)) v(?<version>[^ >]+)(?: \((?<variant>[a-z]+)\))? -->"
    $newBlockPattern = "$newBeginPattern.*?<!-- END baseline:$([regex]::Escape($Pack)) -->"
    $legacyBeginPattern = "<!-- BEGIN portable-agent-baseline:$([regex]::Escape($Pack)) v(?<version>[^ >]+) -->"
    $legacyBlockPattern = "$legacyBeginPattern.*?<!-- END portable-agent-baseline:$([regex]::Escape($Pack)) -->"

    foreach ($tool in $Tools) {
        if (-not $toolMap.ContainsKey($tool)) {
            throw "Unsupported tool '$tool'. Supported tools: $($toolMap.Keys -join ', ')"
        }

        $targetRel = $toolMap[$tool]
        $targetPath = Join-Path $resolvedTarget $targetRel
        if (-not (Test-Path -LiteralPath $targetPath)) {
            Write-Output "skip missing $targetRel for $tool in $resolvedTarget"
            continue
        }

        $text = [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
        $newMatch = [regex]::Match($text, $newBlockPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $legacyMatch = [regex]::Match($text, $legacyBlockPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($newMatch.Success -and $legacyMatch.Success) {
            throw "Both baseline and legacy portable-agent-baseline blocks exist for $Pack in $targetRel"
        }
        if (-not ($newMatch.Success -or $legacyMatch.Success)) {
            throw "Missing $Pack managed block in $targetRel"
        }

        $match = if ($newMatch.Success) { $newMatch } else { $legacyMatch }
        $installedVersion = $match.Groups["version"].Value
        if ($installedVersion -ne $packVersion) {
            throw "Stale $Pack managed block in ${targetRel}: installed v$installedVersion, source v$packVersion"
        }

        $installedVariant = if ($match.Groups["variant"].Success) { $match.Groups["variant"].Value } else { "full" }
        $markerStatus = if ($legacyMatch.Success) { "legacy marker; run apply to migrate" } else { "marker ok" }
        Write-Output "target ok: $targetRel contains $Pack v$installedVersion ($installedVariant, $markerStatus)"
    }
}
