---
name: pm:apply
description: Execute plan with GitHub gate + RED/GREEN/REFACTOR TDD enforcement per task
argument-hint: "[plan-path]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

<objective>
Execute an approved PLAN.md file with strict TDD enforcement and GitHub integration.

**When to use:** After PLAN phase complete and plan is approved (APPROVE received).

Every task runs through RED → GREEN → REFACTOR with hard gates. Every task gets its own branch and PR. Every task updates its local TASK-NN.md status independently.
</objective>

<context>
Plan path: $ARGUMENTS

@.pm/STATE.md
</context>

<process>

<!-- ════════════════════════════════════════════════ -->
<!-- GITHUB GATE — HARD                               -->
<!-- ════════════════════════════════════════════════ -->

<step name="github_gate" priority="first">
**Before writing a single line of code, verify GitHub remote:**

1. Run `git remote -v` — confirm origin is set to the configured repo URL
2. Run `git ls-remote origin HEAD` — confirm remote is reachable
3. Run `git status` — confirm working tree is clean or on correct branch

**If ANY check fails: STOP immediately.**
Print exactly what failed. Do not write a single line of code.

```
GitHub gate failed: [specific error]

[Diagnostic info]

Fix the issue and run /pm:apply again.
```
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- VALIDATE PLAN & LOCAL FILES                      -->
<!-- ════════════════════════════════════════════════ -->

<step name="validate_plan">
1. Confirm plan file exists at $ARGUMENTS path (or find current plan from STATE.md)
2. Error if not found: "Plan not found: {path}"
3. Derive SUMMARY path (replace PLAN.md with SUMMARY.md)
4. If SUMMARY exists: "Plan already executed. SUMMARY: {path}"
5. Read all tasks from the Tasks section
6. Read Boundaries — these files are OFF LIMITS during execution
7. Verify STORY.md exists in the phase directory
8. Verify tasks/ directory exists with TASK-NN.md files for each task
9. If any local files missing: create them from PLAN.md content (fallback)
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- UPDATE STORY STATUS                              -->
<!-- ════════════════════════════════════════════════ -->

<step name="story_start">
Update the phase's STORY.md:
- Set `Status` to `In Progress`

Update STATE.md:
- Loop position: APPLY
- Status: In Progress
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- TDD LOOP — PER TASK                              -->
<!-- ════════════════════════════════════════════════ -->

<step name="tdd_loop">
**For each task in the plan (skip tasks where TASK-NN.md shows Status: Done):**

```
─── Task [N]: [task name] ──────────────────────────────

1. UPDATE TASK STATUS
   Update tasks/TASK-{NN}.md: set Status to "In Progress"

2. CREATE TASK BRANCH
   git checkout main
   git pull origin main
   git checkout -b pm/{phase-name}-task-{N}

3. RED phase
   a. Identify test file for this task from Files field
   b. Write the failing test. Touch ONLY test files.
   c. Run: [test command from Verification field]
   d. Confirm output shows FAIL for the new test

   GATE: If new test passes before implementation → STOP.
         This means either the test is wrong or the feature already exists.
         Report to user and wait for instruction. Do not proceed.

4. GREEN phase
   a. Write minimal implementation. Touch ONLY implementation files.
   b. Run: [test command from Verification field]
   c. Confirm ALL tests pass — new and existing.

   GATE: If any existing test breaks → STOP.
         Report exactly which tests broke and why. Do not proceed.

5. REFACTOR phase
   a. Clean up implementation. No new behaviour introduced.
   b. Run: [test command from Verification field]
   c. Confirm still all green.

   GATE: If any test fails after refactor → STOP.
         Undo refactor changes and report.
```

**BOUNDARY CHECK:** Before writing any file, verify it is NOT listed in Boundaries > Do Not Change section. If it is, STOP and report.

**IMPLEMENTATION-BEFORE-TEST CHECK:** If implementation code for a task exists before the failing test is written, DELETE IT. Start clean. This is not negotiable.

