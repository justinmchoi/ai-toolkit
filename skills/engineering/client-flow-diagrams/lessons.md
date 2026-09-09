# Lessons — client-flow-diagrams

Append one entry per real use. Sanitize: no client names, confidential data,
raw conversations, credentials, or unnecessary project details.

Promote a takeaway into SKILL.md only when:
- it addresses a serious correctness or confidentiality risk; or
- it has been validated across multiple uses; or
- the user explicitly approves the change.

---

## 2026-06-08 — Initial session (first use)

**Task context:**
Translating developer-facing technical architecture documents (class hierarchies,
flow trees, design decisions) into business-level flow diagrams for a
non-technical stakeholder audience.

**Mistakes and weaknesses observed:**

1. **Technical jargon not proactively stripped in first draft.**
   The first diagram draft carried over vocabulary from the source material
   (internal class names, HTTP status codes, method signatures). A revision pass
   was needed after the user pointed them out.
   — *Cause*: Defaulted to source vocabulary without applying a client-safety
   filter first.
   — *Takeaway*: Before writing any node label, ask "would a non-developer
   understand this without context?" Strip class names, method names, and status
   codes by default.
   — *Reusable*: Yes.
   — *Status*: Reflected in Step 5 (review checklist) in SKILL.md. Kept because
   it is a correctness risk for the deliverable, not a stylistic preference.

2. **`step` curve applied globally produced excessive right-angle turns.**
   The `%%{init: {"flowchart": {"curve": "step"}}}%%` directive was added after
   the user asked for right-angle lines. The user then found that simple vertical
   connections also acquired unnecessary horizontal jogs.
   — *Cause*: Mermaid's curve setting applies to all edges uniformly; per-edge
   routing control does not exist. The user's intent was "right angles only at
   branches," not "right angles everywhere."
   — *Takeaway*: Explain the limitation before applying any curve setting. The
   default routing draws straight segments for aligned nodes and only bends where
   the layout needs it.
   — *Reusable*: Yes.
   — *Status*: Reflected in Step 3 of SKILL.md as a factual note about Mermaid's
   routing behaviour (not a prohibition — the tone was softened during the
   lifecycle correction on 2026-06-08).

3. **Lifecycle correction — 2026-06-08.**
   Several first-session stylistic preferences were incorrectly promoted into
   SKILL.md at creation time. They have been moved back to lessons.md pending
   further validation. The preferences were:
   - Specific `classDef` hex colour values for process/decision/success/error/neutral
   - Emoji in swimlane subgraph labels
   - Step numbers (`Step N —`) prefixed to node labels
   - Visual Mermaid legend (standalone small diagram) preferred over a markdown table
   - Document header table (Version, Status, Audience, Related) for formal deliverables
   - Prescriptive output structure ordering (header → overview → legend → diagrams →
     notes → comparison → cross-reference)
   — *Why demoted*: Each was observed and approved in a single session. None
   represents a correctness or confidentiality risk. All are candidate patterns,
   not validated conventions.
   — *Promote when*: validated across multiple uses or explicitly approved.

**Successes observed (confirmed, not yet promoted):**

The following choices were accepted or explicitly approved in the first session.
They are candidate patterns — record further evidence before promoting to SKILL.md.

- **Colour-coded nodes** (blue process / yellow decision / green success / red
  error / grey neutral). Specific classDef values used:
  ```
  classDef process  fill:#CCE5FF,stroke:#0D6EFD,color:#000
  classDef decision fill:#FFF3CD,stroke:#FFC107,color:#000
  classDef success  fill:#D4EDDA,stroke:#198754,color:#000,font-weight:bold
  classDef error    fill:#F8D7DA,stroke:#DC3545,color:#000
  classDef neutral  fill:#E9ECEF,stroke:#6C757D,color:#000
  ```
  User approved without requesting changes. *Observed once.*

