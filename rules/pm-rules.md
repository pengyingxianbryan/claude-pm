---
paths:
  - "**/*.md"
---

# PM Rules

Domain rules for PM — enforced at all times during PM operations. Rules 1–7 govern the loop; Rules 8–10 govern what is allowed to ship.

## Rule 1 — Approval Gate

PM must never begin APPLY, and never write implementation code without the user explicitly saying APPROVE after reviewing the complete plan. The word APPROVE (or clear equivalent) must appear in the conversation before any of these actions occur.

In Plan All mode, APPROVE applies to the full set of phase plans. After APPROVE is received:
1. Create local STORY.md and TASK-NN.md files for all phases
2. Update STATE.md with approval timestamp
3. Confirm the local tracking structure to the user

The user must never be asked to create tracking files manually. PM creates them automatically after APPROVE.

## Rule 2 — TDD Sequence

For every task in APPLY, tests must be written and confirmed FAILING before any implementation file is touched. Implementation code written before a failing test exists must be deleted. This rule has no exceptions.

The sequence is always: RED (failing test) → GREEN (minimal implementation) → REFACTOR (cleanup only).

If a test passes before implementation is written, STOP. Report to user. Do not rationalise past this gate.

If any existing test breaks during GREEN phase, STOP. Report exactly which tests broke. Do not proceed to the next task.

## Rule 3 ��� Per-Task Status Updates

Each TASK-NN.md must update its own status independently as the task progresses:
- `To Do` → `In Progress` when the task starts
- `In Progress` → `Done` when TDD passes and PR is merged

Status updates happen per-task, NOT after the whole Story/phase completes. The STORY.md task table must also update per-task to reflect current progress.

The Completion Record in TASK-NN.md (commit SHA, tests added, PR URL, TDD results) must be filled immediately after the PR is merged — not deferred to UNIFY.

## Rule 4 — Per-Task PRs

Every task gets its own branch and Pull Request:
1. Branch from main: `pm/{phase-name}-task-{N}`
2. After TDD passes: commit, push, create PR via `gh pr create`
3. Present PR URL to user and ask them to review and merge
4. **HARD STOP** — do not proceed to the next task until the user confirms the PR is merged
5. After merge: checkout main, pull latest, start next task

A task is not considered complete until its PR has been created AND merged.

## Rule 5 — Loop Integrity

The overall flow is: INIT → PLAN ALL → APPROVE → [per-phase: APPLY → UNIFY → optional revision]. No phase may skip UNIFY.

UNIFY is mandatory for every phase. No phase is complete without a SUMMARY.md. A session that ends without UNIFY is an orphan — STATE.md must record this and `/pm:resume` must surface it as the first action.

Between phases, the plan for the next phase may be revised via `/pm:plan --revise N` to incorporate learnings.

## Rule 6 — Boundary Protection

The Boundaries section of PLAN.md listing Do Not Change items is enforced absolutely. No file listed in boundaries may be modified during APPLY under any circumstances. Before writing to any file, check it against the boundaries list. If it appears, STOP and report — do not modify.

## Rule 7 — GitHub Gate

`/pm:apply` must verify the GitHub remote is reachable before writing any code. The verification sequence:
1. `git remote -v` — confirm origin is set
2. `git ls-remote origin HEAD` — confirm remote is reachable
3. `git status` — confirm clean working tree

If any check fails for any reason, APPLY must stop immediately and report the failure to the user. No code is written until the remote is confirmed reachable.

Every task completion must result in a `git push` and `gh pr create`. A task is not considered complete until the PR is created and the user has confirmed the merge.

## Rule 8 — Security Gate

No task reaches `git commit` with an open finding from `skills/security-gate/SKILL.md`. Concretely, for every task:
1. No secret-shaped string in the diff. The `secrets-gate.sh` PreToolUse hook enforces this mechanically on `git commit` and `git push`; a blocked commit is fixed, never bypassed with `--no-verify` or by editing the hook.
2. Every new env read is documented in `.env.example` in the same change.
3. Every input crossing a trust boundary is parsed into a typed shape before use.
4. Every handler that touches an object checks the caller may touch *that* object.
5. No string-built SQL / shell / HTML. No `git add -A`.
6. The stack's dependency audit at `high` is clean, or the advisory is floored with a named reason.

A finding whose fix lies outside the task's Boundaries is reported to the user, who widens scope or logs it to `.pm/ISSUES.md` as `High`. It is never silently deferred.

## Rule 9 — CI Green Before Merge Request

After `gh pr create`, PM runs `gh pr checks --watch` and does not ask the user to merge until every check passes. A red check is fixed on the same branch. A repo with no checks is told so once and pointed at `/pm:audit ci --fix`; the absence is recorded in STATE.md `## Baseline gaps`.

## Rule 10 — Observability and SEO Gates Where Applicable

Backend / fullstack / devops tasks pass `skills/observability-gate/SKILL.md` (errors reported, no swallowed catches, structured logs, health). Frontend tasks touching a public page pass `skills/seo-gate/SKILL.md` (metadata, crawlability, structured data, CWV). The PR body states the result of each applicable gate or `n/a` with the reason.