**DESIGN QUALITY CHECK:** If the task involves frontend UI (components, pages, layouts, animations), activate the `designer-uxui` skill from `skills/designer-uxui/SKILL.md`. During REFACTOR phase, run the skill's Review Checklist against all UI code produced. Violations must be fixed before the task is marked complete.

**SHIP GATES (REFACTOR phase, after tests are green, before commit):**

| Gate | Skill | Activates on |
|------|-------|--------------|
| Security | `skills/security-gate/SKILL.md` | **Every task.** Secrets, trust-boundary validation, authz, injection, deps, `.env.example`. |
| Observability | `skills/observability-gate/SKILL.md` | backend / fullstack / devops, or any new async call or error boundary |
| SEO | `skills/seo-gate/SKILL.md` | frontend / fullstack touching a public page, route, layout, sitemap, robots |

Run each applicable checklist against `git diff main...HEAD`. A failed check is fixed inside the task. If the fix is outside the task's Boundaries → STOP, report, let the user widen scope or log to `.pm/ISSUES.md`. The task does not reach `git commit` with an open gate.
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- COMMIT, PUSH & PR — PER TASK                     -->
<!-- ════════════════════════════════════════════════ -->

<step name="commit_push_pr">
After all three TDD phases pass for a task:

1. **Stage and commit** — stage the task's files by name (never `git add -A`: it is how `.env`, build output, and stray dumps reach the remote). The PreToolUse `secrets-gate.sh` hook blocks the commit if a secret-shaped string is staged.
   ```bash
   git add [files from TASK-NN.md Files field + their tests]
   git status --short          # confirm nothing unexpected is staged
   git commit -m "feat(phase-N): task [N] — [task name]

   - RED: [test file] — X tests added, confirmed failing
   - GREEN: [impl file] — all X tests passing
   - REFACTOR: cleanup applied
   - Gates: security ✓ | observability ✓ | seo ✓/n/a"
   ```
   No AI co-author trailer. The commit is the user's.

2. **Push:**
   ```bash
   git push -u origin pm/{phase-name}-task-{N}
   ```

3. **Create PR for review:**
   ```bash
   gh pr create \
     --title "Task [N]: [task name]" \
     --body "$(cat <<'EOF'
   ## Summary
   [What this task delivers — from TASK-NN.md description]

   ## TDD Results
   | Phase | Result |
   |-------|--------|
   | RED | X tests added, confirmed failing |
   | GREEN | All Y tests passing |
   | REFACTOR | Cleanup applied, all tests green |

   ## Files Changed
   [List of files from git diff]

   ## Security
   - Secrets scan: clean
   - Trust boundaries touched: [list / none] — validated with [zod / …]
   - Authz: [object-level check on X / n/a]
   - New deps: [name — why / none]
   - Audit: `[pnpm|npm|pip] audit` high — clean

   ## Observability
   - Errors reported via: [Sentry / shared helper / n/a]
   - Swallowed catches: none
   - New env documented in .env.example: [names / none]

   ## SEO
   [per seo-gate PR section, or "n/a — authenticated route / no page touched"]

   ## Acceptance Criteria
   [From TASK-NN.md acceptance criteria]
   EOF
   )" \
     --base main \
     --head pm/{phase-name}-task-{N}
   ```

4. **CI gate — wait for checks before asking for a merge:**
   ```bash
   gh pr checks --watch --fail-fast
   ```
   - All green → continue to step 5.
   - A check fails → read the log (`gh run view --log-failed`), fix on the same branch, re-run the TDD verification command, commit, push. Repeat. Never ask the user to merge a red PR.
   - No checks reported after 60 s → the repo has no CI. Say so once, recommend `/pm:audit ci --fix`, continue.

5. **Ask user to review:**
   ```
   ════════════════════════════════════════
   PR READY FOR REVIEW
   ════════════════════════════════════════

   Task [N]: [task name]
   PR: [PR URL]
   Branch: pm/{phase-name}-task-{N}

   TDD: RED ✓ | GREEN ✓ | REFACTOR ✓
   Tests: X added, Y total passing
   Gates: security ✓ | observability ✓ | seo n/a
   CI: [N] checks passing

   ────────────────────────────────────────
   Review the PR and merge it to continue.
   Say "merged" when ready to proceed.
   ────────────────────────────────────────
   ```

   **HARD STOP.** Wait for user to confirm merge before proceeding to next task.
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- UPDATE LOCAL STATUS — PER TASK                   -->
<!-- ════════════════════════════════════════════════ -->

