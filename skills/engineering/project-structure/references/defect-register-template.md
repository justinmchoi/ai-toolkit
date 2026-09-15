# Defect register

> **Read this before presenting any defect, gap or risk as newly found.** In a system
> someone has worked in for months, the prior is that anything findable in an afternoon
> has already been found. This file exists so that check does not require already
> suspecting there is something to find — grepping the notes only works once you know
> the symbol to grep, and you learn that at the *end* of a trace, not the start.
>
> This is **not a bug tracker**. No priorities, no assignees, no dates beyond the links.
> The moment it wants those fields, the defects belong in the real tracker and this
> register should point at them.

## Known defects

Rows sit under the **root cause they share**, not in date order. Grouping is what makes a
proposed fix immediately checkable against its siblings; a chronological list gets each
one re-derived on its own, and re-derivation reliably misses the siblings that would
have arrived free.

`Work item` records `None recorded` as a real value. An undocumented defect at least
*looks* undocumented; one written up in prose but never filed looks **handled**, and
reads as closed to everyone who finds the file. State how the column was checked — e.g.
"no tracker ID appears in the writeup", which is a grep, not a tracker query — rather
than claiming the item does not exist.

### Root cause: *(name the shared cause, e.g. "query scoped by one ID that needs three")*

| # | Defect | Writeup | Work item | Status | Fires in production? |
|---|---|---|---|---|---|
| 1 | *(one line)* | `Bugs/YYYY-MM-DD-slug.md` | None recorded *(grep: no tracker ID in the writeup)* | Open | Observed YYYY-MM-DD |

### Root cause: *(next group)*

| # | Defect | Writeup | Work item | Status | Fires in production? |
|---|---|---|---|---|---|
| | | | | | |

## Mitigations

A guard in a downstream tool and a fix to the defect are not the same thing, and this is
where that distinction survives after everyone has forgotten which one shipped.

| Mitigation | Covers | **What this still does not do** |
|---|---|---|
| *(e.g. a validation guard in the support tool)* | *(defects #1, #4)* | *(does not fix the underlying query; anything writing through the API is unaffected)* |

## Audit

The register makes "written up but never filed" countable for the first time. Periodically
list every row whose work item is `None recorded` **and** whose status is `Open` — that is
a concrete backlog, and on a register's first pass it is usually most of the table.
