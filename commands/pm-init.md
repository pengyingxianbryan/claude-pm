---
name: pm:init
description: Initialize PM in a project with GitHub configuration and project setup
argument-hint:
allowed-tools: [Read, Write, Bash, Glob, AskUserQuestion]
---

<objective>
Initialize PM for a project: verify GitHub access, understand the project, generate a roadmap, and create phase directories.

**When to use:** Starting a new project with PM, or adding PM to an existing codebase.
</objective>

<context>
Current directory state (check for existing .pm/)
</context>

<process>

<!-- ════════════════════════════════════════════════ -->
<!-- STEP 1 — GITHUB SETUP                            -->
<!-- ════════════════════════════════════════════════ -->

<step name="check_credentials" priority="first">
1. Check if `.pm/.configured` exists
2. If configured: verify:
   - Run `gh auth status` — confirm GitHub CLI is authenticated
   - Verify git remote: `git ls-remote origin HEAD` — confirm repo is reachable
   - If both pass: skip to Step 2
   - If either fails: warn and offer to reconfigure

3. If NOT configured:
   a. Check `gh auth status` — if not authenticated, instruct: "Run `gh auth login` first, then re-run `/pm:init`." STOP.
   b. Collect GitHub repo:
      - Ask for GitHub repo URL (e.g., `https://github.com/org/repo` or `git@github.com:org/repo.git`)
      - Check current `git remote -v` — if `origin` already exists and matches, confirm and skip
      - If `origin` exists but differs: ask if they want to update it
      - If no `origin`: run `git remote add origin <repo_url>`
      - Verify connectivity: `git ls-remote origin HEAD`
        If fails: warn but allow retry or continue
   c. Create `.pm/` directory
   d. Write `.pm/.env`:
      ```
      GITHUB_REPO="https://github.com/org/repo"
      ```
   e. Add `.pm/.env` to `.gitignore` (if not already present)
   f. Touch `.pm/.configured`
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- STEP 1b — ENGINEERING BASELINE                   -->
<!-- ════════════════════════════════════════════════ -->

<step name="engineering_baseline">
Runs every init (new or existing repo). Detect, report, offer to scaffold. Never overwrite a file that exists.

1. **Detect stack** — lockfile → package manager (`pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` / `bun.lockb` / `requirements*.txt` / `go.mod` / `Cargo.toml`); manifest → framework (Next.js, Expo, Django, …). Read the test / lint / type-check script names from `package.json` (or equivalent).

2. **Check the baseline** and print one line per item:
   ```
   ENGINEERING BASELINE
     CI workflow (.github/workflows/*.yml with test step)   ✗ missing
     Security workflow (secrets scan + SAST + dep review)    ✗ missing
     dependabot.yml / renovate.json                           ✗ missing
     PR template                                              ✗ missing
     .gitignore covers .env*                                  ✓
     .env.example present                                     ✗ missing (3 env reads found)
     Error tracking SDK (Sentry or equivalent)                ✗ not in deps
     Branch protection on main                                ✗ none (gh api 404)
   ```

3. **Offer to scaffold** the missing files from `templates/github/` — ask once: "Scaffold the missing baseline now? (yes / pick / skip)".
   - Copy `ci.yml`, `security.yml`, `dependabot.yml`, `PULL_REQUEST_TEMPLATE.md` into `.github/` as needed.
   - Replace placeholders: `__PM_SETUP__` → the setup-node/pnpm/python/go steps for the detected stack; `__PM_TYPECHECK__` / `__PM_LINT__` / `__PM_TEST__` → the real script commands; `__PM_AUDIT__` → `pnpm audit --audit-level high` / `npm audit --audit-level=high` / `pip-audit` / …; `__PM_ECOSYSTEM__` → `npm` / `pip` / `gomod` / `cargo`.
   - Create `.env.example` listing every env read found, each with a comment block (purpose, scope, where the value comes from). Values empty.
   - Append `.env*` + `!.env.example` to `.gitignore` if absent.
   - Commit on a branch `pm/baseline` and open a PR — same discipline as any task. The user merges.

4. **Branch protection** — if `gh api repos/{owner}/{repo}/branches/main/protection` is 404, print the one command that fixes it and ask whether to run it:
   ```bash
   gh api -X PUT repos/{owner}/{repo}/branches/main/protection \
     -f required_status_checks[strict]=true -f required_status_checks[contexts][]=ci \
     -f enforce_admins=false -f required_pull_request_reviews[required_approving_review_count]=0 \
     -F restrictions=null -f allow_force_pushes=false -f allow_deletions=false
   ```
   (Review count 0 for solo repos; raise it when there is a second reviewer.) Free private repos without branch protection: note it as Accepted in STATE.md with the reason.

5. **Error tracking** — if no SDK is present, do not install here. Record it so Step 3 puts it in Phase 1 (see below).

Everything skipped is written to STATE.md `## Baseline gaps` so `/pm:audit ci` and `/pm:progress` keep surfacing it.
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- STEP 2 — PROJECT OVERVIEW                        -->
<!-- ════════════════════════════════════════════════ -->

