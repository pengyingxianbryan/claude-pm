---
name: pm:audit
description: Audit the repo against industry baselines — security (OWASP), observability (Sentry/logs/health), SEO/AEO, and GitHub CI — producing a dated report and promoting findings to ISSUES.md
argument-hint: "[security|observability|seo|ci|all] [--fix]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

<objective>
Whole-repo sweep against the same checklists the per-task gates enforce, so drift that pre-dates PM (or slipped past a gate) is found, scored, and tracked.

**When to use:** After `/pm:init` on an existing codebase (baseline), before `/pm:verify` on a phase that touched auth/data/public pages, before any external pen-test or SOC 2 / ISO evidence request, or on a schedule.

Report always comes before any change. `--fix` applies low-risk fixes only, each as its own task branch + PR through the normal `/pm:apply` discipline.
</objective>

<context>
Scope: $ARGUMENTS (default: `all`)

@.pm/STATE.md
@.pm/PROJECT.md
</context>

<process>

<step name="scope" priority="first">
1. Parse scope: one of `security | observability | seo | ci | all`. Unknown → print usage, STOP.
2. Detect stack from lockfiles / manifests (pnpm/npm/yarn/bun, pip, go, cargo) and framework (Next.js, Expo, Django, …). Record in the report header.
3. Find the previous audit for the same scope in `.pm/audits/` — needed for the Δ column.
4. Confirm clean working tree. Audit runs against HEAD.
</step>

<step name="security" condition="scope in [security, all]">
Load `skills/security-gate/SKILL.md`. Run every § against the **whole repo**, not a diff:

- §1 `gitleaks detect --source . --no-banner` if installed, else the grep pattern from the skill over `git ls-files`. Plus `git log -p --all -S'PRIVATE KEY' --oneline | head` — history counts.
- §1 `.gitignore` covers `.env*` (except `.env.example`); every `process.env.X` / `os.environ` read is present in `.env.example`.
- §2 Grep every route / handler / server action entry point; each must parse its input through a validator before use. List the ones that don't.
- §3 For each entry point: authn present? object-level authz present? Supabase/Postgres: every table in migrations has `ENABLE ROW LEVEL SECURITY` + at least one policy; every `SECURITY DEFINER` function has an inner caller check and `REVOKE ... FROM anon`.
- §4 Grep: `\$queryRawUnsafe|raw\(|exec\(|execSync\(|dangerouslySetInnerHTML|innerHTML|redirect\(.*req` — each hit reviewed.
- §6 Run the stack's audit at `high`. Record count.
- §8 Fetch headers of the deployed URL if PROJECT.md has one: `curl -sI <url>` — check CSP, HSTS, nosniff, Referrer-Policy. Rate limiting present on auth/OTP/signup routes?

Every failed check → finding with severity per `templates/AUDIT.md` rubric.
</step>

<step name="observability" condition="scope in [observability, all]">
Load `skills/observability-gate/SKILL.md`:

- §1 Error tracker SDK present in deps and initialised with env DSN, `environment`, `release`? Source-map upload step in CI/build?
- §2 Grep empty catches, swallowed promises, `catch { return null }` patterns repo-wide. Count and list top offenders.
- §3 Is there one shared server-error helper? How many routes bypass it?
- §4 Logger is structured (pino/winston/structlog) or `console.*` everywhere? Grep logs for token/password/body fields.
- §5 Health endpoint exists? External uptime monitor configured (ask the user if unknowable from the repo)?
- §6 Alert rules → human channel? Webhook payload includes project/env?
</step>

<step name="seo" condition="scope in [seo, all]">
Skip with "n/a — no public web surface" if the project has no unauthenticated pages. Otherwise load `skills/seo-gate/SKILL.md`:

- §1 Every public route exports metadata with title + description + canonical + OG + Twitter (both or neither). List routes missing any.
- §2 `robots.txt`, `sitemap.xml` present, generated from routes, reachable without auth redirect (check middleware matcher).
- §3 JSON-LD present on root / pricing / docs / blog as applicable; validate at least one.
- §4 If a dev server or deployed URL is available: `npx lighthouse <url> --only-categories=performance,seo,accessibility --quiet --output=json` for home + 2 key pages. Record scores.
</step>

<step name="ci" condition="scope in [ci, all]">
- `.github/workflows/` has a PR workflow running type-check + lint + test + dependency audit (compare against `templates/github/ci.yml`). Missing steps listed.
- Security workflow present (secrets scan + SAST + dependency review) — compare `templates/github/security.yml`.
- `dependabot.yml` or Renovate present.
- PR template present.
- Branch protection on `main`: `gh api repos/{owner}/{repo}/branches/main/protection` — required status checks include CI; required reviews ≥ 1 (solo repos: note as Accepted); force-push disabled. 404 means unprotected → High.
- `gh api repos/{owner}/{repo}` → `security_and_analysis`: secret scanning + push protection enabled where the plan allows.
- Workflow hygiene: `permissions:` declared (least privilege), `timeout-minutes` set, actions pinned to a major tag at minimum, `concurrency` on PR workflows.
</step>

<step name="report">
Write `.pm/audits/AUDIT-{YYYY-MM-DD}-{scope}.md` from `templates/AUDIT.md`. Then print:

```
════════════════════════════════════════
AUDIT — {scope} — {date}
════════════════════════════════════════

Result: PASS | FAIL

            Crit  High  Med  Low   Δ
Security      0     1    3    2   −2
Observ.       0     0    2    1   new
SEO           —     —    —    —   n/a
CI            0     2    0    0   new

Top findings:
  AUD-001 High  security §3  apps/web/src/app/api/export/route.ts:14 — no object-level authz
  AUD-002 High  ci           main branch unprotected
  AUD-003 High  ci           no secrets scan workflow

Report: .pm/audits/AUDIT-2026-10-08-all.md
────────────────────────────────────────
```
</step>

<step name="promote">
Ask: "Promote Critical/High findings to `.pm/ISSUES.md`? (yes / pick / no)"

For each promoted finding create an ISSUE entry (format from `/pm:unify`) with `Origin: AUDIT-{date}-{scope} / AUD-NNN`. Critical → `Priority: Highest`. Update the finding's **Promoted to** field.

Critical findings also go to STATE.md `## Blockers` — `/pm:progress` and `/pm:resume` surface them first.
</step>

<step name="fix" condition="--fix present">
Low-risk only, each via the normal task discipline (branch → TDD where testable → security gate → PR → user merges):

- Scaffold missing `.github/` files from `templates/github/` (fill `__PM_*__` placeholders for the detected stack).
- Add missing `.gitignore` entries.
- Add missing `.env.example` entries for env reads found.
- Add `permissions:` / `timeout-minutes:` / `concurrency:` to workflows lacking them.
- Add metadata/canonical to routes missing them where title/description can be derived from the page's H1 and first paragraph.

Everything else (authz, validation, RLS, error handling, header policy) is **not** auto-fixed — it changes behaviour and needs a planned task. Point at `/pm:plan --fix` or `--add-phase "Security hardening"`.
</step>

</process>

<success_criteria>
- [ ] Scope parsed, stack detected
- [ ] Every in-scope checklist § run repo-wide with evidence (command + excerpt)
- [ ] Report written to .pm/audits/ with severities and Δ vs previous
- [ ] Critical/High offered for promotion to ISSUES.md; Critical added to STATE.md blockers
- [ ] --fix touched only the low-risk list, via branch + PR, never direct to main
- [ ] User given ONE next action
</success_criteria>
