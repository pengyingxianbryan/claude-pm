# PM

Story -> Tasks -> Approval -> TDD -> Ship Gates -> Github

A Claude Code plugin that extends PAUL's Plan-Apply-Unify loop with local Story/Task tracking, GitHub per-task PRs, and strict TDD enforcement.

---

## Installation

### From GitHub

```bash
# Register the marketplace
/plugin marketplace add pengyingxianbryan/claude-pm

# Install the plugin
/plugin install claude-pm
```

### Manual

Clone the repo and point Claude Code at the `pm/` directory.

---

### 1. Local Story/Task Tracking

PM creates a Jira-style hierarchy of markdown files under each phase — no external Jira instance needed. Each phase gets a `STORY.md` (like a Jira Story) and individual `TASK-NN.md` files (like Jira Subtasks). Tasks update their own status independently as work progresses.

```
.pm/phases/01-foundation/
├── STORY.md              # Phase story — status, ACs, scope
├── tasks/
      ├── TASK-01.md        # Task — status, ACs, completion record
│   └── TASK-02.md
├── 01-01-PLAN.md         # Executable plan
└── 01-01-SUMMARY.md      # After completion
```

### 2. GitHub Integration with Per-Task PRs

Every task gets its own branch and Pull Request for review. PM creates a branch from main (`pm/{phase}-task-{N}`), runs TDD, commits, pushes, and opens a PR via `gh pr create`. You review and merge before PM proceeds to the next task. Work is never lost if a session ends unexpectedly.

### 3. Premium Design Enforcement

When tasks involve frontend UI, the `designer-uxui` skill activates automatically during APPLY. It enforces premium design standards: proper animation easing and duration, typographic hierarchy, responsive layouts, accessibility (`prefers-reduced-motion`), and performance (GPU-composited properties only). Stack: Next.js App Router + Tailwind CSS + Motion.

### 4. Superpowers-style TDD Enforcement

Every task in APPLY runs through a strict RED → GREEN → REFACTOR cycle with hard gates:
- **RED:** Write failing test first. If test passes before implementation, STOP.
- **GREEN:** Write minimal implementation. If any existing test breaks, STOP.
- **REFACTOR:** Clean up only. No new behaviour. If tests break, undo.

Implementation code written before a failing test exists is deleted. No exceptions.

### 5. Full Plan Upfront

Unlike PAUL's sequential plan-one-execute-one approach, PM generates plans for ALL phases during `/pm:plan` and presents them for a single APPROVE. Plans can be revised between phases as learnings emerge.

### 6. Ship Gates — Security, Observability, SEO

TDD proves the code does what you meant. The ship gates prove it is also safe to run in public. They run in the REFACTOR phase of every task, before commit:

| Gate | Runs on | Checks |
|---|---|---|
| `security-gate` | **every task** | Secrets, trust-boundary validation, object-level authz, injection, crypto/sessions, dependency audit, headers, `.env.example` hygiene (OWASP-aligned) |
| `observability-gate` | backend / fullstack / devops | Error tracking (Sentry or equivalent) wired with env DSN + release, no swallowed catches, structured logs, health endpoint, alert routing |
| `seo-gate` | frontend touching a public page | Per-page metadata, canonical, OG + Twitter together, robots/sitemap, JSON-LD, Core Web Vitals, a11y floor |

Every PR body carries a Security / Observability / SEO section. After `gh pr create`, PM waits on `gh pr checks --watch` and never asks you to merge a red PR.

A **PreToolUse hook** (`hooks/secrets-gate.sh`) mechanically blocks any `git commit` or `git push` whose added lines contain a secret-shaped string (AWS keys, `sk-…`, `ghp_…`, private keys, JWTs, `password = "…"`). Prose rules get rationalised past; an exit-2 hook does not.

### 7. Engineering Baseline at Init

`/pm:init` detects the stack and reports what the repo is missing — CI workflow, security workflow (gitleaks + semgrep + dependency review + nightly audit), `dependabot.yml`, PR template, `.env.example`, branch protection — and offers to scaffold the missing pieces from `templates/github/` on a `pm/baseline` branch. Phase 1 of every roadmap must carry the remaining baseline tasks (error tracking, health + uptime, security headers, robots/sitemap/metadata for web).

### 8. `/pm:audit` — Whole-Repo Sweep

The per-task gates only see the diff. `/pm:audit [security|observability|seo|ci|all]` runs the same checklists across the entire repo plus GitHub settings (branch protection, secret scanning), writes a dated report to `.pm/audits/` with a Δ against the previous run, and promotes Critical/High findings to `.pm/ISSUES.md`. `--fix` applies low-risk scaffolding only, via branch + PR. Run it as a baseline on an existing codebase, before `/pm:verify` on phases that touch auth/data/public pages, and before any pen-test or SOC 2 / ISO evidence request.

