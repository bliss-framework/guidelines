---
description: Full component validation (web-components and Svelte). Runs css-structure, theme-container, base-variables, and color-scheme checks and produces a consolidated report.
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are running the **full validation** for the component at
`$ARGUMENTS`. This is the umbrella command — it walks every applicable
`.checks.md` triad and consolidates the results into a single PR-ready
report. The component may be a web-component (`:host`) or a Svelte
component (`.<prefix>-container`); detect which up front and adapt the
checks accordingly.

Be exhaustive and concrete — file paths and line numbers, not vague
summaries. Read-only: do not edit any files in the target.

## Step 1 — Load every guideline (live, every run)

Read these in order:

1. `C:\Git\BlissFramework\guidelines\CLAUDE.md` — project-wide invariants.
2. `C:\Git\BlissFramework\guidelines\web-components\README.md` — index
   and the mandatory checklist section.
3. `C:\Git\BlissFramework\guidelines\web-components\css-structure.md`
   and `css-structure.checks.md`.
4. `C:\Git\BlissFramework\guidelines\web-components\theme-container.md`
   and `theme-container.checks.md`.
5. `C:\Git\BlissFramework\guidelines\web-components\base-variables.md`
   and `base-variables.checks.md`.
6. `C:\Git\BlissFramework\guidelines\web-components\color-scheme.md`
   and `color-scheme.checks.md`.
7. Each of the `.decisions.md` files — to know which check skips/N/As
   are legitimate.

Extract:

- The canonical `--base-*` taxonomy (for the alignment report).
- The reserved component prefixes (for verifying this component's
  prefix).
- The four canonical chain patterns (dropdown / tooltip / hover /
  active).

