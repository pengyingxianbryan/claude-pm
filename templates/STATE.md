# STATE.md Template

Template for `.pm/STATE.md` — the project's living memory.

**Purpose:** Single source of truth for current position, accumulated context, and session continuity.

---

## File Template

```markdown
# Project State

## Project Reference

See: .pm/PROJECT.md (updated [YYYY-MM-DD])

**Core value:** [One-liner from PROJECT.md - the ONE thing that matters]
**Current focus:** [Current milestone and phase name]

## Current Position

Milestone: [Name] ([version])
Phase: [X] of [Y] ([Phase Name])
Plan: [A] of [B] in current phase
Status: [Ready to plan | Planning | Approved | Applying | Unifying | Complete | Blocked]
Last activity: [YYYY-MM-DD HH:MM] — [What happened]

Progress:
- Milestone: [░░░░░░░░░░] 0%
- Phase: [░░░░░░░░░░] 0%

## Loop Position

Current loop state:
```
PLAN ──▶ APPLY ──▶ UNIFY
  ◉        ○        ○     [Planning]
  ✓        ◉        ○     [Applying]
  ✓        ✓        ◉     [Unifying]
  ✓        ✓        ✓     [Complete - ready for next PLAN]
```

## Performance Metrics

**Velocity:**
- Total plans completed: [N]
- Average duration: [X] min
- Total execution time: [X.X] hours

**By Phase:**

| Phase | Plans | Total Time | Avg/Plan |
|-------|-------|------------|----------|
| 01-[name] | 0/0 | - | - |

**Recent Trend:**
- Last 5 plans: [durations]
- Trend: [Improving | Stable | Degrading]

## Accumulated Context

### Decisions

| Decision | Phase | Impact |
|----------|-------|--------|
| [Decision summary] | [Phase X] | [Ongoing effect] |

### Deferred Issues

| Issue | Origin | Effort | Revisit |
|-------|--------|--------|---------|
| [Brief description] | [Phase X] | [S/M/L] | [When to reconsider] |

### Blockers/Concerns

| Blocker | Impact | Resolution Path |
|---------|--------|-----------------|
| [Description] | [What's blocked] | [How to resolve] |

## Boundaries (Active)

Protected elements for current phase:

- [Protected file/pattern from current PLAN.md]

## Session Continuity

Last session: [YYYY-MM-DD HH:MM]
Stopped at: [Description of last completed action]
Next action: [What to do when resuming]
Resume context: [Key information needed to continue]

## Plan Status
plans_approved:
<!-- Per-phase status: planned | revised | executing | complete -->
<!-- phase_01: planned -->
<!-- phase_02: planned -->

## GitHub
branch:
remote_verified:
last_push:

## TDD Results
<!-- Written by /pm:apply — one line per task -->
<!-- Format: task_N: RED ✓ | GREEN ✓ | REFACTOR ✓ | tests_added: X | passing: Y -->

## Baseline gaps
<!-- Written by /pm:init and /pm:audit ci. One line per missing baseline item, with why it was skipped. -->
<!-- e.g. branch_protection: none — free private repo, Accepted 2026-10-08 -->

## Audits
<!-- Written by /pm:audit — one line per run: AUDIT-YYYY-MM-DD-scope: PASS|FAIL crit/high/med/low -->

---
*STATE.md — Updated after every significant action*
*Size target: <100 lines (digest, not archive)*
```

---

## Section Specifications

### GitHub Section
**Purpose:** Track GitHub remote and branch state.
**Contains:** feature branch, remote verification status, last push timestamp.
**Update:** After /pm:apply starts (branch created), after each task (push), after PR created.

### TDD Results Section
**Purpose:** Track RED/GREEN/REFACTOR results per task.
**Contains:** One line per task with phase results and test counts.
**Update:** After each task completes all three TDD phases in /pm:apply.

### All Other Sections
Identical to PAUL STATE.md. See PAUL documentation for details on:
- Project Reference, Current Position, Loop Position
- Performance Metrics, Accumulated Context
- Boundaries, Session Continuity