---

## The Loop

```
INIT ──▶ PLAN ALL ──▶ APPROVE ──▶ [per-phase loop]
                                   │
                                   APPLY ──▶ UNIFY
                                   (TDD + PR)
                                   ↕
                                   optional plan revision
```

### Per-Task Workflow

| PM Event | Local Tracking | GitHub Action |
|---|---|---|
| `/pm:plan` approved | STORY.md + TASK-NN.md created (To Do) | — |
| Task starts | TASK-NN.md → In Progress | Branch created from main |
| TDD passes | Completion record filled | Commit + push |
| PR created | — | `gh pr create` |
| PR merged | TASK-NN.md → Done | Back to main, pull |
| All tasks done | STORY.md → In Progress | — |
| `/pm:unify` | STORY.md → In Review | — |
| `/pm:verify` PASS | STORY.md → Done | — |

---

## Setup

On first run in a project, PM's SessionStart hook detects that `.pm/.configured` is missing and directs you to run `/pm:init`.

### `/pm:init` Flow

1. **GitHub** — Checks `gh auth status`, collects repo URL, verifies remote connectivity
2. **Project overview** — Open-ended conversation: what you're building, who it's for, tech stack
3. **Roadmap** — PM proposes a multi-phase roadmap, you refine, approve
4. **Phase directories** — Creates `.pm/phases/01-name/`, `02-name/`, etc.

GitHub authentication is handled by `gh auth login` — no token stored in PM.

---

## Plan Modes

### Mode 1: Plan All (Default)

PM generates plans for all phases at once.

```
/pm:plan

# PM reads ROADMAP.md and generates PLAN.md for every phase
# Presents all plans for review

# User says: APPROVE

# PM automatically creates:
# - STORY.md per phase
# - tasks/TASK-NN.md per task

All plans approved. Local tracking created:
  Phase 1: Foundation
    ├── STORY.md (Highest priority)
    ├── tasks/TASK-01.md [backend]
    └── tasks/TASK-02.md [frontend]

Run /pm:apply to begin Phase 1.
```

### Mode 2: Revise

Update a plan for a specific phase based on learnings from completed phases.

```
/pm:plan --revise 3

# PM reads completed phase summaries
# Revises Phase 3 plan incorporating learnings
# Presents revised plan for APPROVE
# Updates STORY.md and TASK-NN.md files
```

---

## TDD Gate

During `/pm:apply`, every task runs through RED → GREEN → REFACTOR:

### RED — Write Failing Test

- Write test FIRST. Touch ONLY test files.
- Run tests. Confirm new test FAILS.
- **HARD GATE:** If test passes before implementation → STOP. Report to user.

### GREEN — Minimal Implementation

- Write SIMPLEST code to pass the failing test.
- Run tests. Confirm ALL tests pass (new + existing).
- **HARD GATE:** If any existing test breaks → STOP. Report exactly which tests.

### REFACTOR — Clean Up

- Clean up. No new behaviour.
- Run tests. Confirm still all green.
- **HARD GATE:** If any test fails → STOP. Undo refactor.

### After Each Task

```bash
# Ship gates (security always; observability/seo when applicable) — must be clean

# Stage by name — never `git add -A` — then commit. Secrets hook may block; fix, never bypass.
git add src/auth/login.ts src/auth/login.test.ts
git commit -m "feat(phase-1): task 1 — create login endpoint

- RED: login.test.ts — 3 tests added, confirmed failing
- GREEN: login.ts — all 3 tests passing
- REFACTOR: cleanup applied
- Gates: security ✓ | observability ✓ | seo n/a"

# Push, create PR (with Security/Observability/SEO sections), wait for CI
git push -u origin pm/01-foundation-task-1
gh pr create --title "Task 1: Create login endpoint" ...
gh pr checks --watch --fail-fast

# User reviews and merges PR
# TASK-01.md updated to Done with completion record
```

---

## UNIFY — Close the Loop

`/pm:unify` does everything PAUL's unify does, plus:

1. **Creates SUMMARY.md** with reconciliation of plan vs actual
2. **Updates STORY.md** status to `In Review`
3. **Triages deferred issues** — categorizes, logs to ISSUES.md
4. **Lists all merged PRs** from the apply phase

---

## Command Reference — 11 Commands

| Command | What it does |
|---|---|
| `/pm:init` | Set up project — GitHub config, overview, roadmap, phase directories |
| `/pm:plan` | Plan all phases, revise, fix UAT issues, or modify roadmap |
| `/pm:apply` | Execute with TDD (RED/GREEN/REFACTOR), per-task branches + PRs |
| `/pm:unify` | Close loop — summary, reconciliation, triage deferred issues |
| `/pm:audit` | Security / observability / SEO / CI sweep — dated report, findings → ISSUES.md |
| `/pm:verify` | UAT gate — PASS updates to Done, FAIL captures issues |
| `/pm:progress` | Status across all phases + ONE next action |
| `/pm:pause` | Full handoff + session continuity |
| `/pm:resume` | Restore context from STATE.md and handoffs |
| `/pm:research` | Research topic, phase unknowns, or map codebase |
| `/pm:help` | Command reference |

