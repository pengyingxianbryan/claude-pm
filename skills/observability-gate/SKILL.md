---
name: observability-gate
description: Use during /pm:apply on backend, fullstack and devops tasks — enforces error tracking (Sentry or equivalent), structured logs, health checks, and no silently swallowed failures so production tells you when it breaks
---

# Observability Gate — Production Must Be Able To Page You

## When This Skill Activates

- Backend / fullstack / devops tasks: any new route, handler, server action, cron, queue consumer, worker, or external API call.
- Frontend tasks that add async data fetching or error boundaries.
- `/pm:audit observability` — whole-repo sweep.

Runs in REFACTOR alongside `security-gate`.

## The Iron Law

```
AN ERROR NOBODY SEES IS A BUG NOBODY FIXES.
```

## Checklist

### 1. Error tracking is wired

- Project has an error tracker (Sentry is the default; Bugsnag / Rollbar / Datadog / Highlight equivalent). If not: the first backend task of Phase 1 adds it. For Next.js: `npx @sentry/wizard@latest -i nextjs`; for RN/Expo: `@sentry/react-native`; for Python: `sentry-sdk`.
- DSN comes from env, documented in `.env.example`. Never hard-coded.
- `environment` and `release` are set (git SHA or app version) so a regression is attributable to a deploy.
- Source maps uploaded in CI (web) or at build (mobile) — a minified stack is noise.
- PII scrubbing on: `sendDefaultPii: false`, `beforeSend` strips emails/tokens from breadcrumbs. Tracking must not become the leak.

### 2. No swallowed errors

```bash
# Catch blocks with no report or rethrow — each one is a silent failure.
git diff main...HEAD | grep -nE 'catch\s*(\([^)]*\))?\s*\{\s*\}' && echo "EMPTY CATCH — fix"
git diff main...HEAD | grep -nE '\.catch\(\s*\(\)\s*=>\s*\{\s*\}\s*\)' && echo "SWALLOWED PROMISE — fix"
```

- Every `catch` does one of: rethrow, return a typed error the caller handles, or report (`Sentry.captureException(err, { tags, extra })`) then degrade deliberately. "Log and continue" needs a comment explaining why continuing is safe.
- Fire-and-forget promises (`void doThing()`, unawaited `fetch`) attach a `.catch` that reports.
- Background jobs / crons report start, success, and failure. A cron that dies silently is the same as no cron.

### 3. Server responses never leak internals

- Client gets: generic message + `requestId`. Tracker gets: full error, request context, user id (hashed if required).
- Unexpected `throw` in a route → caught by one shared handler (`serverError(err, req)`), not 24 bespoke `try/catch` blocks. If the project has such a helper, new routes **use it**.

### 4. Structured logs

- `logger.info({ requestId, userId, orgId, route, durationMs }, "msg")` — objects, not string concatenation. JSON in prod.
- One correlation id per request, propagated to outbound calls and the error tracker.
- Levels mean something: `error` pages someone, `warn` is reviewed weekly, `info` is for tracing, `debug` is off in prod.
- Never log: tokens, passwords, full request bodies, card numbers, raw PII.

### 5. Health & uptime

- `GET /api/health` (or framework equivalent) returns 200 with `{ status, version, checks: { db, cache, ... } }`. Cheap, unauthenticated, no side effects.
- An external uptime monitor hits it (Better Stack, UptimeRobot, Checkly, healthchecks.io). If none exists, log `.pm/ISSUES.md` `High` — a 99.9 % promise with no monitor is a hope.
- Crons ping a dead-man's-switch (healthchecks.io style) on success so a *missing* run is alerted, not just a failing one.

### 6. Alert routing

- Tracker alert rules exist for: new issue, regression, error-rate spike. They reach a human channel (Slack / Telegram / email / PagerDuty), not only the tracker inbox.
- Alert payloads include the project and environment — a webhook with only a numeric id is unactionable.
- Every alert integration has a verified send (`sendMessage` returns 2xx), not just a passing `getMe`. Integrations that swallow `!res.ok` die silently.

### 7. Metrics that matter (when the project is live)

- Per deploy: error rate, p95 latency, request count on the top 5 routes. Dashboards are optional; alerts on these are not.
- Business-critical flows (signup, checkout, upload, sync) emit one success/failure event each so a 0 % conversion morning is caught by a threshold, not a customer.

## Reporting

```
OBSERVABILITY gate — Task [N]

  ✓ route uses serverError() helper
  ✗ cron /api/cron/reap has no failure report → Sentry.captureException added
  ✓ new env SENTRY_DSN documented in .env.example
  ✓ no empty catch blocks in diff
```

## PR Body Section

```markdown
## Observability
- Errors: reported via [Sentry / helper name] ✓
- Swallowed catches: none
- Logs: structured, requestId propagated ✓
- Health/uptime: [unchanged / added /api/health]
- New env: SENTRY_DSN (documented)
```
