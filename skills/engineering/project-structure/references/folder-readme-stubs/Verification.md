<!-- Scaffolded by the `project-structure` skill. This folder is pre-created empty on purpose:
     the convention names it, so every project has it in the same place under the same name and no
     session has to invent one. An empty folder here is not clutter to clean up. -->

# Verification

The completion gates for this project's work, and the scripts that check them.

Two things live here:

- **A gated checklist**, written *before* the work starts — criteria in
  dependency order, numbered so they are citable from a plan or a failure
  report, each tagged automated or manual. Manual ones carry the exact command,
  so they are runnable rather than aspirational. `SKIP` is reported distinctly
  from `PASS` and never counts toward a green total.
- **A claim suite** — one check per load-bearing factual claim the project's
  documents make, each owning the falsifying command rather than the conclusion.
  Negative claims included; they are the weakest thing in any research document
  and the easiest to re-check.

Keep a `run-log.md` of the runs, failures included: what broke once is what tells
the next reader which criteria are actually load-bearing.
