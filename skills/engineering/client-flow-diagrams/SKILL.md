---
name: client-flow-diagrams
description: Create or revise high-level flow diagrams for client or non-technical audiences. Use when the user needs a workflow, process, integration, or system-interaction diagram that communicates business-level behavior without exposing implementation details.
---

# Client Flow Diagrams

Produce diagrams that help non-technical audiences understand a process — not engineers understand a system.

## Trigger

**Use this skill when:**
- Creating or revising a business-level workflow, process, or integration diagram for a client or stakeholder
- Translating technical documentation (ADRs, architecture notes, code flows) into a client-safe diagram
- The audience includes business owners, product managers, client representatives, or non-technical staff
- The diagram needs to show system interactions, decision points, or phase boundaries without code-level detail

**Do not use this skill when:**
- Creating detailed implementation architecture for developers
- Documenting code-level control flow (use a developer-facing ADR instead)
- The user only needs an internal engineering diagram
- A diagram would not improve communication over plain text

## Workflow

### 1 — Clarify before diagramming

Confirm or ask:
- **Audience**: Who will read this? What is their technical background?
- **Purpose**: What decision or understanding should the reader leave with?
- **Scope**: Which systems, phases, and boundaries are in and out of scope?
- **Detail level**: Does the reader need error paths and decision points, or just the happy path?

When source material is technical (ADRs, code, API docs), treat it as confirmed. Treat your own inferences about business meaning as assumptions — flag them and ask when uncertain.

### 2 — Identify actors, systems, and boundaries

Extract from source material:
- **Actors**: Who or what initiates the flow?
- **Systems**: What systems participate? Group them into swimlanes.
- **Phases**: Are there distinct sequential phases? Split into multiple diagrams when a single one exceeds ~8 nodes.
- **Decisions**: What Yes/No branch points affect the outcome?
- **Boundaries**: Where does one system hand off to another?

### 3 — Produce the diagram

#### Choose the output format

| Situation | Format |
|-----------|--------|
| Quick draft, developer-readable source, no layout constraints | **Mermaid `flowchart TD`** |
| Client requires equal-height columns, or labels above frame borders | **draw.io XML** (user opens in app.diagrams.net, exports SVG/PNG) |

**Mermaid routing note:** Mermaid's `curve` init setting applies uniformly to all edges — no per-edge routing control exists. The `step` option adds right-angle turns to every connection including simple verticals. Explain this if the user asks for selective right-angle routing. Mermaid also cannot enforce equal subgraph heights or place labels outside the frame border — switch to draw.io when either is needed.

---

#### Mermaid output

Use swimlane subgraphs to show system ownership:
```
subgraph SystemName["System Label"]
    ...
end
```

Apply consistent visual differentiation between node types: at minimum distinguish process steps, decision points, success outcomes, and error outcomes. Specific `classDef` colour values and other conventions are recorded in `lessons.md` as candidate patterns pending further validation.

When colour or shape carries meaning, add an in-picture legend: a separate `subgraph` block (e.g. `subgraph Legend["Legend"]`) containing one node per node type, styled with the same `classDef` classes used in the flow, deliberately left with no edges connecting it to the rest of the diagram — it reads as a key, not a flow step. Validated across two independent sessions (2026-06-08; 2026-09-03, a carrier PIN-distribution flow-diagram redesign).

---

#### draw.io XML output

Produce a `.drawio` file when precise layout control is required. Keep frame
heights, label placement, node styling, and edge routing visually consistent.
Use explicit waypoints when auto-routing causes overlaps or crosses
text-bearing shapes. Include a legend when colour or shape carries meaning.

See `lessons.md` for candidate draw.io styles and routing patterns. Treat their
exact coordinates, colours, spacing, and proactive format-selection heuristics
as starting points until repeated use validates them.

### 4 — Add explanations below each diagram

Include:
- What each key decision means in plain language
- Important edge cases (e.g. partial failure behaviour)
- A cross-reference to technical documentation for readers who need more depth

### 5 — Review before delivering

See `review-checklist.md`. Key checks:
- No internal class names, method names, or HTTP status codes visible
- No jargon that requires developer context — replace with business language
- No single diagram with more than ~8–10 nodes — split if needed
- Error paths traceable and concisely labelled

**Rendering check:** Never hand over generated Mermaid source without rendering (or re-rendering) it after every edit — source that parses is not source that renders correctly. When no renderer is available, fall back to structural text-checks (matching brackets/quotes, `classDef` references, `subgraph`/`end` balance). Once a rendering gotcha is found mid-session (e.g. a box-title fill-colour conflict), treat it as a standing check applied to every new element added for the rest of that session. (Observed 2026-09-03; reinforced 2026-09-04, 2026-09-08.)

## Signs this skill needs revision

- Diagrams regularly require jargon cleanup after delivery
- Clients consistently ask for more or less detail than the workflow produces
- A better Mermaid option becomes available for per-edge routing control
