> 🔒 **LOCKED YYYY-MM-DD.** Every claim below was verified against source or a live
> database on that date. **Do not edit without explicit approval from `<owner>`** —
> including "small" fixes, wording tidy-ups, and additions that stay inside the word
> budget. If something here is wrong or stale, say so and propose the change; do not
> apply it.
>
> **Budget: 1000 words. Current: NNN.**

# `<Project>` — executive summary

*Delete this line and everything above the lock banner once the page is actually locked;
until then, keep the banner out and treat the page as a working draft.*

## 1. Vocabulary

One line per term, no prose. If a term needs a paragraph, it needs a file in `Terms/`.

| Term | What it is |
|---|---|
| | |

## 2. The spine

The two or three relationships everything else hangs off. Not a list of entities — the
sentences that, once understood, make the rest follow.

## 3. Old flow vs new flow

Only where the system has been rewritten and both paths still exist. Side by side, so
the reader can see which names moved and which behaviour moved with them.

| | Old | New |
|---|---|---|
| | | |

## 4. One real scenario

Named and concrete, ideally a production example. One scenario the reader can hold.

## 5. What you can do, and how

Group by **job**, in the order work actually happens — the task someone is assigned, not
the API call. One small table per job. Name the **screen or command**, never a checkmark:
you cannot fill that cell without opening the tool, and that is where wrong assumptions
surface. Treat an unfillable cell as a finding. The `—`/`—` rows carry the most
information, because they are what *no* route can do.

### Job: *(e.g. onboard a carrier's products)*

| Step | Internal tool | Raw API | Note |
|---|---|---|---|
| | *(`Templates → Create Template`)* | *(`POST /v1/...`)* | *(the trap in this row)* |

## 6. Watch-outs

Numbered, ranked by how expensive getting each one wrong is — not by how likely it is.

1.

## 7. The one-sentence version

---

**Word gate.** Hard cap 1000 words; write to fit it *first*. When it genuinely will not
fit, raise by **100 words at a time** and state what the extra 100 bought — never
open-ended. Three escalations in a row means this is really two documents. Record the
`wc -w` count in the folder README so drift stays visible.
