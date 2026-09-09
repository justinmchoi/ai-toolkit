# SQL Server Safety Baseline

Status: active
Version: 0.5.0

Always-on correctness rules for T-SQL an agent writes or hands off — diagnostic
queries, verification queries, and data-fix/backfill scripts against SQL
Server. Applies whether the script runs directly or is handed to a person
(DBA, teammate) to run against production.

Distilled from 2026-07 SQL Server data-recovery sessions where each of these
mistakes independently produced either a silent wrong answer (torn read,
false-positive verification) or a hung production query (non-sargable
predicate, unbounded scan).

## Principles

1. Scope NOLOCK away from LOB columns under concurrent writes.
   `NOLOCK` on a column class that can be modified in place across multiple
   pages (`nvarchar(max)`, `varchar(max)`, `xml`, and other LOB types) while
   the table is under concurrent writes can return a torn/inconsistent read.
   If a query needs `NOLOCK` for lock avoidance, either scope it to small
   fixed-size columns only, or use `READ COMMITTED SNAPSHOT` semantics instead
   when LOB columns must be read under load.

2. Never NOLOCK a completion/sign-off verification query.
   A query whose result is the literal basis for "did the fix work" — the
   query a human or agent reads to declare success — must never carry
   `NOLOCK`, even in a codebase culture that reaches for it by default. A
   false-positive success signal is worse than occasionally waiting on a
   lock. This is a narrow, role-based exception: the same table's ordinary
   diagnostic queries may still use `NOLOCK`.
   Reinforcement: an intentionally-NOLOCK/READ UNCOMMITTED diagnostic query's
   output is never proof that a fix actually committed. Check real
   commit/transaction state (`@@TRANCOUNT`) directly instead of reading a
   dirty-read query as confirmation.

3. A CTE is not a materialization boundary.
   SQL Server's optimizer can inline or merge a CTE with the statement that
   consumes it — a CTE does not guarantee "filter first, then process" order.
   When a downstream operation can throw or misbehave on a row that the CTE
   was meant to have already filtered out, materialize into a real temp table
   (`SELECT ... INTO #temp`) instead of relying on the CTE to have narrowed
   the set first.

4. Diagnostic SQL handed to a person must be sargable and range-bounded.
   Before handing ad-hoc diagnostic SQL to a user or DBA to run against
   production, check it for sargability — no `(@param IS NULL OR col =
   @param)` patterns that defeat index seeks — and confirm it's range-bounded:
   no unbounded scans on large or multi-tenant tables. Catch this before
   hand-off, not after it hangs.

5. A read-only verification script must contain zero mutating statements.
   A script named or positioned as "internal verification only" must be
   mechanically read-only — no `UPDATE`, `DELETE`, `INSERT`, `MERGE`, or a
   "guarded" transaction that could commit a write. This is enforced by what
   the script contains, not by a comment or convention describing its intent.

6. Share one predicate between a validation query and its paired mutation.
   A preview/validation query and the mutating statement it's meant to
   authorize should share one written filter condition — via a temp table of
   qualifying keys, a shared variable, or literal copy-paste — not two
   independently maintained copies that merely look equivalent. This makes
   the hand-off's safety guarantee provable, not coincidental.

7. Reassess an approved small-batch design before trusting it at a much
   larger real scale.
   When a script or design was validated against a small sample and the real
   target set turns out to be orders of magnitude larger, do not assume the
   design still holds. Re-derive the concrete thresholds explicitly — row
   count, lock count, batch size — before treating the design as still
   approved. SQL Server escalates a transaction to a table lock at roughly
   5,000 held row/page locks; a single guarded transaction that was safe for
   dozens of rows is not automatically safe for tens of thousands.

8. Before opening a new interactive `BEGIN TRANSACTION` left for human
   review, check `@@TRANCOUNT` first.
   A single `ROLLBACK` unwinds the entire nested transaction stack, while
   `COMMIT` only decrements nesting depth by one. Opening a new transaction
   without knowing the current nesting depth breaks the "commit/rollback
   each independently" mental model a human reviewer will bring to it —
   check `@@TRANCOUNT` before opening it, and account for the existing depth
   in how you instruct the reviewer to resolve it.

