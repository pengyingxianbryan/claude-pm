---
name: pm:resume
description: Restore context from STATE.md and handoffs
argument-hint: "[optional: handoff path]"
allowed-tools: [Read, Glob, Bash]
---

<objective>
Restore PM context after a session break, including local Story/Task status and GitHub branch status. Suggest exactly ONE next action.

**When to use:** Starting a new session on an existing PM project.
</objective>

<context>
$ARGUMENTS (optional handoff path)

@.pm/STATE.md
</context>

<process>

<step name="verify_pm">
1. Verify .pm/ exists. If not: "No PM project found. Run /pm:init first."
2. Read STATE.md for full context
</step>

<step name="detect_handoffs">
1. If $ARGUMENTS provided, use that handoff path
2. Otherwise, find most recent HANDOFF file in .pm/
3. Load handoff content if detected
</step>

<step name="restore_context">
From STATE.md, restore:
- Current phase and plan
- Loop position (PLAN/APPLY/UNIFY)
- GitHub section: branch, last push
- TDD Results: which tasks completed, which pending
- Blockers/Concerns + Baseline gaps + Audits: open Critical findings surface before any other next action

From STORY.md and TASK-NN.md files:
- Per-phase Story status
- Per-task status and completion records
- PR URLs
</step>

<step name="verify_external_state">
Quick checks:
1. `git branch --show-current` — confirm we're on expected branch
2. `git status` — check for uncommitted changes
3. `gh pr list --state open` — check for any open PRs awaiting merge
</step>

<step name="display_and_route">
Present resume status with single routing:

```
════════════════════════════════════════
PM RESUMED
════════════════════════════════════════

Project: [name]
Last session: [timestamp]

Story: Phase [N] — [status]
Tasks: [N]/[M] complete
Branch: [current branch] ([clean/dirty])
TDD: [N]/[M] tasks complete

Loop:
  PLAN ──▶ APPLY ──▶ UNIFY
    ✓        ◉        ○

[If handoff detected:]
Handoff: [path]
Context: [key info from handoff]

[If open PRs exist:]
Open PRs:
  - [PR URL] — awaiting merge

────────────────────────────────────────
▶ NEXT: [single action based on loop position]
────────────────────────────────────────
```

After work proceeds: archive/delete consumed handoff.
</step>

</process>

<success_criteria>
- [ ] Context restored from STATE.md and/or handoff
- [ ] Story/Task status shown from local files
- [ ] GitHub branch status verified
- [ ] Open PRs detected
- [ ] TDD progress shown
- [ ] Loop position correctly identified
- [ ] Exactly ONE next action suggested
</success_criteria>
