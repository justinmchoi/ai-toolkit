---
name: setup-agent-team
description: Create a bounded manual execution packet for large AI-agent team workflows, or refuse/downgrade when the task should stay single-agent. Use when work is multi-domain, parallelizable, and context-heavy enough to need role selection, context packets, ownership boundaries, handoffs, budgets, verification, package-execution policy, and external-system credential policy before launching workers.
maintainer: justin.choi
status: stable
---

# Setup Agent Team

## Overview

Use this skill to decide whether agent-team delegation is warranted and, when
it is, produce a tool-neutral manual execution packet. Do not launch subagents,
run runtime-specific workers, or edit the target repo as part of setup.

## Trigger Gate

Use an agent team only when all are true:

- The work spans multiple domains, surfaces, or viewpoints.
- Meaningful parts can proceed in parallel.
- A single agent's context would become too large, tangled, or risk-prone.

Refuse or downgrade for:

- Small bugs
- Single-file edits
- Clear one-slice features
- Narrow docs/spec/glossary edits
- Tasks with no meaningful parallel ownership
- Requests that need broad write access before scope is known
- Private-vault, credential, production, or package-fetching work without
  explicit approval

If refusing, output a short downgrade decision and recommend the appropriate
single-agent workflow.

## Workflow

1. Inspect the user goal and available repo/project context.
2. Record the project baseline: path, repo guide, worktree state, known user
   changes, existing verification, and whether this continues an existing
   project or starts a new one.
3. Apply the trigger gate. Refuse if the task does not meet it.
4. Select only roles that own distinct questions, artifacts, or verification
   responsibilities.
5. Define context packets for each selected role.
6. Define ownership boundaries, read/write scopes, and disallowed paths.
7. Identify external systems and credential policy.
8. Identify package-manager and dependency-execution policy.
9. Define parallelizable tasks, parallelization safety, blocking dependencies,
   handoff protocol, integration owner, verification plan, budgets, and stop
   conditions.
10. Output the execution packet and wait for user approval before any worker
    launch or implementation.

## Role Catalog

Coordinator: Maintains goal, decomposition, dependencies, integration order,
context allocation, conflict resolution, and final synthesis.

Product Analyst: Clarifies user behavior, scope, acceptance criteria, and
product trade-offs.

Architecture Reviewer: Checks boundaries, data flow, risks, existing patterns,
and long-term design pressure.

Frontend Engineer: Owns UI, UX, component boundaries, frontend tests, and
browser verification.

Backend Engineer: Owns APIs, domain logic, data contracts, persistence, and
server-side tests.

Test Engineer: Owns test strategy, coverage gaps, regression checks, and
verification risk.

Documentation Maintainer: Owns README, context, ADRs, specs, issue notes, and
handoff documentation.

Ad hoc workers may be added only when they receive a bounded task, context
packet, output contract, and stop condition.

## Required Packet Fields

Produce these fields:

- Goal
- Trigger reason
- Project baseline and worktree state
- Selected roles
- Roles refused and why
- Context packet per role
- Ownership boundaries
- Parallelizable tasks
- Parallelization safety
- Blocking dependencies
- External systems and credential policy
- Package execution policy
- Handoff protocol
- Integration owner
- Verification plan
- Team budget
- Per-worker budget
- Stop conditions

## External Systems And Credentials

For each external system, state:

- Purpose
- Whether it is needed for implementation, verification, or both
- No-secret verification path
- Credentialed verification path
- Whether a disposable test environment is required
- Who provides credentials or access
- Required scopes or roles
- Whether production data or production credentials are forbidden
- Stop condition if credentials are unavailable

Prefer no-secret verification first. Use disposable test environments for
risky or stateful integration checks. Do not infer, locate, print, or exfiltrate
credentials.

## Package Execution Policy

Treat package managers as an execution boundary.

Distinguish:

- Local scripts, such as `npm run check` or `npm start`
- Dependency installs, such as `npm install` or `npm ci`
- Remote package execution, such as `npx`, `npm exec`, `pnpm dlx`, or
  equivalents

Default rules:

- Prefer existing local scripts.
- Do not use `npx` as a security shortcut.
- Do not add, update, install, or remotely execute packages without explicit
  approval.
- Pin package names and versions before any approved install or remote
  execution.
- Use an isolated runtime or `--ignore-scripts` when install scripts are not
  required.

## Parallelization Safety

Before recommending parallel workers, state:

- Independent file or artifact sets
- Shared contracts, schemas, interfaces, routes, or docs
- Expected integration order
- Whether an integration checkpoint is required before more edits
- Conflict risk: low, medium, or high

If independent ownership cannot be stated clearly, downgrade to sequential work
or a single-agent workflow.

## Output Templates

### Refusal

```markdown
# Agent Team Decision

- decision: refuse / downgrade
- reason:
- recommended single-agent workflow:
- verification:
```

### Execution Packet

```markdown
# Agent Team Execution Packet

## Goal
## Project Baseline
## Trigger Reason
## Selected Roles
## Roles Not Selected
## Context Packet Per Role
## Ownership Boundaries
## Parallelizable Tasks
## Parallelization Safety
## Blocking Dependencies
## External Systems And Credential Policy
## Package Execution Policy
## Handoff Protocol
## Integration Owner
## Verification Plan
## Team Budget
## Per-Worker Budget
## Stop Conditions
```

## Handoff Format

Require every future role or worker to report:

```markdown
## Result
## Evidence
- Files inspected:
- Commands run:
- Findings:
- Changed files:
## Decisions Needed
## Risks
## Verification
- Passed:
- Failed:
- Not run:
## Knowledge And Documentation Updates
- Durable knowledge update required:
- Documentation update required:
## Next Handoff
- Recommended next owner:
- Context they need:
- Suggested task:
```

## Stop Conditions

Stop setup when:

- The task should stay single-agent.
- Required context is missing.
- Credentials, private data, package-fetching, destructive actions, or external
  network access are needed before approval.
- Ownership boundaries cannot be made explicit.
- Worker budgets would be speculative.
- The user has not approved moving from packet setup to execution.
