---
name: pm:progress
description: Smart status with local tracking context — suggests ONE next action
argument-hint: "[context]"
allowed-tools: [Read, Glob]
---

<objective>
Show current progress including Story/Task status, GitHub branch state, and TDD results across all phases. Route to exactly ONE next action.

**When to use:**
- Mid-session check on progress
- After `/pm:resume` for more context
- When unsure what to do next
</objective>

<context>
$ARGUMENTS

@.pm/STATE.md
@.pm/ROADMAP.md
</context>

<process>

<step name="load_state">
Read `.pm/STATE.md` and `.pm/ROADMAP.md`:
- Current phase and total phases
- Current plan (if any)
- Loop position (PLAN/APPLY/UNIFY markers)
- Plans approved timestamp
- Per-phase plan status (planned / revised / executing / complete)

Read STORY.md files from each phase directory:
- Status per phase (To Do / In Progress / In Review / Done)

Read TASK-NN.md files from active phase:
- Per-task status and completion records
- PR URLs

GitHub status:
- `git branch --show-current`
- `git status`

TDD Results from STATE.md:
- Per-task RED/GREEN/REFACTOR status

Ship-readiness from STATE.md:
- `## Baseline gaps` — anything still missing from init
- `## Audits` — last run per scope, PASS/FAIL, open Critical/High
- `.pm/ISSUES.md` — count of open issues with Origin AUDIT-*
If any Critical is open, it is the ONE next action regardless of loop position.
</step>

<step name="calculate_progress">
**Milestone Progress:**
- Phases complete: X of Y
- Current phase progress: Z%

**Current Loop:**
- Position: PLAN/APPLY/UNIFY
- Status: [what's happening]

**Story Status (per phase):**
- Phase 1: [name] — [To Do / In Progress / In Review / Done]
- Phase 2: [name] — [To Do / In Progress / In Review / Done]

**Task Status (current phase):**
- Task 1: [name] — [To Do / In Progress / Done] [PR URL if exists]
- Task 2: [name] — [To Do / In Progress / Done]

**GitHub Status:**
- Current branch: [branch name]
- Working tree: [clean/dirty]

**TDD Progress:**
- Tasks complete: X of Y
- Total tests: N passing
</step>

<step name="determine_routing">
Based on state, determine **ONE** next action:

| Situation | Single Suggestion |
|-----------|-------------------|
| No project initialized | `/pm:init` |
| Init done, no plans | `/pm:plan` |
| Plans approved, not executing | `/pm:apply` |
| Phase applied, not unified | `/pm:unify` |
| Unified, more phases remain | `/pm:apply` (next phase) or `/pm:plan --revise N` |
| All phases unified | `/pm:verify` |
| TDD gate failed (task blocked) | "Fix failing test and continue /pm:apply" |
| GitHub remote unreachable | "Fix GitHub remote before /pm:apply" |
| PR waiting for merge | "Merge PR [URL] to continue" |

**IMPORTANT:** Suggest exactly ONE action. Not multiple options.
</step>

<step name="display_progress">
```
════════════════════════════════════════
PM PROGRESS
════════════════════════════════════════

Milestone: [name] - [X]% complete
├── Phase 1: [name] ████████████ Done
├── Phase 2: [name] ████████░░░░ 70%
└── Phase 3: [name] ░░░░░░░░░░░░ Pending

Plans: approved [date]
  Phase 1: complete
  Phase 2: executing (revised)
  Phase 3: planned

Current Loop: Phase 2, Plan 02-01
┌─────────────────────────────────────┐
│  PLAN ──▶ APPLY ──▶ UNIFY          │
│    ✓        ✓        ○             │
└─────────────────────────────────────┘

Tasks (Phase 2):
  Task 1: [name] — Done (PR: #12)
  Task 2: [name] — In Progress
  Task 3: [name] — To Do

GitHub: main — clean
TDD: 1/3 tasks complete | 8 tests passing

────────────────────────────────────────
▶ NEXT: Continue /pm:apply for Task 2
────────────────────────────────────────
```
</step>

</process>

<success_criteria>
- [ ] Overall progress displayed visually
- [ ] Per-phase Story status shown
- [ ] Per-task status shown for active phase with PR URLs
- [ ] GitHub branch status shown
- [ ] TDD progress shown (tasks complete, tests passing)
- [ ] Current loop position shown
- [ ] Exactly ONE next action suggested
</success_criteria>