- **Step numbers in node labels** (`Step N —` prefix). User described them as
  "explicit & nice." *Observed once.*

- **Visual Mermaid legend** (small standalone diagram showing all node types with
  actual colours). Replacing a markdown colour table was accepted without
  pushback. *Promoted to SKILL.md Step 3 (2026-09-03).* Independently observed
  twice: 2026-06-08 (this session, as a standalone legend diagram) and
  2026-09-03 (Rogers E-Pin flow-diagram redesign, formalized as an in-picture
  legend built from a disconnected Mermaid subgraph — see the 2026-09-03 entry
  below). Two independent dated observations cleared this skill's promotion
  bar; see SKILL.md Step 3, Mermaid output, for the promoted pattern.

- **Emoji on swimlane headers and outcome nodes** (✅ / ❌). User explicitly
  asked for icons and accepted the placement without revision. *Observed once.*

- **Splitting into two diagrams** when a single flow has distinct sequential
  phases. A two-phase split kept each diagram digestible.
  User did not ask to recombine them. *Observed once.*

- **Document header table** (Version, Status, Audience, Related) for formal
  deliverables. User accepted it as making the document "formal enough."
  *Observed once.*

**Open questions after this session:**
- Should the review checklist be applied silently, or shown to the user for
  sign-off before delivery?
- Is a comparison table (two flows side by side) always useful, or only when the
  user explicitly asks to compare them?

---

## 2026-06-10 — Second session (draw.io output format)

**Task context:**
Activation business flow diagrams for a client-facing ADR involving two related
brands. Two swimlane diagrams, 4 columns each. The client identified that Mermaid
frames were unequal heights and the frame labels were inside the borders.

**Mistakes and weaknesses observed:**

1. **Mermaid cannot produce equal-height swimlane frames or external frame labels.**
   The user noticed visual inconsistency: Mermaid renders each subgraph just tall
   enough for its content, so columns with fewer nodes are shorter than those with
   more. Frame labels also render inside the border, not above it.
   — *Cause*: Mermaid subgraph layout is fully automatic; no height or label-position
   overrides exist.
   — *Takeaway*: When the deliverable requires precise visual polish (equal column
   heights, labels above borders), generate draw.io XML instead of Mermaid. The user
   opens the file in app.diagrams.net and exports as SVG/PNG.
   — *Reusable*: Yes — this is a hard Mermaid limitation.
   — *Status*: Promoted to SKILL.md Step 3 as the output-format decision rule.

2. **draw.io edge routing: overlapping lines when multiple edges share the same target.**
   First-pass XML produced 5 "No" edges all converging on a single SF_ERR node,
   each using the default orthogonalEdgeStyle with no waypoints. All five rendered
   on top of each other.
   — *Cause*: Without explicit waypoints, draw.io's auto-router assigns no spacing
   between parallel edges going to the same target.
   — *Takeaway*: Each "No" edge needs its own dedicated vertical spine in the
   routing gap (staggered x: 295, 275, 255, 235, 215 — 20 px apart). Add staggered
   entryY values on the target (0.15, 0.25, 0.35, 0.45, 0.55) so arrow-tips don't
   pile on the same point.
   — *Reusable*: Yes — applies whenever 3+ edges converge on one node.
   — *Status*: Candidate pattern pending repeated validation.

3. **draw.io edge routing: auto-router crossed through text-bearing shapes.**
   Without waypoints, the router chose paths that passed through the interior of
   shapes that contained text.
   — *Cause*: Orthogonal auto-routing computes paths at render time and doesn't
   always avoid shapes, especially when multiple edges compete for the same corridor.
   — *Takeaway*: Reserve a wide routing gap (≥100 px) between the leftmost column
   caller column and the logic column. Route all "No" edges exclusively through
   this gap with explicit waypoints. "Yes" paths exit the diamond bottom
   straight down — no waypoints needed.
   — *Reusable*: Yes.
   — *Status*: Candidate pattern pending repeated validation.

