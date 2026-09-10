param(
    [string] $TargetRepo = (Get-Location).Path,

    [string] $Pack = "karpathy-principles",

    [string[]] $Tools = @("codex", "claude"),

    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$toolMap = @{
    codex         = "AGENTS.md"
    claude        = "CLAUDE.md"
    copilot       = ".github/copilot-instructions.md"
    "claude-rule" = ".claude/rules/$Pack.md"
}

# A path-scoped rule file exists solely to carry one pack, so removing that pack means deleting
# the file. Stripping the block would leave an orphaned `paths:` frontmatter that still loads.
$ruleTools = @("claude-rule")

function Read-Utf8Text($Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8Text($Path, $Text) {
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

$resolvedTarget = (Resolve-Path -LiteralPath $TargetRepo).Path
$packName = [regex]::Escape($Pack)

function Get-BlockPattern($Marker, $EscapedPackName) {
    $escapedMarker = [regex]::Escape($Marker)
    return "\r?\n?\r?\n?<!-- BEGIN ${escapedMarker}:$EscapedPackName v[^>]+ -->.*?<!-- END ${escapedMarker}:$EscapedPackName -->\r?\n?"
}

$newPattern = Get-BlockPattern "baseline" $packName
$legacyPattern = Get-BlockPattern "portable-agent-baseline" $packName

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

    if ($ruleTools -contains $tool) {
        if ($DryRun) {
            Write-Output "would delete $targetRel for $tool"
            continue
        }
        Remove-Item -LiteralPath $targetPath -Force
        Write-Output "deleted $targetRel for $tool"
        continue
    }

    $current = Read-Utf8Text $targetPath
    $hasNewBlock = [regex]::IsMatch($current, $newPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $hasLegacyBlock = [regex]::IsMatch($current, $legacyPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($hasNewBlock -and $hasLegacyBlock) {
        throw "Both baseline and legacy portable-agent-baseline blocks exist for $Pack in $targetRel; resolve the duplicate manually."
    }

    if (-not ($hasNewBlock -or $hasLegacyBlock)) {
        Write-Output "skip absent $Pack in $targetRel for $tool"
        continue
    }

    $pattern = if ($hasNewBlock) { $newPattern } else { $legacyPattern }
    $next = [regex]::Replace($current, $pattern, [Environment]::NewLine, [System.Text.RegularExpressions.RegexOptions]::Singleline).TrimEnd() + [Environment]::NewLine

    if ($DryRun) {
        Write-Output "would remove $Pack from $targetRel for $tool"
        continue
    }

    Write-Utf8Text $targetPath $next
    Write-Output "removed $Pack from $targetRel for $tool"
}
