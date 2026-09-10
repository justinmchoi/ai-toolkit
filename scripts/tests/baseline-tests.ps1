<#
.SYNOPSIS
    Tests for the baseline CLI. No framework dependency -- runs anywhere the CLI itself runs.

.DESCRIPTION
    Exercises scripts/baseline.ps1 against a throwaway target directory. Every case here maps to a
    real defect: the core/full clobber, the silent variant switch, rules written without globs,
    "all" sweeping in a named-only target, and remove leaving an orphaned rule file behind.

    Run:  pwsh -NoProfile -File scripts/tests/baseline-tests.ps1
    Exits non-zero on the first failing assertion count, so it works as a CI gate.
#>
[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cli = Join-Path $repoRoot "scripts/baseline.ps1"
if (-not (Test-Path -LiteralPath $cli)) { throw "cannot find baseline.ps1 at $cli" }

$script:pass = 0
$script:fail = 0

function Test-Case($Name, [scriptblock] $Body) {
    try {
        & $Body
        $script:pass++
        Write-Host ("  PASS  " + $Name)
    } catch {
        $script:fail++
        Write-Host ("  FAIL  " + $Name) -ForegroundColor Red
        Write-Host ("        " + $_.Exception.Message) -ForegroundColor Red
    }
}

function Assert-Match($Text, $Pattern, $Because) {
    if ($Text -notmatch $Pattern) { throw "$Because`n        expected match: $Pattern`n        actual: $Text" }
}
function Assert-NoMatch($Text, $Pattern, $Because) {
    if ($Text -match $Pattern) { throw "$Because`n        expected NO match: $Pattern`n        actual: $Text" }
}

# A pack with a core adapter, and one without, so both paths are covered.
$packWithCore = "verification-epistemics"
$packNoCore = "karpathy-principles"
$packWithPaths = "sql-server-safety"

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("baseline-tests-" + [guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
function New-Target { $d = Join-Path $tmp ([guid]::NewGuid().ToString("N").Substring(0,8)); New-Item -ItemType Directory -Path $d -Force | Out-Null; return $d }
function Invoke-Cli {
    param([hashtable] $P)
    # The CLI reports user-facing errors with [Console]::Error.WriteLine, which writes straight to
    # the process stderr handle and is therefore invisible to PowerShell's 2>&1 redirection.
    # Swap the console error writer for a buffer so the error-path cases can assert on the message.
    $sw = New-Object System.IO.StringWriter
    $orig = [Console]::Error
    [Console]::SetError($sw)
    try {
        $out = (& $cli @P 2>&1 | Out-String)
    } finally {
        [Console]::SetError($orig)
    }
    return ($out + $sw.ToString())
}

Write-Host "baseline CLI tests"
Write-Host ("  repo: " + $repoRoot)
Write-Host ("  temp: " + $tmp)
Write-Host ""

# --- variant selection -------------------------------------------------------------------------

Test-Case "apply installs the core rendering by default when the pack has one" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $text = Get-Content (Join-Path $t "CLAUDE.md") -Raw
    Assert-Match $text "BEGIN baseline:$packWithCore v[^>]+ \(core\)" "auto should prefer core when a core adapter exists"
}

Test-Case "REGRESSION: re-applying does NOT replace a core install with the full block" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $before = (Get-Content (Join-Path $t "CLAUDE.md") -Raw).Length
    $out = Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; TargetRepo=$t}
    $after = Get-Content (Join-Path $t "CLAUDE.md") -Raw
    Assert-Match $after "\(core\)" "the core marker must survive a re-apply"
    Assert-Match $out "\(core\)" "output should name the variant it kept"
    if ($after.Length -gt $before * 2) { throw "file grew from $before to $($after.Length) chars -- the full block was installed over the core one" }
}

Test-Case "an explicit downgrade to full is announced, not silent" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $out = Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; Variant="full"; TargetRepo=$t}
    Assert-Match $out "switched core->full" "switching renderings must be reported"
    Assert-NoMatch (Get-Content (Join-Path $t "CLAUDE.md") -Raw) "\(core\)" "the core marker should be gone after an explicit switch"
}

Test-Case "a pack with no core adapter falls back to full without erroring" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packNoCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $text = Get-Content (Join-Path $t "CLAUDE.md") -Raw
    Assert-Match $text "BEGIN baseline:$packNoCore v" "the full block should be installed"
    Assert-NoMatch $text "\(core\)" "no core marker for a pack that has no core adapter"
}

