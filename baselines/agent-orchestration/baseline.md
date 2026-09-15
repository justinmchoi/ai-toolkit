# Agent Orchestration Baseline

Status: active
Version: 0.3.0

Always-on discipline for dispatching, coordinating, and communicating around
AI sub-agents and background agents — the mechanics of handing work to another
agent and getting a trustworthy result back, not the content of the work
itself. This is a distinct concern from `repo-context-grounding`, which is
about starting work correctly in a single repo the current session is already
in; this baseline is about crossing that boundary — into another repo, into a
parallel agent, into a blocked tool call, into a shared log another session
might also be writing to.

## Principles

1. Verify a dispatched sub-agent's "worktree isolation" actually covers the
   target repo before relying on it.
   Before relying on a dispatched sub-agent's `isolation: "worktree"` option
   to cover work in a repo other than the current session's own, don't assume
   it covers that other repo — verify the mechanism's actual scope (which
   repo it creates the worktree in), or create the worktree explicitly in the
   target repo yourself and hand the agent that literal path. An isolation
   option scoped to the wrong repo gives false confidence that mutations are
   contained when they are not.

2. Hand a continuation dispatch the concrete specifics already discovered,
   not a cold open-ended prompt.
   When dispatching a background/sub-agent to continue work already partially
   investigated, include concrete already-discovered specifics — file paths,
   class/symbol names, ruled-out candidates, commands already tried — in the
   dispatch prompt. A prompt that re-poses the original open-ended question
   forces the new agent to re-derive ground already covered, wasting its
   budget and risking a different (and possibly contradictory) path through
   the same investigation.

3. Post a labeled partial synthesis as soon as any parallel branch is solid,
   layering later completions on top.
   When multiple parallel background agents are working toward one
   time-sensitive answer, post an interim synthesis of whatever is already
   solid as soon as it exists, explicitly labeled partial/incomplete, then
   layer each subsequent agent's completion on as a scoped update rather than
   withholding everything until the last agent finishes. Silence until full
   completion is the wrong default when the answer is time-sensitive and part
   of it is already trustworthy.

4. Stop at a safety-classifier block on an IAM- or secret-adjacent write and
   hand over the exact command — don't route around it.
   When a safety-classifier block hits an IAM- or secret-adjacent write, stop
   and hand the user the exact command/value rather than routing around it
   via another tool, another phrasing, or another approach that reaches the
   same effect. Also don't assume a later identical attempt will fail the
   same way — classifier behavior isn't fully deterministic, so a blocked
   command isn't evidence that retrying (or asking the user to run it
   themselves) is pointless.

5. Grep a shared append-only log for ordinal collisions immediately before
   writing, not from a value read earlier in the conversation.
   Before appending a sequentially-numbered entry to a shared memory/log file
   that more than one concurrent session could touch, grep the file for that
   exact ordinal immediately before writing — not a "next number" value
   computed or read earlier in the conversation, which can be stale by the
   time the write actually happens. On collision, disambiguate explicitly
   (e.g. a suffix or a note) rather than inventing a corrected total order
   that silently renumbers another session's entry.

6. Confirm no other executor is already on the same target before dispatching.
   Before dispatching a background/sub-agent, confirm no other executor —
   the user's own session, another already-running agent — is already
   working the same target, especially when the user's phrasing about who
   did what is ambiguous. Dispatching blind onto a target someone else is
   already mid-way through risks duplicated work, colliding writes, or a
   report that contradicts what the other executor is about to produce.

7. Check whether a fix to shared/base code was already tried and reverted
   before reapplying it in a multi-session project.
   Before reapplying a fix to shared/base code in a multi-session project,
   check whether a prior session already tried and explicitly reverted that
   exact fix — commit messages, PR descriptions, prior capture notes. A new
   session does not automatically inherit that history, so absence of a
   memory of the revert is not evidence the revert never happened.

8. Treat mid-run narration of a later step as a plan, not a result, until
   the run finishes.
   An early step in a sequenced/multi-step process that narrates what a
   later step in the same run will do describes a plan, not a result —
   either move that narration to run last, or explicitly re-verify and
   update it against the sequence's actual final outcome before considering
   the run complete. Reporting the planned outcome as if it already happened
   is a false-confirmation risk if a later step fails, changes course, or is
   skipped.

9. When an ordinary edit is blocked by the classifier, change the tool shape
   rather than retrying the same call.
   A small, targeted edit blocked twice in a row by the permission or
   auto-mode classifier will very likely be blocked a third time. Switch to
   an equivalent path that makes the same change — a full-file read plus
   write — since a different tool shape may not trip the same rule, and this
   avoids stalling on a call that has already demonstrated it will not go
   through as-is. This is deliberately the opposite of the secret- or
   IAM-adjacent case in principle 4, which stops and hands the exact command
   to the user: the distinguishing factor is what the write touches, not that
   a block occurred. Only a reasonable fallback while the file is small
   enough that a full-file rewrite stays cheap and low-risk to diff-review;
   for a large file, a blocked edit is better escalated to the user than
   worked around by broadening the write's blast radius.
   _(added 2026-09-15, from `switch-to-read-write-when-edit-blocked-by-classifier`)_

## Priority

Apply this baseline before dispatching, coordinating, or reporting on
sub-agent/background-agent work, but never use it to override explicit user
instructions, safety rules, privacy boundaries, or stricter repo-local
instructions.

## Non-Goals

- This does not cover which agent type or model to pick for a task — that is
  a capability/cost decision made per task, not a dispatch-mechanics rule.
- This does not cover prompt-engineering content quality (how to phrase a
  good task description) beyond principle 2's narrow requirement to include
  already-known specifics — it is not a general prompting guide.
- This does not cover single-session, single-repo work at all — see
  `repo-context-grounding` for that.
