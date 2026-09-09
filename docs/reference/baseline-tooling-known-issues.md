# Baseline Tooling: Known Issues & Workarounds

Status: known-issues log (2026-09-03, `baseline-gap-review` occurrence #2
re-apply step). These are bugs/gaps in this repo's own `scripts/baseline.ps1`,
the `iq-baseline` shim, and `pack.json`'s provenance schema — not baseline
*content* (principles), so they don't belong in a baseline pack. Logged here
as workarounds rather than fixed in-place; fix the underlying scripts in a
dedicated session if these keep costing time.

1. **`baseline status`'s pack table can silently omit a stale pack.**
   A pack that `baseline verify <pack-name>` correctly flags as stale/needing
   re-apply can be missing entirely from `baseline status`'s summary table,
   giving false confidence that everything is current. Workaround: after
   editing any baseline's content, run `baseline verify <pack-name>`
   explicitly for that pack — don't trust `status` alone.

2. **`baseline verify all` halts at the first missing/stale pack** instead of
   sweeping the full list and reporting every issue. Workaround: don't treat
   a `verify all` run as a complete health check by itself — loop
   `baseline verify <pack-name>` per pack manually (or confirm whether a
   continue-past-failures mode exists) when a full sweep is actually needed.

3. **`ai-toolkit`'s and `es-ai-toolkit`'s `baseline.ps1` scripts have
   diverged in CLI surface, not just in baseline content.** `es-ai-toolkit`'s
   copy lacks the `-Tools` parameter `ai-toolkit`'s has. Sibling operational
   scripts across the two toolkit repos need their own periodic API-drift
   check, the same way baseline *content* gets one (see
   `repo-context-grounding`'s build-gate-doctrine bullet and this skill's own
   step 2) — a content-only diff won't catch this.

4. **The `iq-baseline` shim mis-forwards/rejects the `-Tools` flag** even
   though the underlying `scripts/baseline.ps1` it wraps accepts it fine.
   This is a shim bug, not evidence the flag is unsupported — if `-Tools`
   seems to fail, try calling `scripts/baseline.ps1` directly before
   concluding the feature doesn't exist.

5. **`pack.json`'s provenance-field schema is inconsistent even within this
   repo** — some packs use `source: {title, repository, license,
   relationship}`, others use a flatter `origin: {note, relationship}`,
   and neither shape is documented as canonical. Read each pack's own
   `pack.json` first rather than assuming which shape it uses before writing
   a provenance update.
