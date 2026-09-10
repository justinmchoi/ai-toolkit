# CLAUDE.md

<!-- Project CLAUDE.md template. Keep it short — this file is always-on context for every
     session in this folder. Anything long belongs in 0000-INDEX.md or a story folder. -->

This is a **<documentation/research project, not a code repository | code repository>** — <no build,
no tests, no git | see below for build and test commands>. Everything here is <markdown notes plus
diagrams/screenshots> for <ticket/initiative, one line>.

## Start here

**Always read `0000-INDEX.md` first.** It's the map: which folder holds what, the "where do I find…"
quick-answer table, and the naming/placement conventions this project follows. Don't duplicate its
content here — it's kept current on its own.

## The one fact that saves the most time

<Optional but high value. The single thing a fresh session most often gets wrong: a misleading
name, a module that isn't where it looks like it should be, a term that means something narrower
here. Delete this section if there isn't one yet — add it the first time a session wastes an hour.>

## Known repo locations, for any question that needs source code examined

<Only if this project references code repos it doesn't contain.>

- `<RepoName>`, `<RepoName>` — `<absolute path>`
- `<RepoName>` — `<absolute path>`

These are the user's own local clones, often mid-work (uncommitted changes, a feature branch checked
out). **Never `git checkout` / `git reset --hard` / `git pull` on them.**

To read the current default-branch version of something without disturbing the checkout:

```sh
git -C <repo> fetch origin                                   # safe, doesn't touch the worktree
git -C <repo> show origin/<branch>:<path>                    # one file
git -C <repo> grep -n "<pattern>" origin/<branch> -- <path>  # search a tree without checking it out
git -C <repo> ls-tree -r --name-only origin/<branch> -- <path>  # list files, e.g. find a module
```

Confirm the default branch with `git -C <repo> branch -r` rather than assuming. Each repo may have
its own `CLAUDE.md`/`AGENTS.md`, plus per-module ones — **read those first before grepping blind**,
but trust `git ls-files` over prose when a repo's own docs describe its layout.

## <Tracker / API access>

<Only if this project needs an external system. Record the path that actually works and the ones
that don't — e.g. which MCP servers fail, which CLI is authenticated, which field holds the real
content, how to fetch attachments. This section repays itself the first time it's read.>
