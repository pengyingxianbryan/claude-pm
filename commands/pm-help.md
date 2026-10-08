---
name: pm:help
description: Show available PM commands and usage guide
---

<objective>
Display the complete PM command reference.

Output ONLY the reference content below. Do NOT add project-specific analysis, git status, or commentary.
</objective>

<reference>
# PM Command Reference

**PM** (Just Approval → Driven Test → Evaluation) extends PAUL's Plan-Apply-Unify loop with local Story/Task tracking, GitHub per-task PRs, and Superpowers-style TDD enforcement.

## The Loop

```
INIT ──▶ PLAN ALL ──▶ APPROVE ──▶ [per-phase loop]
                                   APPLY ──▶ UNIFY
                                   ↕
                                   optional revision
```

## 11 Commands

| Command | What it does |
|---|---|
| `/pm:init` | Set up project — GitHub config, overview, roadmap, phase directories |
| `/pm:plan` | Plan all phases, revise, fix UAT issues, or modify roadmap |
| `/pm:apply` | Execute with TDD (RED/GREEN/REFACTOR), per-task branches + PRs |
| `/pm:unify` | Close loop — summary, reconciliation, triage deferred issues |
| `/pm:audit` | Security / observability / SEO / CI sweep → dated report, findings → ISSUES.md |
| `/pm:verify` | UAT gate — PASS updates to Done, FAIL captures issues |
| `/pm:progress` | Status across all phases + ONE next action |
| `/pm:pause` | Full handoff + session continuity |
| `/pm:resume` | Restore context from STATE.md and handoffs |
| `/pm:research` | Research topic, phase unknowns, or map codebase |
| `/pm:help` | This reference |

## `/pm:plan` Arguments

| Argument | Mode |
|---|---|
| (none) | **Plan All** — generate plans for every phase |
| `--revise N` | **Revise** — update plan for phase N |
| `--fix N` | **Fix** — create fix plan from UAT issues |
| `--add-phase <desc>` | **Add Phase** — append to roadmap |
| `--remove-phase N` | **Remove Phase** — remove future phase |

## `/pm:research` Arguments

| Argument | Mode |
|---|---|
| `<topic>` | Research a specific topic |
| `phase N` | Identify and research unknowns for phase N |
| `codebase` | Map the existing codebase |

## `/pm:audit` Arguments

| Argument | Scope |
|---|---|
| `security` | OWASP: secrets, validation, authz, injection, deps, headers, RLS |
| `observability` | Error tracking, swallowed catches, logs, health, alerts |
| `seo` | Metadata, robots/sitemap, JSON-LD, Core Web Vitals (public surface only) |
| `ci` | Workflows, dependabot, PR template, branch protection, secret scanning |
| `all` (default) | Everything above |
| `--fix` | Apply low-risk fixes (scaffolds, .gitignore, .env.example) via branch + PR |

## Ship Gates (per task, REFACTOR phase)

```
security       — every task. Secrets hook blocks commit/push mechanically.
observability  — backend / fullstack / devops. Nothing fails silently.
seo            — frontend touching a public page. Every page earns its index.
CI             — gh pr checks --watch green before a merge is requested.
```

## Local Tracking

PM creates Jira-style local files under each phase:

```
.pm/phases/01-foundation/
├── STORY.md              # Phase story (status, ACs, scope)
├── tasks/
│   ├── TASK-01.md        # Individual task (status, ACs, completion record)
│   └── TASK-02.md
├── 01-01-PLAN.md         # Executable plan
└── 01-01-SUMMARY.md      # After completion
```

Each task updates its own status: `To Do` → `In Progress` → `Done`

## Per-Task PR Workflow

| PM event | GitHub action |
|---|---|
| Task starts | Branch `pm/{phase}-task-{N}` created from main |
| TDD passes | Commit + push to task branch |
| After push | PR created via `gh pr create` |
| User reviews | Merge PR before next task proceeds |
| All tasks merged | UNIFY closes the loop |

## TDD Gate (per task)

```
RED    — Write failing test → GATE: passes early? STOP.
GREEN  — Minimal implementation → GATE: breaks existing? STOP.
REFACTOR — Clean up only → GATE: breaks anything? Undo.
```

## Key Principles

1. **APPROVE before execution** — no code without explicit approval
2. **Full plan upfront** — all phases planned at once, revised as needed
3. **TDD per task** — RED → GREEN → REFACTOR, no exceptions
4. **Per-task PRs** — every task gets its own branch and PR for review
5. **Local tracking** — Story/Task .md files update per-task, not per-phase
6. **GitHub gate** — remote verified before any code
7. **UNIFY every phase** — no orphan phases
8. **Boundaries are absolute** — DO NOT CHANGE means DO NOT CHANGE
9. **Ship gates** — security on every task, observability/SEO where applicable, CI green before merge
10. **Baseline at init** — CI, security workflows, dependabot, PR template, .env.example, branch protection

---

*PM v3.1 | Built on PAUL + Superpowers TDD + OWASP*
</reference>
