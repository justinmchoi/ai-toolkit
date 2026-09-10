#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage: install script [--link|--copy] [--verify-only] [--keep-existing]

Installs personal skills from the canonical skills root.

Default mode is automatic:
  - symlinks through ~/.local/share/ai-toolkit/current
  - on Windows, run from a shell that can create real symlinks

Options:
  --link           Force symlink mode.
  --copy           Force copy mode as an explicit fallback.
  --verify-only    Check links without changing them.
  --keep-existing  Leave non-symlink targets in place instead of moving them
                   to a backup directory and linking the canonical skill.
  -h, --help       Show this help.
USAGE
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

symlink_failure_hint() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*)
      cat >&2 <<'HINT'

Windows note:
  This script requires real directory symlinks. In Git Bash, enable Windows
  Developer Mode or run the shell with privileges that can create symlinks.
  Prefer:

    MSYS=winsymlinks:nativestrict ./scripts/skills-setup/install-claude-code.sh

  If you run from WSL, the default ~/.claude/skills path is inside WSL, not the
  Windows user's Claude Code profile, unless you explicitly set CLAUDE_SKILLS_DIR.
HINT
      ;;
  esac
}

# Windows note: under Git Bash, `ln -s` does not fail when symlink creation is unavailable -- it
# silently COPIES the directory instead. A copy then drifts from the source in both directions, and
# a later reinstall destroys whatever was edited in the installed copy. That has already happened
# here (the eli5 recovery, 2026-09-09), so a copy is never an acceptable outcome.
#
# Real symlinks need elevation on Windows even with Developer Mode enabled, but a directory
# JUNCTION needs neither and resolves identically for reads. Try the symlink; fall back to a
# junction rather than erroring out.
create_symlink() {
  local link_source="$1"
  local link_target="$2"

  ln -s "$link_source" "$link_target" 2>/dev/null || true

  if [ -L "$link_target" ]; then
    return 0
  fi

  # ln -s produced a copy (or nothing). Remove it before the fallback so a half-installed
  # directory is never left behind.
  [ ! -e "$link_target" ] || rm -rf "$link_target"

  if command -v powershell.exe >/dev/null 2>&1; then
    win_target="$(cygpath -w "$link_target" 2>/dev/null || printf '%s' "$link_target")"
    win_source="$(cygpath -w "$link_source" 2>/dev/null || printf '%s' "$link_source")"
    powershell.exe -NoProfile -Command "New-Item -ItemType Junction -Path '$win_target' -Target '$win_source' -Force | Out-Null" >/dev/null 2>&1 || true
    if [ -d "$link_target" ]; then
      printf 'note: used a directory junction instead of a symlink: %s -> %s
' "$link_target" "$link_source"
      return 0
    fi
  fi

  printf 'ERROR: could not link (symlink and junction both failed): %s -> %s
' "$link_target" "$link_source" >&2
  symlink_failure_hint
  exit 1
}

move_to_backup() {
  existing_path="$1"
  backup_dir="$2"
  backup_name="$3"

  backup_target="$backup_dir/$backup_name"
  mkdir -p "$backup_dir"
  [ ! -e "$backup_target" ] || fail "Backup target already exists: $backup_target"
  mv "$existing_path" "$backup_target"
  printf '%s\n' "$backup_target"
}

copy_skill_snapshot() {
  skill_source="$1"
  skill_target="$2"

  mkdir -p "$skill_target"
  cp -R "$skill_source/." "$skill_target/"
}

verify_copy_snapshot() {
  skill_source="$1"
  skill_target="$2"
  label="$3"

  [ -d "$skill_target" ] || fail "$label copy is missing: $skill_target"
  if ! diff -qr "$skill_source" "$skill_target" >/dev/null 2>&1; then
    fail "$label copy differs from canonical source: $skill_target"
  fi
}

replace_symlink() {
  local link_source="$1"
  local link_target="$2"
  local link_parent
  local tmp_link
  local old_source

  link_parent="$(dirname "$link_target")"
  tmp_link="$link_parent/.tmp-link.$$.$RANDOM"
  old_source=""

  [ -L "$link_target" ] || fail "Refusing to replace non-symlink: $link_target"
  old_source="$(readlink "$link_target")"
  create_symlink "$link_source" "$tmp_link"
  if ! unlink "$link_target"; then
    unlink "$tmp_link" || true
    fail "Failed to unlink old symlink: $link_target"
  fi
  if ! mv "$tmp_link" "$link_target"; then
    unlink "$tmp_link" || true
    create_symlink "$old_source" "$link_target" || true
    fail "Failed to install replacement symlink: $link_target"
  fi
}

