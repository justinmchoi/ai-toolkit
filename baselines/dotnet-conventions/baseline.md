# .NET Conventions Baseline

Status: active
Version: 0.7.0

Always-on .NET/C# conventions for dependency-injection registration and
codegen/scaffold output. Distilled from 2026-07 work on a .NET payments service where DI
registration semantics silently dropped a second implementation, and a
scaffolded EF Core migration surfaced changes the agent hadn't caused.

## Principles

1. Use `Add*`, not `TryAdd*`, for every implementation in a multi-implementation
   registration.
   `.NET`'s `TryAdd*` DI methods dedup by service type alone, not
   implementation type. Registering a second implementation of an interface
   meant to be resolved as `IEnumerable<T>` (a strategy-pattern registration)
   with `TryAdd*` silently no-ops — the second implementation is never
   resolved, with no error. Use `Add*` when the interface is intentionally
   multi-implementation.

2. Don't bake a per-call value into a pooled/shared DI instance's registration.
   A typed `HttpClient` (`AddHttpClient<T>()`) assumes a static base URL known
   at DI-registration time. When the real host is resolved per-call (e.g. a
   value read from a database row), do not set `BaseAddress` at registration —
   build the full URI per call instead. This generalizes beyond `HttpClient`:
   any DI-pooled object with a "set-once at registration" value is wrong when
   that value is actually per-call.
   Reinforcement: a `DelegatingHandler` registered via
   `AddHttpMessageHandler<T>()` is pooled, not created per-request. Per-request
   state must flow through `HttpRequestMessage.Options` (or headers), never a
   constructor-injected scoped service treated as if it were set once per call.

3. Treat an unexpected scaffold diff as evidence of pre-existing drift, not
   something you caused.
   When a scaffolded EF Core migration (or any codegen tool) produces changes
   beyond what the intended edit should touch, that is a signal of pre-existing
   model/config drift, not a new problem you introduced. Verify by running a
   throwaway empty re-scaffold — if it reproduces the same unrelated diff, fix
   the root model/config, not the generated output. Never hand-edit the
   generated file to remove the unexpected parts.

4. Implement a cross-cutting concern (audit, retry, validation) as a handler
   registered into an existing pipeline seam, not an opt-in helper method call
   sites must remember to invoke.

5. Place a cross-cutting `DelegatingHandler` relative to a retry handler
   deliberately — inside retry observes physical attempts, outside retry
   observes logical calls.

6. When chaining into a different library's fluent builder mid-pipeline,
   don't cast its return type back — call it as a standalone statement and
   return your own original reference.

7. A fire-and-forget async operation must own its own DI scope, its own
   `CancellationToken.None`, and its own exception handling — never inherit
   any of the three from its trigger.

8. A nullable foreign-key column meaning "no associated record" must receive
   a real `null` end-to-end, never a sentinel or randomly-generated value.

9. In a migration's raw `InsertData`/`DeleteData`/`UpdateData` column
   literals, use the schema's original column casing, never the C# entity
   property's casing.

10. Before a Singleton reaches for `IServiceScopeFactory.CreateScope()` to
    get a fresh handle to a shorter-lived resource, check for a
    purpose-built factory for that resource type first (e.g.
    `IHttpClientFactory`), and use manual scope creation only when none
    exists.

11. Register a `DelegatingHandler` shared across more than one typed
    `HttpClient` via `AddHttpMessageHandler<T>()` as Transient, never
    Singleton.

12. When two options classes bind the same config section, treat one reading
    a property from the other instead of owning its own as a design smell
    to flag during implementation.

13. Before adding a generic type parameter to accept "one of several caller
    types" while preserving encapsulation, check whether the constraint
    interface it requires already does the whole job.
    If the interface used as the generic constraint already exposes every
    member the method needs, the generic buys nothing — skip it. Only
    introduce the generic when the concrete type itself, not just what its
    constraint interface exposes, must flow back out past the method's
    boundary.

