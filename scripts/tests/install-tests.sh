#!/usr/bin/env bash
# Tests for skill installation.
#
# The defect these guard against is specific and has already cost real work: under Git Bash on
# Windows, `ln -s` does not fail when symlink creation is unavailable -- it silently COPIES the
# directory. A copy drifts from its source in both directions and a reinstall destroys whatever
# was edited in it. One skill (eli5) had already accumulated an improvement that way.
#
# So the contract is not "a symlink is created". It is: an installed skill is NEVER a plain
# directory. A junction satisfies that; a copy does not.
#
#   Run: bash scripts/tests/install-tests.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LIB="$ROOT_DIR/scripts/lib/personal-skill-install.sh"
pass=0
fail=0

ok()   { pass=$((pass+1)); printf '  PASS  %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL  %s\n         %s\n' "$1" "$2"; }

# Is the path a link of any kind (POSIX symlink, or a Windows junction/reparse point)?
is_link() {
  [ -L "$1" ] && return 0
  if command -v powershell.exe >/dev/null 2>&1; then
    local w lt
    w="$(cygpath -w "$1" 2>/dev/null || printf '%s' "$1")"
    lt="$(powershell.exe -NoProfile -Command "(Get-Item -LiteralPath '$w' -Force).LinkType" 2>/dev/null | tr -d '\r\n ')"
    [ -n "$lt" ] && return 0
  fi
  return 1
}

printf 'skill install tests\n  repo: %s\n\n' "$ROOT_DIR"

if [ ! -f "$LIB" ]; then
  printf '  FAIL  installer library not found at %s\n' "$LIB"
  exit 1
fi

# Pull create_symlink out rather than sourcing the whole library, so no top-level side effects run.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sed -n '/^create_symlink() {/,/^}/p' "$LIB" > "$tmp/fn.sh"
# create_symlink calls this on total failure; stub it so a failure surfaces as a test result.
printf 'symlink_failure_hint() { :; }\n' >> "$tmp/fn.sh"
# shellcheck disable=SC1090
. "$tmp/fn.sh"

if ! declare -F create_symlink >/dev/null; then
  printf '  FAIL  could not extract create_symlink from the library\n'
  exit 1
fi

# --- the core contract -------------------------------------------------------------------------
src="$tmp/source-skill"
mkdir -p "$src"
printf -- '---\nname: probe\n---\n\n# probe\n' > "$src/SKILL.md"

dst="$tmp/installed"
if create_symlink "$src" "$dst" >/dev/null 2>&1; then
  if is_link "$dst"; then
    ok "install produces a link, never a plain directory copy"
  else
    bad "install produces a link, never a plain directory copy" \
        "$dst is a real directory -- it will drift and a reinstall will destroy edits"
  fi
else
  bad "install produces a link, never a plain directory copy" "create_symlink returned non-zero"
fi

# --- the link must actually resolve --------------------------------------------------------------
if [ -f "$dst/SKILL.md" ]; then
  ok "the installed path resolves to the source content"
else
  bad "the installed path resolves to the source content" "SKILL.md not readable through $dst"
fi

# --- edits at the source must be visible through the install (the whole point) -------------------
printf 'ADDED-AT-SOURCE\n' >> "$src/SKILL.md"
if grep -q 'ADDED-AT-SOURCE' "$dst/SKILL.md" 2>/dev/null; then
  ok "a source edit is visible through the install (no drift possible)"
else
  bad "a source edit is visible through the install (no drift possible)" \
      "the install is a snapshot, not a link -- this is exactly the eli5 failure"
fi

# --- a failed attempt must not leave a half-installed directory behind ---------------------------
dst2="$tmp/installed2"
mkdir -p "$dst2/stale"
# create_symlink calls `exit 1` when it gives up; run it in a subshell so that does not take
# the harness down with it.
( create_symlink "$tmp/does-not-exist" "$dst2" >/dev/null 2>&1 ) || true
if [ ! -e "$dst2" ] || is_link "$dst2"; then
  ok "a failed install leaves no half-installed directory"
else
  if [ -d "$dst2/stale" ]; then
    bad "a failed install leaves no half-installed directory" "$dst2 still holds pre-existing content"
  else
    ok "a failed install leaves no half-installed directory"
  fi
fi

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
