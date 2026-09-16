#!/usr/bin/env python3
"""Edit a baseline pack's coupled files atomically.

A pack's version lives in four places and its three full adapters are
byte-identical by convention, so one logical change spans several files and a
partially-applied edit leaves a state `doctor` exists to forbid -- created by
the tool meant to maintain it.

This implements the validate-all-then-write discipline from
`documentation-craft` ("a multi-file transform validates every edit before
writing any of them"): every replacement across every file is resolved and
asserted in memory first, and nothing touches disk unless all of them matched
exactly the expected number of times. On any mismatch it prints every problem
and exits 1 having written nothing.

Version bumps are handled for you -- pass `new_version` and it rewrites
baseline.md's `Version:` line, every adapter's BEGIN marker (full and core) and
pack.json's `version` field together, which is the coherence `doctor` checks.

Usage: pack_edit.py <repo_root> <edits.json>

edits.json shape:
{
  "packs": [
    {
      "name": "git-collaboration-hygiene",
      "new_version": "0.13.0",
      "baseline": [ {"old": "...", "new": "...", "count": 1}, ... ],
      "adapters": [ {"old": "...", "new": "...", "count": 1}, ... ],
      "pack_json": [ {"old": "...", "new": "...", "count": 1}, ... ]
    }
  ]
}

Version bumps in baseline.md's `Version:` line, the adapters' BEGIN markers and
pack.json's "version" field are applied automatically when new_version is given.
"""
import json
import re
import sys
from pathlib import Path

ADAPTERS = ["CLAUDE.md.block", "AGENTS.md.block", "copilot-instructions.md.block"]
CORE = "CLAUDE.md.core.block"


def apply_edits(text, edits, label, errors):
    for i, e in enumerate(edits):
        old, new = e["old"], e["new"]
        want = e.get("count", 1)
        got = text.count(old)
        if got != want:
            errors.append(
                f"{label}: edit #{i} matched {got} time(s), expected {want}\n"
                f"    old starts: {old[:110]!r}"
            )
            continue
        text = text.replace(old, new)
    return text


def main():
    repo = Path(sys.argv[1])
    spec = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

    pending = {}   # path -> new content
    errors = []

    for pack in spec["packs"]:
        name = pack["name"]
        root = repo / "baselines" / name
        if not root.is_dir():
            errors.append(f"{name}: pack directory not found at {root}")
            continue
        ver = pack.get("new_version")

        # --- baseline.md ---
        bpath = root / "baseline.md"
        btext = bpath.read_text(encoding="utf-8")
        btext = apply_edits(btext, pack.get("baseline", []), f"{name}/baseline.md", errors)
        if ver:
            new_b, n = re.subn(r"(?m)^Version: .*$", f"Version: {ver}", btext)
            if n != 1:
                errors.append(f"{name}/baseline.md: Version: line matched {n} time(s), expected 1")
            btext = new_b
        pending[bpath] = btext

        # --- adapters (three full blocks, byte-identical by convention) ---
        adapter_edits = pack.get("adapters", [])
        rendered = None
        for fname in ADAPTERS:
            apath = root / "adapters" / fname
            if not apath.exists():
                errors.append(f"{name}: missing adapter {fname}")
                continue
            atext = apath.read_text(encoding="utf-8")
            if rendered is None:
                base = atext
            elif atext != base:
                errors.append(f"{name}: adapter {fname} is not byte-identical to CLAUDE.md.block")
            rendered = True
            out = apply_edits(atext, adapter_edits, f"{name}/adapters/{fname}", errors)
            if ver:
                out, n = re.subn(
                    rf"(<!-- BEGIN baseline:{re.escape(name)} )v[0-9.]+",
                    rf"\g<1>v{ver}",
                    out,
                )
                if n != 1:
                    errors.append(f"{name}/adapters/{fname}: BEGIN marker matched {n} time(s), expected 1")
            pending[apath] = out

        # --- core adapter, if the pack has one ---
        cpath = root / "adapters" / CORE
        if cpath.exists():
            ctext = cpath.read_text(encoding="utf-8")
            ctext = apply_edits(ctext, pack.get("core", []), f"{name}/adapters/{CORE}", errors)
            if ver:
                ctext, n = re.subn(
                    rf"(<!-- BEGIN baseline:{re.escape(name)} )v[0-9.]+",
                    rf"\g<1>v{ver}",
                    ctext,
                )
                if n != 1:
                    errors.append(f"{name}/adapters/{CORE}: BEGIN marker matched {n} time(s), expected 1")
            pending[cpath] = ctext
        elif pack.get("core"):
            errors.append(f"{name}: core edits given but no {CORE} exists")

        # --- pack.json ---
        ppath = root / "pack.json"
        ptext = ppath.read_text(encoding="utf-8")
        ptext = apply_edits(ptext, pack.get("pack_json", []), f"{name}/pack.json", errors)
        if ver:
            new_p, n = re.subn(r'"version": "[0-9.]+"', f'"version": "{ver}"', ptext, count=1)
            if n != 1:
                errors.append(f"{name}/pack.json: version field matched {n} time(s), expected 1")
            ptext = new_p
        try:
            json.loads(ptext)
        except json.JSONDecodeError as ex:
            errors.append(f"{name}/pack.json: result is not valid JSON - {ex}")
        pending[ppath] = ptext

    if errors:
        print("ABORTED - nothing written. {} problem(s):\n".format(len(errors)))
        for e in errors:
            print("  * " + e)
        sys.exit(1)

    for path, text in pending.items():
        path.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {len(pending)} file(s):")
    for path in pending:
        print("  " + str(path.relative_to(repo)))


if __name__ == "__main__":
    main()