Test-Case "-Variant core on a pack without one fails loudly rather than silently installing full" {
    $t = New-Target
    $out = Invoke-Cli @{Command="apply"; Name=$packNoCore; Tools="claude"; Variant="core"; TargetRepo=$t}
    Assert-Match $out "no core adapter" "should refuse rather than quietly substitute the full block"
}

# --- path-scoped rules -------------------------------------------------------------------------

Test-Case "claude-rule writes a rule file with paths: frontmatter" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithPaths; Tools="claude-rule"; TargetRepo=$t} | Out-Null
    $rule = Join-Path $t ".claude/rules/$packWithPaths.md"
    if (-not (Test-Path -LiteralPath $rule)) { throw "rule file was not created at $rule" }
    $text = Get-Content $rule -Raw
    Assert-Match $text "(?s)^---\s*\npaths:" "a rule without paths: frontmatter would load eagerly and defeat the point"
    Assert-Match $text "BEGIN baseline:$packWithPaths" "the rule should carry the pack block"
}

Test-Case "claude-rule refuses a pack that declares no globs" {
    $t = New-Target
    $out = Invoke-Cli @{Command="apply"; Name=$packNoCore; Tools="claude-rule"; TargetRepo=$t}
    Assert-Match $out "declares no 'paths'" "a rule without globs must be refused, not written"
}

Test-Case "-Tools all does not sweep in the named-only rule target" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packNoCore; Tools="all"; TargetRepo=$t} | Out-Null
    if (Test-Path -LiteralPath (Join-Path $t ".claude/rules")) { throw "'all' created a rules file; it must be opt-in by name" }
    foreach ($f in @("CLAUDE.md", "AGENTS.md", ".github/copilot-instructions.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $t $f))) { throw "'all' should still have written $f" }
    }
}

# --- remove ------------------------------------------------------------------------------------

Test-Case "remove deletes the rule file rather than leaving orphaned frontmatter" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithPaths; Tools="claude-rule"; TargetRepo=$t} | Out-Null
    Invoke-Cli @{Command="remove"; Name=$packWithPaths; Tools="claude-rule"; TargetRepo=$t} | Out-Null
    if (Test-Path -LiteralPath (Join-Path $t ".claude/rules/$packWithPaths.md")) {
        throw "rule file still present; stripping the block would leave paths: frontmatter that still loads"
    }
}

Test-Case "remove strips a block without destroying surrounding content" {
    $t = New-Target
    $claude = Join-Path $t "CLAUDE.md"
    Set-Content -LiteralPath $claude -Value "# My project`n`nKeep this line.`n" -NoNewline
    Invoke-Cli @{Command="apply"; Name=$packNoCore; Tools="claude"; TargetRepo=$t} | Out-Null
    Invoke-Cli @{Command="remove"; Name=$packNoCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $text = Get-Content $claude -Raw
    Assert-Match $text "Keep this line\." "pre-existing content must survive removal"
    Assert-NoMatch $text "BEGIN baseline:$packNoCore" "the block should be gone"
}

# --- status / verify ---------------------------------------------------------------------------

Test-Case "status parses a version carrying a variant suffix" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $out = Invoke-Cli @{Command="status"; TargetRepo=$t}
    Assert-Match $out "$packWithCore\s+YES" "status should see the installed pack"
    Assert-Match $out "\(core\)" "status should report which rendering is installed"
}

Test-Case "verify accepts a core install instead of reporting the block missing" {
    $t = New-Target
    Invoke-Cli @{Command="apply"; Name=$packWithCore; Tools="claude"; TargetRepo=$t} | Out-Null
    $out = Invoke-Cli @{Command="verify"; Name=$packWithCore; Tools="claude"; TargetRepo=$t}
    Assert-NoMatch $out "Missing $packWithCore managed block" "a core install is a valid install"
    Assert-Match $out "target ok" "verify should pass on a core install"
}

Test-Case "verify catches a core adapter whose marker version has drifted from pack.json" {
    # Guards the exact drift the core/full split introduces: two files carrying the same version.
    $out = Invoke-Cli @{Command="verify"; Name=$packWithCore; Tools="claude"}
    Assert-Match $out "core adapter present and tagged \(core\)" "the shipped core adapter should be consistent"
}

Write-Host ""
Write-Host ("  $script:pass passed, $script:fail failed")
if (-not $KeepTemp) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
if ($script:fail -gt 0) { exit 1 }
