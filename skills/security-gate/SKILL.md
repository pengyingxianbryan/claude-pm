---
name: security-gate
description: Use during /pm:apply on EVERY task and during /pm:audit security — enforces OWASP-aligned checks (secrets, trust-boundary validation, authz, injection, dependencies, env hygiene) before any PR is opened
---

# Security Gate — Ship Nothing Exploitable

## Overview

TDD proves the code does what you meant. This gate proves it does not also do what an attacker means. It runs in the REFACTOR phase of every task and again as a whole-repo sweep in `/pm:audit security`.

**Core principle:** Every bug here is cheaper to fix before the PR than after the incident.

## When This Skill Activates

- Every task in `/pm:apply`, during REFACTOR, before `git commit`. No discipline exemption — frontend leaks secrets too.
- `/pm:audit security` — whole-repo sweep against the same checklist.

## The Iron Law

```
NO SECRET IN GIT. NO UNVALIDATED INPUT PAST A TRUST BOUNDARY. NO AUTHZ BY ACCIDENT.
```

## Per-Task Checklist (REFACTOR phase)

Run against `git diff main...HEAD` — only the task's own changes.

### 1. Secrets

```bash
# Staged + committed on this branch. Zero tolerance.
git diff main...HEAD | grep -nE '(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]+|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|(api[_-]?key|secret|password|token)["'"'"']?\s*[:=]\s*["'"'"'][^"'"'"']{8,})' || echo "no secret patterns"
# If gitleaks is installed, prefer it:
command -v gitleaks >/dev/null && gitleaks detect --source . --log-opts="main...HEAD" --no-banner
```

- `.env*` files are in `.gitignore` (except `.env.example`).
- Every new `process.env.X` / `os.environ["X"]` read is documented in `.env.example` with a comment: purpose, scope, where the value comes from. **Never ship a new env dependency undocumented.**
- No credentials in test fixtures that are also valid in prod. A fixture key must be obviously fake.

**GATE:** any hit → remove it, rotate the credential if it was ever pushed, then re-run. A pushed secret is compromised even after a force-push.

### 2. Trust boundaries — input validation

A trust boundary is anywhere data enters from outside the process: HTTP body/query/headers/cookies, webhooks, CLI args, file uploads, DB rows written by other services, LLM output used as code/SQL/shell.

- Every boundary parses into a typed shape **before** use (zod / valibot / pydantic / explicit checks). No `req.body.foo` reaching business logic raw.
- Reject, don't sanitise: unknown fields dropped, wrong types 400, size limits enforced (body, upload, array length, string length).
- IDs from the client are never trusted to belong to the caller — see §3.

### 3. Authorisation

- Every route/handler/server action answers: **who** is calling (authn) and **may they touch this object** (authz). Object-level checks on every read AND write, not just the list endpoint (OWASP API1 / BOLA).
- Role/plan/feature checks live server-side. A hidden button is not a permission.
- Admin / cron / internal endpoints verify a secret or signature, with constant-time comparison (`crypto.timingSafeEqual`, `hmac.compare_digest`).
- Row-Level Security (Supabase/Postgres): a new table ships with RLS enabled and policies written. A `SECURITY DEFINER` function re-checks the caller inside its body and is revoked from `anon`.

### 4. Injection

- SQL: parameterised queries / query builder only. String-built SQL = STOP.
- Shell: no `exec(\`cmd ${userInput}\`)`. Use `execFile` / arg arrays.
- HTML: framework escaping by default; every `dangerouslySetInnerHTML` / `innerHTML` / `v-html` has a sanitiser (DOMPurify) and a comment saying why it exists.
- Path: user-supplied filenames resolved with `path.resolve` and checked against the allowed root. `..` is an attack, not a typo.
- SSRF: user-supplied URLs fetched server-side go through an allowlist (scheme https, host list, no private ranges).
- Redirects: `next`/`returnTo` params are same-origin relative paths only.

### 5. Crypto & sessions

- Passwords: argon2id / bcrypt via the framework. Never roll your own.
- Tokens: `crypto.randomBytes(32)` or framework equivalent. No `Math.random()` for anything security-relevant.
- Cookies: `HttpOnly; Secure; SameSite=Lax|Strict`. Session on auth change (login / password reset / role change) is rotated.
- JWT: algorithm pinned, expiry checked, verified with the public key — never `decode()` as a stand-in for `verify()`.

### 6. Dependencies

```bash
# Pick the one that matches the lockfile
pnpm audit --audit-level high || npm audit --audit-level=high || yarn npm audit --severity high
pip-audit || cargo audit || bundle audit || go list -m -json all | nancy sleuth
```

- A new dependency is justified in the PR body: what it does that ~20 lines couldn't, weekly downloads, last release date, licence.
- New high/critical advisory introduced by this task → STOP. Floor the version (overrides) or pick another package.

### 7. Error handling & information leak

- No stack traces, SQL, or internal paths in responses to clients. Log the detail, return a generic message + correlation id.
- Catch blocks never swallow silently — see `observability-gate`.
- `console.log` of request bodies, tokens, or PII is removed before commit.

### 8. Headers & transport (web)

- CSP, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`, HSTS set at the framework/edge layer. One place, not per route.
- CORS: explicit origin list, never `*` with credentials.
- Rate limit on auth, OTP, password reset, signup, and any endpoint that costs money (LLM calls, email, SMS).

### 9. Data & privacy

- PII fields named and minimised. Nothing collected "in case".
- Deletion paths exist for anything a user can create (GDPR/PDPA erasure).
- Analytics / telemetry never carries raw PII; hash or drop it.

## Reporting

On any failed check:

```
SECURITY gate failed — Task [N]

  [§ number] [check name]
  File: path:line
  Finding: [one line]
  Fix: [one line]

Fixing before commit. Task does not proceed to PR until clean.
```

Fix it in the same task. If the fix is out of the task's boundaries (e.g. needs a shared middleware), STOP and report — the user decides whether to widen scope or log it to `.pm/ISSUES.md` as `High`.

## PR Body Section

Every PR body carries:

```markdown
## Security
- Secrets scan: clean
- Trust boundaries touched: [list or "none"] — validated with [zod/...]
- Authz: [object-level check on X / n/a]
- New deps: [name — why / "none"]
- Audit: `pnpm audit --audit-level high` clean
```

A PR without this section is not ready for review.

## Common Rationalisations — All Invalid

| Excuse | Reality |
|--------|---------|
| "Internal endpoint, no auth needed" | Internal is a network claim, not a security one. SSRF makes it external. |
| "Frontend already validates" | The attacker doesn't use your frontend. |
| "It's just a dev key" | Dev keys get reused, leaked, and promoted. |
| "I'll add RLS later" | Later is after the data leak. |
| "The ORM escapes it" | Not inside `raw()` / `$queryRawUnsafe` / string templates. |
| "Nobody would guess that ID" | UUIDs leak in logs, URLs, and referrers. Check ownership. |