4. **No legend in first draft.**
   The user asked for a legend explaining colour and shape meanings. Without it,
   readers cannot interpret the visual encoding without prior context.
   — *Cause*: Legend was not in the original skill workflow for this format.
   — *Takeaway*: Always include a Legend container when colour-coded shapes are used
   (already required by review-checklist.md, but now also required in the generate
   step, not just the review step).
   — *Reusable*: Yes.
   — *Status*: Kept as a general review rule; exact legend structure remains a
   candidate pattern.

**Successes observed (confirmed, not yet promoted):**

- **draw.io swimlane container style for borderless frames:**
  `swimlane;startSize=0;fillColor=none;strokeColor=#888888;strokeWidth=2;`
  with a separate `text` label cell above the container (y=40, container y=78).
  Accepted without revision. *Observed once.*

- **R1→SF_OK "below-content" routing pattern for long cross-column return edges:**
  When a rightmost-column node must connect back to a leftmost-column node, and
  the gap area is occupied by vertical spines, routing the edge at y = frame_bottom
  + 30 (below all frame content) keeps it from crossing any spine. *Observed once.*

**Open questions after this session:**
- When should the user be recommended to use draw.io vs Mermaid upfront, before
  the layout problem appears? Possible heuristic: ≥3 columns with uneven node
  counts → recommend draw.io proactively.

---

## 2026-06-12 — Third session (response-path correction + v2 pattern validation)

**Task context:**
Revising related client-facing draw.io diagrams after a response-path service
was initially modeled as a request-relay. The user created corrected v2 files
manually in draw.io, which became validation evidence for several XML routing
patterns.

**Architecture correction — response-path services are not request-relays:**
The caller sends the request to the processing system directly. The processing
system returns the result through the response-path service, which transforms
or hands the result back to the caller.
— *Impact*: The response-path service swimlane sits between the caller and the
  processing system, but its node belongs at the bottom of the lane on the
  response side. Its only edges are processing system → response-path service
  and response-path service → caller.
— *Independent confirmation flow*: Omit the response-path service swimlane when
  it does not participate. Do not add an unused swimlane "for consistency";
  an unused swimlane is worse than no swimlane.

**Mistakes observed:**

1. **Absolute label offsets break when nodes move.**
   First version used `x="-15" y="-244"` style absolute pixel offsets for "No"
   edge labels. These are correct only at the exact node positions used at authoring
   time — any node shift breaks label placement.
   — *Fix*: Use relative label offsets such as
   `<mxGeometry relative="1" x="-0.75" y="-17">` with
   `<mxPoint as="offset" />`. `x` is proportional along the edge and `y` is a
   perpendicular pixel nudge.
   — *Critical detail*: `<mxPoint as="offset" />` is **required**. Without it,
   draw.io ignores the relative positioning entirely.
   — *Status*: Validated by user's v2 correction. Strong candidate for promotion.

2. **Single waypoint for cross-column bends is ambiguous.**
   Used one waypoint per bend between two non-adjacent columns. draw.io can
   re-route the edge on reload with a single waypoint as a suggestion, not a
   constraint.
   — *Fix*: Use two waypoints per bend: one at the source node's y-level in the
   inter-column gap, one at the target node's y-level in the same gap.
   — *Status*: Validated by user's v2 correction. Candidate for promotion.

3. **Return path exit at center (exitY=0.5) creates visual ambiguity.**
   When an external-system node has both an incoming and an outgoing edge, using
   `exitY=0.5` puts the outgoing arrow at exactly the same height as the
   incoming. At a glance, the two arrows look like a single pass-through edge.
   — *Fix*: Use `exitY=0.75` plus two explicit waypoints (source y-level then target
   y-level in the gap) so the outgoing arrow exits visibly lower than the incoming.
   — *Status*: Validated by user's v2 correction. Candidate for promotion.