14. Before adding a method to a shared strategy-pattern interface, check
    whether sibling implementers treat existing methods as genuine
    capabilities or as permanent unfillable stubs.
    A method intrinsically tied to one implementer's protocol belongs on a
    narrow capability interface instead of the shared one — not on the
    interface every strategy implements. Justify the split with demonstrated
    risk from keeping it shared, not a hypothetical future need.

15. Before naming a new shared abstraction merged from separate call sites,
    check the domain model's existing vocabulary for a narrower established
    meaning tied to only one of the call sites.
    Look at existing status fields, enums, and doc comments before picking a
    name. Prefer a mechanical/structural name over a state-implying one when
    the call sites being merged don't uniformly share that state — reusing a
    status-flavored name that only fits one call site will mislead readers at
    the other.

16. An idempotency/replay short-circuit that finds a record by key must
    separately validate the record's current state (status/expiry) before
    reusing it in a response.
    Existence at that key is not the same as still being valid to reuse. A
    record that once satisfied the request may since have expired, been
    cancelled, or moved to a terminal state; returning it unchecked reuses
    stale data as if it were still current.

17. When auditing every call-site of a conditional credential-routing system
    (e.g. multiple HttpClient configurations), enumerate every method x its
    actual routing rule from the code itself into a full table.
    Read the routing rule from the code, not from memory. Separate the rows
    into "by-design", "correctly exempted", and
    "should-be-exempted-but-isn't" — don't spot-check a handful of call sites
    and assume the rest follow the pattern.

18. When writing/updating a parent and its child in one operation, check the
    ORM model for an existing navigation property before doing a manual
    second save.
    Attach the child to the parent's navigation property before the first
    save so the change tracker resolves the foreign key in one call.

19. Before adding an operation to a versioned/public SDK/API interface,
    confirm a real consumer exists.
    Symmetry or completeness alone is not justification, and new work should
    extend the live interface, not a deprecated parallel one.

20. Don't serialize a value into a shared/generic field only to immediately
    deserialize it back within the next step of the same operation.
    Pass a typed object/property directly; reserve serialization for genuine
    cross-boundary handoffs (cross-process, cross-time, external API).

21. When adding a field to a widely-implemented shared interface, treat a
    green build as the minimum bar, not sufficient proof.
    Separately verify (1) every concrete implementation was actually updated,
    (2) a reflection-based test-data generator targeting the bare interface
    won't fail at runtime for unregistered concrete types, and (3) if the new
    field carries sensitive data, it needs its own masking/redaction tag — it
    does not inherit protection from wherever it was previously nested.

22. A shared "sync whole object graph" update method must not treat a
    missing/null collection on the input object as "clear this in the DB"
    when narrow-purpose callers pass partial objects.
    Narrow callers should re-fetch the full object and mutate only their own
    field, not hand a partial object to a full-sync method.

23. Before attaching a shared request/response logging middleware to an
    HttpClient carrying secrets in the body (e.g. an OAuth client-credentials
    form POST), verify its default masking scope explicitly covers body
    content, not just header names.
    Many masking libraries default to header-only redaction.

24. A migration rollback can only undo migrations whose Down()/reverse code
    is compiled into the branch you run it from.
    If a shared environment's migration history shows entries beyond your
    current branch, locate the branch that actually owns those extra
    migrations (search all branches) and roll back from there.

25. On Windows, check for a locked build output before treating a copy
    failure as a code bug.
    When `dotnet build`/`dotnet test` fails with file-copy/file-in-use errors
    (MSB3026, MSB3027) on a project's own output DLL, check first for another
    running process holding that binary (an IDE-launched debug session, a
    leftover `dotnet run`) before investigating it as a compile or code
    problem. Windows + locally-run services only; doesn't apply to CI.

26. Carry an unconfirmed candidate value alongside an entity, not as a
    mutable property on it, across a persist-then-refetch boundary.
    When a value must travel from a producer, through an EF Core insert/update
    (which returns a fresh re-fetched instance, not the same object
    reference), to a consumer that needs it afterward: carry it as a separate
    parameter/return value alongside the entity (a wrapper record), not as a
    mutable property on the entity. A mutable property requires an explicit
    restoration step after every persist call because the re-fetched instance
    never had it set — miss that step once and the value silently vanishes.
    Only promote a value to a real entity property once it's validated and
    settled.

