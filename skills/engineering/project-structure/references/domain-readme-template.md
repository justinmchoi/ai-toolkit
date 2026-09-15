# Domain — how this project's subject matter works

> **Purpose:** everything about *how the subject matter works* — the vocabulary, the
> way the pieces interact, and the defects already known about. Read `01-big-picture.md`
> to learn it from zero, `00-executive-summary.md` to explain it to someone else, and
> `02-defect-register.md` before tracing any suspected bug. `Terms/` answers "what does
> this word mean"; `Scenarios/` answers "what happens when I do X".
>
> ## Reading order
>
> | File | Read it when |
> |---|---|
> | `00-executive-summary.md` | you need to explain this domain to someone else (LOCKED once verified; 1000-word cap) |
> | `01-big-picture.md` | you are learning it from zero |
> | `02-defect-register.md` | **before** presenting any defect as newly found |
> | `Terms/` | a single word needs defining |
> | `Scenarios/` | several terms interact and no one term answers the question |
>
> `Terms/` holds a quick-reference lookup for terms that come up in this project but
> aren't obvious from a software background alone — business/domain concepts,
> industry-specific concepts, and any vendor/partner's own protocol-specific
> vocabulary. Go here first when a term is used and you don't remember exactly what
> it means or why it matters. This is deliberately separate from a code repo's own
> `CONTEXT.md` (if one exists) — that file is the precise *code* domain glossary
> (entities, call boundaries); this one is "what does this business/domain term
> mean and why does this project care," written for someone without that
> background. Cross-reference both ways when a term has both a business meaning
> and a code representation.
>
> **One file per term** (not one growing file) — easier to link to from other docs
> (ADRs, implementation plans, tracker comments) and easier to scan the list below
> to see what's covered.

## Terms (`Terms/`)

| Term | File | One-line hook |
|---|---|---|
| *(add a row per term as it gets written)* | | |

## How to add a term

Term files live in `Terms/`; create that subfolder the day there is more than a handful of them, and keep them flat here until then. A composite write-up that no single term can answer — "how do A, B and C actually relate, and which one do I change?" — is a **scenario**, not a term: it goes in `Scenarios/`, created the day the first one is actually written rather than scaffolded empty.

New file, `kebab-case-term.md`, one row added to the table above. Cite the actual
source (spec section, entity file, tracker item, conversation with a domain expert,
a legacy doc) wherever possible — don't write from general knowledge alone if a
project-specific source exists, since a specific vendor/industry/team sometimes
uses a term in a narrower or different sense than general usage.

**When does a concept earn its own file, versus staying explained inline inside a
related term's file?** A concept graduates to its own file once it's a distinct
named entity/mechanism (not just a flag or field on another term — a boolean flag
that's literally a field on some other entity should stay inline there, not get
pulled out) referenced from two or more other term entries. If a term meets
that bar but doesn't have a file yet, say so explicitly right here in a line like
this — don't leave the gap silent. Periodically re-grep the existing files for
bolded/backticked terms that get referenced across more than one file but have no
entry of their own; that's exactly how a gap like this gets caught before it's been
silently missing for a while.