<step name="update_task_status">
**After user confirms PR is merged:**

1. Update `tasks/TASK-{NN}.md` — set completion record:
   ```
   | Status | Done |
   | Completed At | [ISO timestamp] |
   | Commit SHA | [short SHA] |
   | Tests Added | X |
   | Tests Passing | Y |
   | PR URL | [URL] |
   | Branch | pm/{phase-name}-task-{N} |
   ```

2. Mark all acceptance criteria checkboxes in TASK-NN.md as checked.

3. Update PLAN.md task status to `done` with completion metadata.

4. Update STORY.md task table — mark this task as `Done`.

5. Update STATE.md TDD Results section:
   ```
   task_[N]: RED ✓ | GREEN ✓ | REFACTOR ✓ | tests_added: X | passing: Y
   ```

6. Checkout main and pull:
   ```bash
   git checkout main
   git pull origin main
   ```

7. Proceed to next task.
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- CHECKPOINT HANDLING                               -->
<!-- ════════════════════════════════════════════════ -->

<step name="handle_checkpoints">
When a checkpoint task is reached (non-auto tasks):

**checkpoint:decision**
- Present decision context and options
- Wait for user selection
- Record decision
- Continue execution

**checkpoint:human-verify**
- Present what was built
- Present verification steps
- Wait for "approved" or issue description
- Continue execution

**checkpoint:human-action**
- Present required action
- Wait for "done" confirmation
- Continue execution
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- PHASE TRANSITION                                 -->
<!-- ════════════════════════════════════════════════ -->

<step name="phase_transition">
After all tasks in the current phase complete:

1. Check ROADMAP.md: are there more phases?
2. If yes:
   - Present: "Phase [N] complete. Phase [N+1] plan exists."
   - Ask: "Would you like to **review/revise** the plan for Phase [N+1], or **continue** as planned?"
   - If "revise" → instruct user to run `/pm:plan --revise N+1`
   - If "continue" → proceed to UNIFY for current phase
3. If no more phases: proceed to UNIFY (final)
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- COMPLETION                                       -->
<!-- ════════════════════════════════════════════════ -->

<step name="complete">
After all tasks complete:

```
════════════════════════════════════════
APPLY COMPLETE
════════════════════════════════════════

All [N] tasks complete.
PRs merged: [N]
Tests: [total] passing

TDD Results:
  Task 1: RED ✓ | GREEN ✓ | REFACTOR ✓
  Task 2: RED ✓ | GREEN ✓ | REFACTOR ✓

────────────────────────────────────────
▶ NEXT: /pm:unify
  Close the loop, write summary.
────────────────────────────────────────
```

Update STATE.md loop position: APPLY ✓
</step>

</process>

<success_criteria>
- [ ] GitHub remote verified before any code written
- [ ] Every task has its own branch created from main
- [ ] Every task completed RED → GREEN → REFACTOR in order
- [ ] No test passed before implementation (RED gate)
- [ ] No existing tests broken (GREEN gate)
- [ ] Every task passed the security gate; observability/SEO gates where applicable
- [ ] Every task committed with structured message, files staged by name, no AI co-author trailer
- [ ] Every task pushed and PR created via `gh pr create` with Security/Observability/SEO sections
- [ ] CI checks green (or absent and reported) before the user is asked to merge
- [ ] Every task's PR reviewed and merged by user before proceeding
- [ ] Every task's TASK-NN.md updated to Done with completion record
- [ ] STORY.md task table updated per task
- [ ] STATE.md TDD Results updated per task
- [ ] Already-completed tasks (Status: Done) skipped on resume
- [ ] Boundary files untouched
- [ ] Phase transition offered if more phases exist
- [ ] User informed of next action: /pm:unify
</success_criteria>