### `/pm:plan` arguments

| Argument | Mode |
|---|---|
| (none) | **Plan All** — generate plans for every phase |
| `--revise N` | **Revise** — update plan for phase N |
| `--fix N` | **Fix** — create fix plan from UAT issues |
| `--add-phase <desc>` | **Add Phase** — append to roadmap |
| `--remove-phase N` | **Remove Phase** — remove future phase |

### `/pm:audit` arguments

| Argument | Scope |
|---|---|
| `security` | OWASP: secrets (incl. history), validation, authz, injection, deps, headers, RLS |
| `observability` | Error tracking, swallowed catches, logs, health, uptime, alert routing |
| `seo` | Metadata, robots/sitemap, JSON-LD, Lighthouse CWV (public surface only) |
| `ci` | Workflows, dependabot, PR template, branch protection, secret scanning, workflow hygiene |
| `all` (default) | Everything above |
| `--fix` | Low-risk fixes only (scaffolds, .gitignore, .env.example, workflow hygiene) via branch + PR |

### `/pm:research` arguments

| Argument | Mode |
|---|---|
| `<topic>` | Research a specific topic |
| `phase N` | Identify and research unknowns for phase N |
| `codebase` | Map the existing codebase |

---

## Repo Structure

```
pm/
├── .claude-plugin/
│   ├── marketplace.json       # Marketplace registration
│   └── plugin.json            # Plugin metadata
├── hooks/
│   ├── hooks.json             # SessionStart + PreToolUse hook config
│   ├── setup.sh               # Thin sentinel check — defers to /pm:init
│   └── secrets-gate.sh        # Blocks git commit/push carrying a secret-shaped string
├── commands/                  # 11 commands total
│   ├── pm-init.md             # Project setup: GitHub, engineering baseline, overview, roadmap
│   ├── pm-plan.md             # Plan all / revise / fix / add-phase / remove-phase
│   ├── pm-apply.md            # TDD + ship gates, per-task branches, PRs, CI wait
│   ├── pm-unify.md            # Loop closure: summary, reconciliation, deferred issues
│   ├── pm-verify.md           # UAT confirmation gate
│   ├── pm-audit.md            # Security / observability / SEO / CI sweep
│   ├── pm-progress.md         # Smart status with task-level visibility
│   ├── pm-pause.md            # Full handoff
│   ├── pm-resume.md           # Context restoration
│   ├── pm-research.md         # Research topic / phase / codebase
│   └── pm-help.md             # Command reference
├── skills/
│   ├── tdd-gate/SKILL.md          # RED/GREEN/REFACTOR enforcement
│   ├── designer-uxui/SKILL.md     # Premium frontend design enforcement
│   ├── security-gate/SKILL.md     # OWASP-aligned per-task + repo checks
│   ├── observability-gate/SKILL.md# Sentry / logs / health / alerts
│   └── seo-gate/SKILL.md          # Metadata / crawlability / JSON-LD / CWV
├── templates/
│   ├── PLAN.md                # Plan template (readable markdown)
│   ├── STATE.md               # State template with GitHub/TDD/Baseline/Audits sections
│   ├── STORY.md               # Phase story template (Jira-style)
│   ├── TASK.md                # Individual task template (Jira-style)
│   ├── PROJECT.md             # Project context template
│   ├── ROADMAP.md             # Phase structure template
│   ├── SUMMARY.md             # Completion documentation template
│   ├── AUDIT.md               # /pm:audit report template + severity rubric
│   └── github/
│       ├── ci.yml                     # type-check + lint + test + dep audit on PR
│       ├── security.yml               # gitleaks + semgrep + dependency review + nightly audit
│       ├── dependabot.yml             # weekly, grouped
│       └── PULL_REQUEST_TEMPLATE.md   # TDD + Security + Observability + SEO sections
├── rules/
│   └── pm-rules.md            # 10 hard rules
├── CLAUDE.md                  # Agent instructions
├── LICENSE                    # MIT
└── README.md                  # This file
```

---

## How to Reconfigure

Delete the sentinel file and run init again:

```bash
rm .pm/.configured
/pm:init
```

---

## License

MIT — see [LICENSE](LICENSE).

---

*PM v3.1 — Just Approval → Driven Test → Evaluation*
*Built on [PAUL](https://github.com/ChristopherKahler/paul) (Plan-Apply-Unify Loop) + [Superpowers TDD](https://github.com/nicholasgriffintn/superpowers)*