4. **Over-routing via a gap when a straight path is available.**
   Used two waypoints routing through an inter-column gap for an edge whose
   target was directly accessible from the source column center.
   — *Fix*: Use a single waypoint at the target's y-level directly below the
   source column center.
   — *Principle*: Fewer waypoints → more robust. Only add waypoints where
   auto-routing would produce a visually confusing result.
   — *Status*: Validated by user's v2 correction. Candidate for promotion.

5. **Cross-swimlane return edge: match entry side to waypoint direction, and prefer the fewest turns.**
   A return edge first used two waypoints routing left and then up, creating
   three segments and two turns. Switching the entry side reduced ambiguity but
   still kept an unnecessary turn.
   — *Best fix*: One waypoint directly below the source at the target's y-level,
   with `entryX=1;entryY=0.5`. Path: source bottom → straight down to target
   y-level → straight left to target right side. Single turn.
   — *General rule*: For a long cross-swimlane return edge, use `exitX=0.5;exitY=1`
   (bottom center of source), drop with one waypoint to the target's y-level directly
   below the source, then enter from the right (`entryX=1;entryY=0.5`). One waypoint,
   one turn.
   — *Avoid*: Routing via an intermediate y that is above the target — it forces a
   third segment going back up, adding an unnecessary turn.
   — *Status*: Validated immediately on use.

**Successes observed:**

- **Colour-coded "No" edge labels with matching strokeColor/fontColor.** Using a
  distinct color per error condition persisted correctly through the v2
  validation. *Observed across multiple sessions.*

- **Stable column x-coordinates for a precise draw.io layout.** Keeping fixed
  column widths and gap centers made follow-up XML edits predictable. The exact
  coordinates remain project-specific; the reusable lesson is to define a small
  coordinate grid before drawing many edges. *Validated by v2.*

- **Response-path node at bottom of swimlane.** The response-path service node
  sits at the very bottom of its lane, aligned with success outcomes in adjacent
  lanes. This makes the response path visually coherent: everything flows down
  and then back left to the caller. *Validated by v2.*

**Open questions after this session:**
- When source is an auto-save draw.io file with auto-generated IDs, should we
  normalize to semantic IDs when copying to the canonical source file? Answer
  used: yes — semantic IDs make future XML edits much less error-prone.

---

## 2026-06-10 — Second session (continued — edge clarity refinements)

**Additional mistakes observed:**

5. **Shared connection point on a node caused two edges to appear as one.**
   Two edges to and from the same data-store node both used
   `entryX=0;entryY=0.5` / `exitX=0;exitY=0.5` — the same pixel on the node's
   left face. Their approach and departure segments overlapped visually, making
   it look like a single through-edge rather than two separate read/write
   operations on the data-store node.
   — *Cause*: Default `entryY=0.5` / `exitY=0.5` assigns both edges the exact same
   connection point. draw.io overlaps the terminal segments with no visual separation.
   — *Fix*: Stagger `entryY` / `exitY` on the shared face (e.g., entering edge at
   `entryY=0.3`, departing edge at `exitY=0.7` — 32 px apart on an 80 px face).
   Update explicit waypoints in the shared routing corridor to reflect the new y-values
   so paths through intermediate columns stay visually parallel and distinct.
   — *Status*: Candidate pattern pending repeated validation.

6. **Label proximity alone is insufficient when multiple edges share a routing corridor.**
   After positioning "No" labels near their source diamonds with `mxPoint as="offset"`,
   4 labels still clustered at similar x-positions in the 100 px gap. Users could not
   reliably trace which label belonged to which line without visually following each
   path across the spine.
   — *Cause*: When many edges share a corridor (parallel vertical spines in the gap),
   their labels converge in a small x-zone even if each label is near its own source.
   A supplementary visual cue can help link a label to its line when position
   alone is insufficient.
   — *Fix*: Add `strokeColor=<color>;fontColor=<color>;` to each "No" edge style,
   using a distinct color per decision (e.g., dark blue, orange, purple, teal, brown).
   The line and its label share the same color, while clear labels, spacing, or
   line styles preserve the association without relying on color alone.
   — *Status*: Candidate pattern pending repeated validation.