9. Before extending an existing shared table's schema through one
   schema-management pipeline (e.g. EF Core migrations), check whether a
   second, independent pipeline also declares that exact table.
   A legacy DACPAC/SQL project, another team's migration tool, or any other
   schema-management pipeline that could still deploy against the same table
   is a silent-drift or data-loss risk if it declares that table
   independently. If a second pipeline is still live, create a new table
   instead of extending the shared one.

10. To determine a table's true row-uniqueness or grain, query
    `sys.indexes`/`sys.index_columns` directly for the actual constraint.
    Don't infer uniqueness from column, table, or foreign-key names — a
    name suggesting a unique grain (e.g. a singular-sounding table or an
    `Id`-like column) is not evidence of an enforced constraint. Query the
    catalog views for the real answer.

11. Before writing raw SQL to repair a data-integrity gap in a live/shared
    environment, check whether the application already exposes a validated
    write endpoint/command for that exact operation, and prefer it.
    An existing app-level write path is already validated and sidesteps
    environment/server-identity uncertainty that raw SQL against a live
    environment carries. Reach for raw SQL only when no such endpoint or
    command exists for the operation.

12. A `Microsoft.Data.SqlClient` DLL-load failure (SNI native DLL, e.g.
    `DllNotFoundException`/`0x800700CE`) on a deeply-nested working-directory
    path is a Windows path-length artifact, not a code regression.
    OneDrive-synced folders are a common trigger for this because they add
    extra nested path segments. Re-verify from a short-path clone before
    treating the failure as a real regression.

13. Cast to `nvarchar(max)` before `REPLICATE()` when generating long T-SQL
    test strings.
    `REPLICATE()` on a plain `nvarchar` literal returns `nvarchar(4000)` by
    default and silently truncates its result to 4000 chars — when probing a
    length boundary (a CHECK constraint, an `nvarchar(max)` limit), this can
    make a correctly-working constraint look broken (a "200001-char" seed
    that's actually only 4000 chars passing where it should fail). Always
    `CAST` the seed literal to `nvarchar(max)` first.

14. Use a fixed decision table for local SQL Server fault injection when
    testing retry logic, not ad hoc trial and error.
    Given a target behavior to test, use: wrong DB name → error 4060,
    transient, connection-wide · unreachable IP/blocked port → error 10060,
    transient, connection-wide, recoverable mid-test by removing the block ·
    renamed table via `sp_rename` → error 208, permanent, isolated to one
    table · row lock + timeout → error -2, **not** transient by EF Core's own
    design · bad password → error 18456, permanent. When the chosen technique
    is a firewall block on loopback (app and SQL Server on the same machine),
    verify it actually took with `Test-NetConnection` first — Windows
    Firewall enforcement on loopback traffic is inconsistent enough that a
    block rule sometimes silently doesn't apply — or default to pointing the
    connection string at an unreachable IP instead, which avoids loopback
    ambiguity entirely. Specific to SQL Server and EF Core's
    `SqlServerTransientExceptionDetector`; needs re-deriving for other DB
    providers.

15. Local temp tables (`#temp`) are session-scoped.
    When re-running a multi-step script in pieces during manual testing,
    close and reopen the database connection rather than manually cleaning
    up temp tables, to guarantee a genuinely clean slate between runs.

16. An OR-chained `(colA = x AND colB = y)` diagnostic query needs every
    column checked for index support — if `colB` is unindexed, add a
    redundant `colA IN (...)` prefix so the optimizer gets a real seek path
    on the composite index.

## Priority

Apply this baseline before ordinary SQL-authoring habits, but never use it to
override explicit user instructions, safety rules, privacy boundaries, or
stricter repo-local instructions.

## Non-Goals

- This does not cover general T-SQL style, indexing strategy, or schema
  design.
- This does not replace a DBA review for genuinely high-risk production
  changes.
- This does not define the backfill/data-recovery pipeline scaffold itself —
  see the `sql-backfill-pipeline-scaffold` skill for that.
