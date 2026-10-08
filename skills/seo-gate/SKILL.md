---
name: seo-gate
description: Use during /pm:apply when a frontend task adds or changes a public page, route, layout, or marketing/docs content — enforces metadata, crawlability, structured data, Core Web Vitals and AEO (answer-engine) basics
---

# SEO Gate — Every Public Page Earns Its Index

## When This Skill Activates

Frontend / fullstack tasks that touch any of:
- `app/**/page.*`, `app/**/layout.*`, `pages/**`, route files, `sitemap.*`, `robots.*`
- Marketing, docs, blog, landing, pricing, or any page reachable without login

Skip for authenticated dashboards, admin consoles, and API-only tasks. Say so in the PR body ("SEO: n/a — authenticated route").

Works alongside `designer-uxui` (visual craft) and `security-gate`. Runs in REFACTOR.

## Checklist

### 1. Metadata — per page, not just root

- `<title>` 50–60 chars, primary keyword first, brand last. Unique per page.
- `description` 140–160 chars, a real sentence a human would click.
- `canonical` set and absolute. Pagination / filters / UTM variants point at the clean URL.
- Open Graph + Twitter card: `og:title`, `og:description`, `og:image` (1200×630, **a stable public URL, never a presigned or expiring one**), `og:url`, `twitter:card=summary_large_image`.
- **Next.js trap:** `metadata` merges per *field*, not deep. A page declaring only `openGraph` inherits the root layout's `twitter` block and shows the wrong card. Declare both or neither.

### 2. Crawlability

- `robots.txt` allows the public surface and disallows `/api`, auth, and internal routes. Points at the sitemap.
- `sitemap.xml` generated from the route source of truth, includes `lastmod`, excludes `noindex` pages.
- `noindex` on: auth pages, search-result pages with params, thin utility pages, preview/staging hosts (via header or env).
- Auth middleware does not 307 the crawler to `/login` for `.xml`, `.txt`, `/.well-known`, or OG image routes — exempt them explicitly.
- One H1 per page. Headings form a real outline (H2 → H3), not styled divs.
- Internal links are `<a href>` (or framework `<Link>`), not `onClick` navigation. Important pages are ≤3 clicks from home.

### 3. Structured data (AEO)

- JSON-LD on pages where a type fits: `Organization` + `WebSite` (root), `Product`/`SoftwareApplication` + `Offer` (pricing), `Article` (blog/docs), `FAQPage` (FAQ sections), `BreadcrumbList` (nested routes).
- Validate: paste into https://validator.schema.org or run `npx schema-dts` type-check if present. Zero errors.
- Answer-engine readiness: the first ~60 words under the H1 answer the page's question directly. FAQ sections use real question headings.

### 4. Core Web Vitals

- Images: framework image component (`next/image`), explicit `width`/`height` or `fill`, `priority` only on the LCP image, modern format (webp/avif), `sizes` set.
- Fonts: `next/font` or `font-display: swap`, subset, preloaded, ≤2 families.
- No layout shift from late-loading content: reserve space for ads, embeds, banners.
- Third-party scripts: `strategy="lazyOnload"` or `afterInteractive`, never render-blocking in `<head>`.
- Targets: LCP < 2.5 s, INP < 200 ms, CLS < 0.1. Verify with Lighthouse (`npx lighthouse <url> --only-categories=performance,seo --quiet`) when a local server is available.

### 5. Accessibility floor (also ranks)

- `lang` on `<html>`. `alt` on every content image (empty `alt=""` for decorative).
- Buttons are `<button>`, links are `<a>`. Focus visible. Colour contrast ≥ 4.5:1 body text.
- Forms: labels bound to inputs, errors announced.

### 6. i18n (if the site has locales)

- `hreflang` alternates per locale including `x-default`.
- Locale in the URL (`/en/`, `/de/`), not in a cookie only.

## Reporting

```
SEO gate — Task [N]: [page/route]

  ✓ title/description/canonical
  ✓ OG + Twitter declared together
  ✗ sitemap missing new route  → fixed in sitemap.ts
  ✓ JSON-LD: Article, validated
  ✓ LCP image priority, sizes set
```

Unfixable inside task boundaries → `.pm/ISSUES.md` as `Medium`, discipline `frontend`.

## PR Body Section

```markdown
## SEO
- Route(s): /pricing
- Metadata: title/desc/canonical/OG/Twitter ✓
- Sitemap/robots: updated ✓
- Structured data: Product + Offer ✓ (validated)
- CWV: LCP image priority ✓, no CLS sources
```