27. Before adding a fetch inside a shared helper, check whether every caller
    already has the value.
    When adding a data-resolution call (DB fetch, provider lookup, external
    call) inside a shared/helper method, first check whether the value is
    already available in the calling method's scope from an earlier step —
    thread it through as a parameter rather than re-deriving it. Doesn't apply
    when the value may have genuinely changed since the caller resolved it, or
    when some callers legitimately don't have it.

28. After adding a member to a widely-mocked interface, explicitly configure
    every test double for it — a loose mock defaults a value-type member
    silently.
    Value-type properties (`bool`, `int`, enums) on loose mocks (Moq's default
    `MockBehavior.Loose`, FakeItEasy's default fakes) return their CLR default
    silently with no exception, unlike `Task`-returning members (which throw
    on `await` when unconfigured). A green build does not mean the doubles are
    correctly wired. Explicitly search every test double implementing the
    interface and add an explicit `.Setup(...)`/`A.CallTo(...)` for the new
    member, even where the default happens to be the desired value, so the
    suite passes by design, not by coincidence.

29. When a transitive dependency forces a NuGet version bump, match the
    repo's existing pin, don't pick the bare minimum.
    When a transitive dependency forces a version bump on a directly
    referenced package and trips a `NU1605` downgrade error, grep the rest of
    the solution for that package's existing pinned version(s) and match the
    prevailing pin — picking the bare minimum that satisfies the error
    introduces yet another inconsistent pin instead of fixing the actual
    drift. Only applies when the solution already has an established,
    consistent pin to match.

30. Prefer a required property on a shared base interface over an empty
    marker interface for per-type policy.
    When a policy/capability needs to vary per concrete type and must be
    declared explicitly per implementer, and a shared base interface already
    exists for that family of types, add a required (non-default)
    property/method to it rather than introducing an empty marker interface
    checked via `is`/`as` — per .NET's own Framework Design Guidelines, marker
    interfaces carry no compiler-enforced contract and scatter type-checking
    across call sites. Reach for a marker interface only when there's a
    genuine reason to test via `is`/`as` at a call site with no other access
    to the base interface, or when adding to the shared base would touch
    implementers with no business knowing about the concern.

31. Match the codebase's existing selective XML-doc convention; don't
    default to "everywhere" or "nowhere."
    Use `<summary>`/`<remarks>` XML doc only on genuine public API surface
    (interfaces, public methods/properties, public records) intended for
    IntelliSense/generated-doc consumption, matching wherever the codebase
    already applies it selectively (document where the contract isn't
    obvious from the signature, skip where it is) — don't convert every
    method or none. Keep plain `//` on private implementation methods,
    especially ones carrying inline "why this line does X" reasoning; XML
    doc's member-level shape doesn't fit inline reasoning and converting it
    is pure churn. A raw `&` in XML doc content only stays safe while the
    project has no `GenerateDocumentationFile`/strict doc-validation enabled
    (surfaces as CS1570 if that ever changes).

32. Build/run a throwaway .NET executable under a short path, not a deep
    harness-generated scratchpad path.
    `dotnet run` can fail with a bare `CreateProcess` error from exceeding
    Windows's `MAX_PATH` (~260 chars) when the working directory embeds a
    long repo name + session ID + subfolders — even though `dotnet
    build`/restore succeeded. Scaffold and run throwaway compiled executables
    under a short path (e.g. `C:\tmp\<short-name>`) instead, and delete it
    when done. Keep using the normal scratchpad for non-executable temp files
    (scripts, JSON, notes), where `MAX_PATH` doesn't bite.

33. Suspect `DefaultAzureCredential`'s probing chain for unexplained
    multi-second cold-start latency.
    When diagnosing unexplained multi-second-to-tens-of-seconds latency in an
    app using `DefaultAzureCredential` (Key Vault access, service-to-service
    auth), explicitly suspect and measure its credential-source probing chain
    in isolation before attributing the delay to database, HTTP, or business
    logic — it runs its full multi-source probe on a non-Azure-hosted local
    dev machine before falling through to a working credential. Azure/.NET
    specific; mainly on non-Azure-hosted dev/CI machines.

34. After an EF Core model/entity-config change, grep the scaffolded
    snapshot for the expected DDL — don't trust "build succeeded."
    After any EF Core model/entity-config change (including post-merge),
    scaffold the migration and grep the updated `ModelSnapshot.cs` for the
    expected new DDL to confirm it was actually captured — a scaffold can
    silently not pick up a new constraint. Then run a throwaway empty
    migration add→remove cycle to prove zero remaining drift, apply the full
    chain to a disposable local DB, and use raw `sqlcmd` to empirically
    verify boundary behavior before dropping the scratch DB and any leftover
    migration artifacts. (See principle 3 for the sibling case — an
    unexpected scaffold diff signaling pre-existing drift; this is the
    inverse: confirming an *intended* change was actually captured.)

35. To resolve a NuGet package's exact public API without a decompiler,
    read its source via `gh api`.
    Locate the installed DLL under `~/.nuget/packages/{pkg}/{version}/lib/...`,
    read its `.nuspec` for the `<repository url=.../>` or `<projectUrl>`, then
    use `gh api repos/{owner}/{repo}/contents/{path}` to fetch and grep the
    matching source file(s) for the real signatures — faster and more
    reliable than extracting strings from the binary. Only applies to
    open-source packages with a discoverable public GitHub source repo; fall
    back to a real decompiler (ILSpy/ildasm) for closed-source or
    private-feed packages.

36. Before trusting a "will/won't retry" claim, check the HTTP-client-level
    resilience policy (e.g. Polly) registration and its per-endpoint scoping
    explicitly.
    A message-bus retry loop and an HTTP-client resilience policy are two
    independent layers, and one can silently override or exclude the other.
    Neither an agent's sweep nor a stated belief about retry behavior is a
    substitute for reading the actual policy registration code.

37. XML doc comments apply to public test classes and methods too, for a
    different reader.
    The selective-XML-doc rule scopes itself to "genuine public API surface
    intended for IntelliSense or generated-doc consumption", and on a literal
    reading a test class falls outside it — it is `public` only so the runner
    can discover it, and nothing consumes its IntelliSense. That reading is why
    the rule missed twice on new test files. A test class still earns a
    class-level `<summary>` stating **what it proves and why it is separate
    from the baseline suite**, and `<summary>`/`<remarks>` on any method whose
    reasoning is non-trivial: the reader is a future maintainer skimming the
    suite to learn which safety properties are covered, which is the same job
    XML doc does for an API consumer. Trivial arrange-act-assert methods whose
    name already says everything still take a plain `//` comment or none.
    _(added 2026-09-11, from `reopened-xml-doc-for-public-api-plain-comments-for-private-impl`)_

38. Verify a NuGet version copied from template or skill reference code before
    adding it — the pin is documentation, not a build artifact.
    Version strings inside a template's example `.csproj` are never compiled or
    CI-checked, so they go stale silently. Query
    `https://api.nuget.org/v3-flatcontainer/{package-id-lowercase}/index.json`,
    or run the `dotnet add package` and actually read the diagnostics. A
    typo'd or non-existent version fails fast and loudly (`NU1103` — a
    template pin of `5.4.483` resolved to nothing when the real latest stable
    was `5.4.0`), but a **stale-and-vulnerable** one succeeds silently and
    surfaces only as an `NU1902`/`NU1903` build warning nobody reads. This is
    about reference documentation, not about second-guessing every pin in an
    actively-maintained repo's own `.csproj`, which reflects real intent.
    _(added 2026-09-11, from `verify-nuget-version-from-skill-template-before-adding`)_

## Priority

Apply this baseline before ordinary .NET DI and codegen habits, but never use
it to override explicit user instructions, safety rules, privacy boundaries,
or stricter repo-local instructions.

## Non-Goals

- This does not cover general DI lifetime choice (singleton/scoped/transient),
  only the registration-dedup and per-call-value traps above.
- This does not cover EF Core migration authoring or review beyond the
  scaffold-drift signal.