install_personal_skills() {
  tool_label="$1"
  root_dir="$2"
  source_dir="$3"
  target_dir="$4"
  shift 4

  verify_only=0
  keep_existing=0
  install_mode="${AGENTIC_SKILLS_INSTALL_MODE:-auto}"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --link)
        install_mode=link
        ;;
      --copy)
        install_mode=copy
        ;;
      --verify-only)
        verify_only=1
        ;;
      --keep-existing)
        keep_existing=1
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        fail "Unknown option: $1"
        ;;
    esac
    shift
  done

  [ -d "$source_dir" ] || fail "Missing source directory: $source_dir"

  case "$install_mode" in
    auto)
      install_mode=link
      ;;
    link|copy)
      ;;
    *)
      fail "Unknown install mode: $install_mode"
      ;;
  esac

  root_dir="$(cd "$root_dir" && pwd -P)"
  state_dir="${AI_TOOLKIT_STATE_DIR:-${AI_AGENT_LIBRARY_STATE_DIR:-${AGENTIC_ENGINEERING_SKILLS_STATE_DIR:-${AGENTIC_SKILLS_STATE_DIR:-}}}}"
  if [ -z "$state_dir" ]; then
    preferred_state_dir="$HOME/.local/share/ai-toolkit"
    legacy_ai_agent_library_dir="$HOME/.local/share/ai-agent-library"
    legacy_agentic_dir="$HOME/.local/share/agentic-engineering-skills"
    if [ -e "$legacy_ai_agent_library_dir/current" ] && [ ! -e "$preferred_state_dir/current" ]; then
      state_dir="$legacy_ai_agent_library_dir"
    elif [ -e "$legacy_agentic_dir/current" ] && [ ! -e "$preferred_state_dir/current" ]; then
      state_dir="$legacy_agentic_dir"
    else
      state_dir="$preferred_state_dir"
    fi
  fi
  current_link="$state_dir/current"
  backup_stamp="$(date +%Y%m%d-%H%M%S)"

  if [ "$install_mode" = "copy" ]; then
    if [ "$verify_only" -eq 0 ]; then
      mkdir -p "$target_dir"
    else
      [ -d "$target_dir" ] || fail "Missing target directory: $target_dir"
    fi
  elif [ "$verify_only" -eq 0 ]; then
    mkdir -p "$state_dir"

    if [ -L "$current_link" ]; then
      if [ ! -d "$current_link" ]; then
        replace_symlink "$root_dir" "$current_link"
        printf 'Repaired repo current link: %s -> %s\n' "$current_link" "$root_dir"
      else
        current_resolved="$(cd "$current_link" && pwd -P)"
        if [ "$current_resolved" != "$root_dir" ]; then
          replace_symlink "$root_dir" "$current_link"
          printf 'Updated repo current link: %s -> %s\n' "$current_link" "$root_dir"
        fi
      fi
    elif [ -e "$current_link" ]; then
      if [ "$keep_existing" -eq 1 ]; then
        fail "Current link path exists but is not a symlink: $current_link"
      fi

      backup_dir="$state_dir/.ai-toolkit-backups/$backup_stamp"
      backup_target="$(move_to_backup "$current_link" "$backup_dir" "current")"
      create_symlink "$root_dir" "$current_link"
      printf 'Moved existing repo current path to backup: %s\n' "$backup_target"
      printf 'Created repo current link: %s -> %s\n' "$current_link" "$root_dir"
    else
      create_symlink "$root_dir" "$current_link"
      printf 'Created repo current link: %s -> %s\n' "$current_link" "$root_dir"
    fi

    mkdir -p "$target_dir"
  else
    [ -L "$current_link" ] || fail "Missing repo current symlink: $current_link"
    [ -d "$current_link/skills" ] || fail "Repo current link does not resolve to skills: $current_link"
    current_resolved="$(cd "$current_link" && pwd -P)"
    [ "$current_resolved" = "$root_dir" ] || fail "Repo current link points at $current_resolved, expected $root_dir"
    [ -d "$target_dir" ] || fail "Missing target directory: $target_dir"
  fi

  found=0
  linked=0
  repaired=0
  migrated=0
  kept=0
  copied=0
  updated=0

  seen_names="|"

  for category_dir in "$source_dir"/*; do
    [ -d "$category_dir" ] || continue
    category_name="$(basename "$category_dir")"

    for skill_dir in "$category_dir"/*; do
      [ -d "$skill_dir" ] || continue
      found=1

      skill_name="$(basename "$skill_dir")"
      [ -f "$skill_dir/SKILL.md" ] || fail "Missing SKILL.md for canonical skill: $category_name/$skill_name"
      case "$seen_names" in
        *"|$skill_name|"*)
          fail "Duplicate canonical skill name across categories: $skill_name"
          ;;
      esac
      seen_names="${seen_names}${skill_name}|"
      target="$target_dir/$skill_name"

      if [ "$install_mode" = "copy" ]; then
        if [ "$verify_only" -eq 1 ]; then
          verify_copy_snapshot "$skill_dir" "$target" "$tool_label skill"
          continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
          if diff -qr "$skill_dir" "$target" >/dev/null 2>&1; then
            printf 'Verified %s skill copy: %s\n' "$tool_label" "$target"
            continue
          fi

          if [ "$keep_existing" -eq 1 ]; then
            kept=$((kept + 1))
            printf 'Keeping existing %s skill copy: %s\n' "$tool_label" "$target"
            continue
          fi

          backup_dir="$target_dir/.ai-toolkit-backups/$backup_stamp"
          backup_target="$(move_to_backup "$target" "$backup_dir" "$skill_name")"
          copy_skill_snapshot "$skill_dir" "$target"
          updated=$((updated + 1))
          printf 'Moved existing %s skill to backup: %s\n' "$tool_label" "$backup_target"
          printf 'Copied %s skill: %s\n' "$tool_label" "$target"
          continue
        fi

        copy_skill_snapshot "$skill_dir" "$target"
        copied=$((copied + 1))
        printf 'Copied %s skill: %s\n' "$tool_label" "$target"
        continue
      fi

      desired="$current_link/skills/$category_name/$skill_name"

      if [ "$verify_only" -eq 1 ]; then
        [ -L "$target" ] || fail "$tool_label skill is not a symlink: $target"
        link_target="$(readlink "$target")"
        [ "$link_target" = "$desired" ] || fail "$tool_label skill points at $link_target, expected $desired"
        [ -f "$target/SKILL.md" ] || fail "$tool_label skill link does not resolve to SKILL.md: $target"
        continue
      fi

      if [ -L "$target" ]; then
        link_target="$(readlink "$target")"
        if [ "$link_target" = "$desired" ] && [ -f "$target/SKILL.md" ]; then
          printf 'Verified %s skill link: %s\n' "$tool_label" "$target"
        else
          replace_symlink "$desired" "$target"
          repaired=$((repaired + 1))
          printf 'Repaired %s skill link: %s -> %s\n' "$tool_label" "$target" "$desired"
        fi
        continue
      fi

      if [ -e "$target" ]; then
        if [ "$keep_existing" -eq 1 ]; then
          kept=$((kept + 1))
          printf 'Keeping existing non-symlink %s skill: %s\n' "$tool_label" "$target"
          continue
        fi

        backup_dir="$target_dir/.ai-toolkit-backups/$backup_stamp"
        backup_target="$(move_to_backup "$target" "$backup_dir" "$skill_name")"
        create_symlink "$desired" "$target"
        migrated=$((migrated + 1))
        printf 'Moved existing %s skill to backup: %s\n' "$tool_label" "$backup_target"
        printf 'Linked %s skill: %s -> %s\n' "$tool_label" "$target" "$desired"
        continue
      fi

      create_symlink "$desired" "$target"
      linked=$((linked + 1))
      printf 'Linked %s skill: %s -> %s\n' "$tool_label" "$target" "$desired"
    done
  done

  [ "$found" -eq 1 ] || fail "No canonical skills found under $source_dir"

  if [ "$verify_only" -eq 1 ]; then
    if [ "$install_mode" = "copy" ]; then
      printf 'Verified %s personal skill copies successfully.\n' "$tool_label"
    else
      printf 'Verified %s personal skill links successfully.\n' "$tool_label"
    fi
  elif [ "$install_mode" = "copy" ]; then
    printf 'Finished %s personal skill copy install: copied=%s updated=%s kept=%s\n' \
      "$tool_label" "$copied" "$updated" "$kept"
  else
    printf 'Finished %s personal skill install: linked=%s repaired=%s migrated=%s kept=%s\n' \
      "$tool_label" "$linked" "$repaired" "$migrated" "$kept"
  fi
}