**Additional successes observed (confirmed, not yet promoted):**

- **`mxPoint as="offset"` for edge label positioning.** Adding `<mxPoint x="dx" y="dy"
  as="offset"/>` inside an edge's `mxGeometry` shifts the label by (dx, dy) pixels from
  draw.io's auto-computed midpoint. Effective for moving labels to the first segment of
  an L-shaped edge. *Observed once — requires per-edge calculation of the path midpoint.*

- **Exact entryY/exitY to produce horizontal inter-column edges.** When source and target
  center y-values differ, `orthogonalEdgeStyle` adds a visible jog. Computing
  `entryY = (desired_y − node_top) / node_height` forces the entry point to match the
  source exit y exactly, producing a clean horizontal segment. *Observed once.*

---

## 2026-09-03 — Fourth session (Rogers E-Pin flow-diagram redesign)

**Task context:**
Redesigning a client-facing Mermaid flow diagram for a Rogers E-Pin integration,
with multiple rounds of layout and legend revisions within the same session.

**Successes observed (validated):**

- **In-picture legend as a disconnected Mermaid subgraph — confirmed a second
  time.** Built the legend as its own `subgraph` block, styled with the same
  `classDef` classes as the flow, with no edges connecting it to the rest of
  the diagram. Accepted without pushback, independently of the 2026-06-08
  session that first tried this.
  — *Status*: Two independent dated observations (2026-06-08, 2026-09-03)
  clears this skill's promotion bar. **Promoted to SKILL.md Step 3** (Mermaid
  output). See the 2026-06-08 entry above, now marked promoted.

**Mistakes and weaknesses observed:**

1. **Handed over Mermaid source without re-rendering after an edit.**
   A source edit was handed over without rendering it first; the edit had
   introduced a problem that only showed up at render time, not by reading the
   source text.
   — *Cause*: Treated a text edit as self-evidently correct because it "looked
   right" in the source.
   — *Takeaway*: Never hand over generated Mermaid source without
   rendering/re-rendering it after every edit. When no renderer is available,
   fall back to structural text-checks (matching brackets/quotes, `classDef`
   references actually defined, `subgraph`/`end` balance). Once a rendering
   gotcha is found mid-session, treat it as a standing check applied to every
   new element added for the rest of that session.
   — *Reusable*: Yes.
   — *Status*: Reinforced 2026-09-04 and 2026-09-08 (a box-title fill-colour
   conflict was the concrete gotcha found on reinforcement). **Promoted to
   SKILL.md Step 5** (Review before delivering) as a standing rendering check.

2. **Assumed subgraph declaration order and `~~~` invisible-edge hints control
   left-right column position.**
   Reordered subgraph declarations and added `~~~` invisible edges to try to
   move a node's column relative to its sibling; the rendered layout did not
   change.
   — *Cause*: Mermaid's dagre/ELK flowchart layout engine ignores subgraph
   declaration order and invisible-edge hints for column/cluster left-right
   positioning. The only real lever for two sibling nodes' relative position is
   their declaration order within a shared subgraph.
   — *Takeaway*: Don't rely on cross-subgraph declaration order or `~~~` edges
   to fix column position — reorder the nodes within their shared subgraph
   instead, and verify any layout fix by rendering (cropped/zoomed), never by
   assuming the source change worked.
   — *Reusable*: Yes.
   — *Status*: Observed once (mermaid-cli ~11.17.0). Candidate pattern pending
   a second independent observation before promotion.

**Open questions after this session:**
- Does the dagre/ELK ordering limitation hold across other Mermaid renderers
  (not just mermaid-cli ~11.17.0), or is it specific to that engine/version?
