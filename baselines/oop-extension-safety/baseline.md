# OOP Extension Safety Baseline

Status: active
Version: 0.4.0

Always-on guards for inheritance extension points in object-oriented codebases.
Applies to any language that supports abstract/virtual methods and dependency
injection.

Distilled from two production bugs where base-class bypass, aggregate hook
parameters, and wrong-type mocks allowed incorrect carrier-specific behaviour
to compile, pass tests, and reach production.

## Principles

1. Complete the template method.
   When a base class introduces a `protected abstract` or `virtual` hook to let
   subclasses vary a decision, every code path in the base class that involves
   that decision must route through the hook. A direct call to a concrete field
   (e.g. `_baseBuilder.Build(...)`) inside the base class bypasses virtual
   dispatch silently — adding a new subclass will not override it, and the base
   class behaviour runs for all subclasses regardless.

2. Prefer primitive parameters in abstract hooks.
   Abstract and virtual hook methods should accept the smallest set of concrete
   primitives needed, not a whole aggregate object. Passing an aggregate object
   (e.g. a query type, a command type, or a context bag) ties the hook to one
   specific caller shape. When a second code path holds the same data in a
   different type, the hook cannot be reused — a separate, bypass-prone code
   path gets written instead.

3. Mock the most-specific injected type.
   When writing test doubles for injected dependencies, mock the exact concrete
   class or interface that is registered in the DI container, not a base class.
   Because a subclass is assignable to its base, mocking the base class satisfies
   the injection site even when the production code injects the wrong subtype.
   The test passes, but it does not catch the type mismatch.

4. Declare concrete delegate types at the class level.
   When a class varies only in which concrete types it delegates to — not in any
   algorithm — express that variation through generic type parameters or equivalent
   declaration-level constructs, not solely through constructor parameters. A type
   parameter at the class declaration is visible in every diff and code review
   without needing DI registration context, and cannot silently accept a wrong-but-
   assignable subtype. A constructor parameter alone accepts any compatible type at
   the injection site and can be satisfied incorrectly without a compile error or
   test failure. The pattern applies to factory classes, adapters, and dispatchers
   where two or more implementations share the same routing logic but differ only
   in which concrete collaborators they use.

5. Prefer a DI-wired subclass hook over an inline caller-type check.
   When a shared class needs different behavior for a specific caller, prefer
   a `protected virtual` hook overridden by a DI-wired subclass over checking
   the caller's concrete type inline. The caller-specific coupling becomes
   visible at the constructor/DI level instead of buried in logic that reads
   as caller-agnostic — a reviewer scanning the shared class sees a normal
   extension point, not a hidden branch that only fires for one caller.

## Priority

This baseline takes precedence over ordinary implementation and test-writing habits, but
never use it to override explicit user instructions, safety rules, privacy
boundaries, or stricter repo-local instructions.

## Non-Goals

- This is not a general OOP style guide.
- This does not prohibit concrete fields in base classes — only direct calls to
  those fields that should be routed through a virtual hook.
- This does not require every test to mock only interfaces.

## Origin

Distilled from carrier-integration work. The three bugs were: a service
factory injecting a base-class builder
instead of the carrier-specific subtype; a confirmation flow calling the base
builder directly instead of the polymorphic hook; and a hook signature that
accepted a full aggregate object, preventing reuse from a second caller.
