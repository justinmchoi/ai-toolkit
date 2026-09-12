# Layered Ownership Baseline

Status: active
Version: 0.3.0

This is a tool-neutral always-on baseline for AI agents working inside a
multi-repo personal system. It keeps decision records where they belong and
prevents any single repo from drifting into a central governance hub.

## Principles

1. Each layer records its own decisions.
   A repo's roadmap, status entries, and decision records cover only the
   assets that repo owns. Another layer's merge plans, status changes, or
   boundaries are recorded in that layer's own documents.

2. Cross-layer references are pointers, not ownership.
   When another layer's state matters, link to the owning repo's artifact
   ("governs itself in X") instead of duplicating or governing it.

3. Identify the owner before writing.
   Before recording a status or decision entry, ask which layer owns the
   affected asset, and write the entry there — even when the current session
   happens to be in a different repo.

4. No central governance hub.
   If a document starts mirroring another repo's changes, that is the
   hub pattern re-forming: stop, move the content to its owner, and leave a
   pointer behind.

5. Use the layer's own intake path when creating a durable artifact, not the
    fastest generator to hand.
    When asked to turn a session pattern into a skill or baseline "for future
    reuse", check first whether the environment already has a structured
    capture -> review -> promote pipeline — a capture skill plus an
    improvements inbox, or an instruction file pointing at a toolkit repo as
    source of truth, are the concrete signals. A skill generator produces a
    finished, immediately-live artifact in an ungoverned personal folder, with
    no review step and no check on whether the content is company-identifying
    and therefore belongs to a different layer entirely. Prefer the pipeline,
    or ask which the user meant; "for future reuse" and "as a baseline" are the
    phrases that distinguish it from a genuinely one-off local convenience
    command, which the generator still suits. The distinguishing signal is that
    language *plus* the pipeline existing — either alone is not enough.
    _(added 2026-09-11, from `default-to-improvement-extraction-over-skill-creator-when-capturing-a-session-pattern`)_

## Origin

Authored 2026-07-03 after a real violation: capture-layer merge decisions
were written into `ai-toolkit`'s roadmap, silently recreating the
governance-hub pattern the operator had frozen out of
`ai-ops-ecosystem-spec` the day before. The operator's boundary is explicit:
the second-brain system must never be mixed with the skills and specs
layers.

## Managed Block

The pack applies one managed block per instruction file through the standard
baseline CLI. The block can be updated or removed without rewriting
surrounding repo-specific instructions.
