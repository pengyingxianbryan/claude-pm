---
name: tdd-gate
description: Use when executing /pm:apply — enforces RED/GREEN/REFACTOR per task before any implementation code
---

# TDD Gate — RED/GREEN/REFACTOR Enforcement

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When This Skill Activates

This skill is MANDATORY during every `/pm:apply` execution. For each `<task>` in PLAN.md, the full RED/GREEN/REFACTOR cycle must complete before moving to the next task.

## The Iron Law

```
NO IMPLEMENTATION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

## Red-Green-Refactor Per Task

For each `<task>` in the PLAN.md `<tasks>` section:

### RED — Write Failing Test

1. Identify the test file from the task's `<files>` field
2. Write ONE minimal test showing what the task's `<done>` criteria requires
3. Touch ONLY test files — no implementation files
4. Run the test command from the task's `<verify>` field
5. **Confirm the new test FAILS**

**Requirements:**
- One behavior per test
- Clear test name describing the behavior
- Real code, not mocks (unless unavoidable)

**HARD GATE — If the test passes before implementation:**
```
STOP. Do not proceed.

This means either:
1. The test is wrong (doesn't test what you think)
2. The feature already exists

Report to user:
"RED gate failed: Test [test name] passed before implementation.
 This test does not prove anything new. Fix the test or confirm
 the feature already exists."

Wait for user instruction. Do not continue.
```

### GREEN — Minimal Implementation

1. Write the SIMPLEST code to make the failing test pass
2. Touch ONLY implementation files — no test files
3. Run the test command from `<verify>`
4. **Confirm ALL tests pass — new AND existing**

Don't add features. Don't refactor. Don't "improve" beyond the test.

**HARD GATE — If any existing test breaks:**
```
STOP. Do not proceed to the next task.

Report exactly which tests broke:
"GREEN gate failed: [N] existing tests now failing.
 Broken tests:
 - [test name]: [failure reason]
 - [test name]: [failure reason]

 Fix the implementation before continuing."

Wait for resolution. Do not move to REFACTOR.
```

### REFACTOR — Clean Up

1. Clean up implementation code — improve names, remove duplication, extract helpers
2. **No new behaviour introduced** — only restructuring
3. Run the test command from `<verify>`
4. **Confirm ALL tests still pass**

**HARD GATE — If any test fails after refactor:**
```
STOP. Undo the refactor changes.

Report:
"REFACTOR gate failed: Tests broke during cleanup.
 Reverting refactor. Implementation is GREEN but unrefactored."

Proceed with unrefactored code rather than breaking tests.
```

### After All Three Phases Pass

1. **Ship gates** — run `security-gate` (always), `observability-gate` and `seo-gate` (when applicable). Open finding = task not done.
2. **Commit** with structured message, files staged by name (never `git add -A`), no AI co-author trailer:
   ```
   feat(phase-N): task [N] — [task name]

   - RED: [test file] — X tests added, confirmed failing
   - GREEN: [impl file] — all X tests passing
   - REFACTOR: cleanup applied
   - Gates: security ✓ | observability ✓ | seo n/a
   ```
3. **Push** to task branch: `git push -u origin pm/{phase}-task-{N}`
4. **Create PR** via `gh pr create` for review, then `gh pr checks --watch` — green before asking for a merge
4. **Update TASK-NN.md** status to Done with completion record
5. **Update STATE.md** TDD Results section
6. Move to next task (after PR is merged)

## The Five Rules

### Rule 1: RED Must Genuinely Fail

If the test passes before implementation exists, the RED gate has failed. Stop and report. Never rationalise past this. A passing test proves nothing about new behaviour.

### Rule 2: GREEN Means ALL Tests Pass

Not just the new one. If any existing test breaks during implementation, stop immediately. Report exactly which tests failed. Do not move to the next task. Fixing broken tests is not optional.

### Rule 3: REFACTOR Means No New Behaviour

Only cleanup. Run full test suite after. Still green? Proceed. Any failure? Stop and report. If refactoring breaks tests, undo the refactor — working code trumps clean code.

### Rule 4: Delete Implementation Written Before Tests

If implementation code exists for a task before the failing test is written, delete it. Start clean. This is not negotiable. "Keep as reference" is a rationalisation — it biases your test design.

### Rule 5: One Task at a Time

Complete all three phases (RED, GREEN, REFACTOR) of one task before starting the next. Never batch tasks through RED together. Each task is an independent cycle.

## Boundary Enforcement

Before writing ANY file during a task, check:
- Is this file listed in `<boundaries>` DO NOT CHANGE section?
- If yes: STOP. Report. Do not modify.

Boundary violations are absolute — no exceptions, no "just this once."

## Common Rationalizations — All Invalid

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = skip it" | Hard to test = hard to use. Fix the design. |
| "Already manually tested" | Ad-hoc testing has no record and can't be re-run. |
| "Keep existing code as reference" | You'll adapt it. That's testing after. Delete. |
| "Just this once" | Every shortcut was "just this once." |

## Red Flags — Stop and Start Over

- Implementation code written before failing test exists
- Test passes immediately with no implementation
- Can't explain why test failed
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "Keep as reference"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Verification Checklist

Before marking a task complete:

- [ ] Test written FIRST (before any implementation)
- [ ] Watched test FAIL (RED confirmed)
- [ ] Failure was for expected reason (feature missing, not typo)
- [ ] Wrote MINIMAL code to pass (GREEN confirmed)
- [ ] ALL tests pass (new and existing)
- [ ] Refactored without breaking tests
- [ ] Committed with structured message
- [ ] Pushed to task branch
- [ ] PR created for review
- [ ] TASK-NN.md updated to Done

Cannot check all boxes? You skipped TDD. Start over.