<step name="check_existing">
1. Check for existing `.pm/PROJECT.md`
2. If exists: route to `/pm:resume` — do not re-initialize
3. If not: proceed with project conversation
</step>

<step name="project_conversation">
Have an open-ended conversation to understand the project. Ask follow-up questions as needed.

Start with: **"What are you building?"**

Through conversation, establish:
- What the product/feature is
- Who it's for (target users)
- Core value proposition
- Tech stack and constraints
- Key features / deliverables (3-5)
- What's explicitly out of scope

Do NOT use a rigid question script. Adapt to what the user shares. If they give a comprehensive overview upfront, don't re-ask what they've already covered.

Populate PROJECT.md from the conversation:
- Core value, description, type, features, tech stack, constraints, target users
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- STEP 3 — ROADMAP RECOMMENDATION                  -->
<!-- ════════════════════════════════════════════════ -->

<step name="recommend_roadmap">
Based on the project overview, propose a full multi-phase roadmap:

1. Analyze the project scope, dependencies, and complexity
2. Break into phases (typically 3-8 phases):
   - Phase 1 is always foundation/setup, and it **must** contain these tasks (skip only the ones the baseline check marked ✓):
       • CI + security workflows merged and required by branch protection
       • Error tracking wired (Sentry or equivalent) with env DSN, `environment`, `release`, source maps
       • `/api/health` (or equivalent) + external uptime monitor
       • Security headers (CSP, HSTS, nosniff, Referrer-Policy) set in one place
       • For projects with a public web surface: `robots.txt`, `sitemap`, root metadata (title/description/OG/Twitter), `Organization` JSON-LD
     Each is a normal task: discipline `devops` / `backend` / `frontend`, with Files, Verification, Done-when.
   - Middle phases deliver core features (vertical slices preferred)
   - Final phase is polish/deployment, and includes one `/pm:audit all` task whose Done-when is "no Critical/High open" 
3. For each phase, define:
   - Name and goal
   - Key deliverables
   - Dependencies on other phases
   - Estimated scope (number of plans)

Present the roadmap:
```
════════════════════════════════════════
PROPOSED ROADMAP — [project name]
════════════════════════════════════════

Phase 1: [name]
  Goal: [what this delivers]
  Scope: [deliverables]

Phase 2: [name]
  Goal: [what this delivers]
  Depends on: Phase 1
  Scope: [deliverables]

[... all phases ...]

════════════════════════════════════════
```

Ask: "Does this roadmap look right? Adjust anything, or say **APPROVE** to proceed."

If user requests changes: revise and re-present. Loop until approved.
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- STEP 4 — CREATE PHASE DIRECTORIES                -->
<!-- ════════════════════════════════════════════════ -->

<step name="create_structure">
After roadmap is approved, create the full directory structure:

```
.pm/
├── PROJECT.md          (populated from conversation)
├── ROADMAP.md          (populated from roadmap)
├── STATE.md            (initialized)
├── .env                (GitHub repo URL)
├── .configured         (sentinel)
└── phases/
    ├── 01-[phase-name]/
    ├── 02-[phase-name]/
    ├── 03-[phase-name]/
    └── ...
```

Write ROADMAP.md with full phase details (goals, dependencies, scope).
Write STATE.md with initialized loop position.
</step>

<!-- ════════════════════════════════════════════════ -->
<!-- COMPLETION                                       -->
<!-- ════════════════════════════════════════════════ -->

<step name="complete">
Display:

```
════════════════════════════════════════
PM INITIALIZED
════════════════════════════════════════

Project: [name]
Phases: [N] created

  .pm/phases/
  ├── 01-[name]/
  ├── 02-[name]/
  └── 03-[name]/

GitHub: [GITHUB_REPO] (gh authenticated)
Remote: [verified/unverified]

────────────────────────────────────────
▶ NEXT: /pm:plan
  Generate plans for all phases.
────────────────────────────────────────
```
</step>

</process>

<success_criteria>
- [ ] gh CLI authenticated (or user directed to authenticate)
- [ ] GitHub repo collected, origin remote configured, and connectivity verified
- [ ] .pm/.env created with GITHUB_REPO
- [ ] .pm/.env added to .gitignore
- [ ] .pm/.configured sentinel created
- [ ] Engineering baseline detected and reported; missing CI/security/dependabot/PR template/.env.example offered from templates/github/ (never overwriting)
- [ ] Branch protection checked; fix command offered
- [ ] Skipped baseline items recorded in STATE.md ## Baseline gaps
- [ ] Phase 1 roadmap carries the mandatory baseline tasks
- [ ] Project conversation completed — PROJECT.md populated
- [ ] Roadmap proposed, refined, and approved
- [ ] ROADMAP.md written with all phase details
- [ ] Phase directories created under .pm/phases/
- [ ] STATE.md initialized
- [ ] User presented with ONE clear next action: /pm:plan
</success_criteria>
