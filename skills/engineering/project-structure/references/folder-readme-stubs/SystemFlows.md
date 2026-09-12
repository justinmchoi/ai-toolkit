<!-- Scaffolded by the `project-structure` skill. This folder is pre-created empty on purpose:
     the convention names it, so every project has it in the same place under the same name and no
     session has to invent one. An empty folder here is not clutter to clean up. -->

# System Flows

Code-level flow and lifecycle reference: one file per distinct flow, each with a
class diagram plus a sequence diagram (or the equivalent), built by deliberate
exploration and kept current.

Parallel to `Glossary/` but one layer down — business/domain *terms* there,
code-level *processes* here. ASCII diagrams survive a plain diff; prefer them
over images.

A subfolder (e.g. `lifecycles/`) is right when a genuinely different grain of the
same subject matter appears — per-flow detail vs. cross-flow caller journeys.