## Step 2 — Locate the component

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md`, `CHANGELOG.md` at the root.
- `component-variables.manifest.json` at the root.
- CSS source folder (typically `src/css/`).
- Test fixtures: `docs/test/dark-mode.html`, `e2e/dark-mode.spec.ts`,
  or similar.

Identify the component's **prefix** from manifest / variables.css /
README. Identify the **structure strategy** (canonical vs lean per
D-CSS-1) from the README — this gates several CSS-structure checks.

**Detect the component type** — web-component (custom element,
`:host` container) or Svelte (light DOM, `.<prefix>-container`). This
gates several theme-container checks (C-TC-9, C-TC-10 are Svelte-only;
the C-TC-1 `:host, :root` exception applies only to web-components).
Signals: `customElements.define(...)` and `attachShadow(...)` →
web-component; `.svelte` files and a `<prefix>-container` class in
a Svelte template → Svelte.

If the layout is unfamiliar, report what you found and proceed with
best-effort path mapping. Do not abort — most checks can still run.

## Step 3 — Run every check across all four topics

Run all 47 checks (12 CSS-structure + 14 theme-container + 12 base-
variables + 9 color-scheme), executing each "How to verify" adapted to
this component's actual paths. Follow the discipline laid out in each
individual validator command:

- `/validate-css-structure` notes for C-CSS-1 through C-CSS-12.
- `/validate-theme-container` notes for C-TC-1 through C-TC-14.
- `/validate-base-variables` notes for C-BV-1 through C-BV-12.
- `/validate-color-scheme` notes for C-CS-1 through C-CS-9.

Run **independent** Grep / Read calls in parallel — many checks
inspect the same files, so batch reads and reuse the content across
checks.

When two checks duplicate each other's evidence (C-BV-1 and C-CSS-8
both look for hardcoded colors in feature files), run the search once
and reuse the result for both.

## Step 4 — Cross-cutting invariants (from CLAUDE.md)

Beyond the 47 checks, verify the **Non-negotiable invariants** from
CLAUDE.md explicitly:

1. Components work standalone (covered by C-BV-10 / C-TC-13 — manual).
2. Components opt in to theme-designer (covered by C-BV-2 + C-BV-11).
3. **No JS-based theme detection** — Grep TS/JS for
   `matchMedia\(.*prefers-color-scheme`, `localStorage.*theme`, runtime
   color-scheme writes. Cross-cuts color-scheme.
4. **No `color-scheme` on the container** — overlaps C-CS-1 and C-TC-4.
5. One component → one prefix — overlaps C-BV-4.
6. Two layers of CSS variables on the container, never three; variables
   live on the container, never on `:root` — overlaps C-TC-1, C-BV-9.
   Grep for `--<prefix>-base-` (e.g., `--wp-base-`) and similar
   parallel-taxonomy patterns. Also Grep for `--<prefix>-*:` under
   `:root` / `html` / `body` selectors.
7. `@layer variables, component, overrides;` — overlaps C-CSS-3.
8. Every visible color via variable — overlaps C-BV-1 / C-CSS-8.
9. `light-dark()` for color fallbacks — overlaps C-CS-2.
10. BEM with component prefix — overlaps C-CSS-7.

Mark which invariants are violated; cross-reference the failing checks.

## Step 5 — Canonical taxonomy alignment

Beyond the checks, enumerate:

- Every `--base-*` the component consumes.
- Whether each appears in the canonical taxonomy table in
  `base-variables.md`.
- Canonical `--base-*` variables the component does *not* consume
  (informational).

Flag non-canonical reads for human review — they may indicate a new
variable that needs to be added to the taxonomy, or a typo.

## Step 6 — Produce the consolidated report

Output to the conversation:

```
# Component Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Component type:** web-component / Svelte / hybrid
**Prefix:** <wg / ms / drp / wp / ltree / sw / ...>
**Container selector:** :host / .<prefix>-container
**Strategy:** canonical / lean
**Date:** <today>

## Headline result

| Topic              | Pass | Fail | Manual | Exception | N/A |
|--------------------|------|------|--------|-----------|-----|
| CSS structure      |  /12 |      |        |           |     |
| Theme container    |  /14 |      |        |           |     |
| Base variables     |  /12 |      |        |           |     |
| Color scheme       |  / 9 |      |        |           |     |
| **Total**          |  /47 |      |        |           |     |

## Invariant violations (CLAUDE.md)
- <#N — what's violated, at which file:line>
- (or: "All 10 invariants honored.")

## CSS structure (C-CSS-1 → C-CSS-12)
### C-CSS-1 — ...
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception / N/A
**Findings:** ...
[...]

## Theme container (C-TC-1 → C-TC-14)
[...]

## Base variables (C-BV-1 → C-BV-12)
[...]

## Color scheme (C-CS-1 → C-CS-9)
[...]

## Canonical taxonomy alignment
### `--base-*` consumed
| Variable | In canonical? | Used in |
|----------|---------------|---------|
| ...      | ✅ / ⚠️        | ...     |

### Canonical `--base-*` NOT consumed (informational)
- <list>

## Manual verifications required
1. <step-by-step browser instructions>
2. <Playwright command to run>
3. <build + bundle-size command>

## Recommended actions (priority order)
1. <highest-impact failure: concrete file:line edit>
2. ...

## PR-ready summary checklist

Paste into the PR description, tick every box (or attach the per-check
status above):

```
CSS structure
[ ] C-CSS-1  ... [ ] C-CSS-7  ...
[ ] C-CSS-2  ... [ ] C-CSS-8  ...
[ ] C-CSS-3  ... [ ] C-CSS-9  ...
[ ] C-CSS-4  ... [ ] C-CSS-10 ...
[ ] C-CSS-5  ... [ ] C-CSS-11 ...
[ ] C-CSS-6  ... [ ] C-CSS-12 ...

Theme container
[ ] C-TC-1  ... [ ] C-TC-8  ...
[ ] C-TC-2  ... [ ] C-TC-9  ...
[ ] C-TC-3  ... [ ] C-TC-10 ...
[ ] C-TC-4  ... [ ] C-TC-11 ...
[ ] C-TC-5  ... [ ] C-TC-12 ...
[ ] C-TC-6  ... [ ] C-TC-13 ...
[ ] C-TC-7  ... [ ] C-TC-14 ...

Base variables
[ ] C-BV-1   ... [ ] C-BV-7  ...
[ ] C-BV-2   ... [ ] C-BV-8  ...
[ ] C-BV-3   ... [ ] C-BV-9  ...
[ ] C-BV-4   ... [ ] C-BV-10 ...
[ ] C-BV-5   ... [ ] C-BV-11 ...
[ ] C-BV-6   ... [ ] C-BV-12 ...

Color scheme
[ ] C-CS-1   ... [ ] C-CS-6 ...
[ ] C-CS-2   ... [ ] C-CS-7 ...
[ ] C-CS-3   ... [ ] C-CS-8 ...
[ ] C-CS-4   ... [ ] C-CS-9 ...
[ ] C-CS-5   ...
```
```

End with a single-sentence verdict ("X failures, Y manual checks
pending — see report above").

## Discipline

- Never mark ✅ without actually running the verification.
- A check that can't run (missing file, no tool) is ❌ with the reason.
- Browser / build checks are ⚠️ Manual with explicit steps.
- Documented exceptions in the component README count as ⚠️ Exception
  (quote the limitation), not failures.
- A check that's N/A because of a documented decision (lean strategy,
  underscore convention, etc.) gets N/A with citation.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`; prefer Glob
  over `Bash` + `ls`.
- Batch independent file reads in parallel — performance matters when
  scanning 33 checks against the same handful of files.
