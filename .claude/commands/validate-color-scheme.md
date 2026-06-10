---
description: Validate a web-component package against color-scheme.checks.md (C-CS-1 through C-CS-9).
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the web-component at `$ARGUMENTS` against the
**color-scheme** (dark-mode) guideline. Be exhaustive and concrete — file
paths and line numbers, not vague summaries. Read-only: do not edit any
files in the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\color-scheme.md` —
   rationale, the `:host`-color-scheme footgun, the `light-dark()` pattern,
   framework conventions (`data-theme`, `data-bs-theme`, `.dark`, `.light`),
   per-instance overrides.
2. `C:\Git\BlissFramework\guidelines\web-components\color-scheme.checks.md`
   — the 9 checks C-CS-1 through C-CS-9.
3. `C:\Git\BlissFramework\guidelines\web-components\color-scheme.decisions.md`
   — to understand what choices the component team should have made
   (especially D-CS-2 framework conventions and D-CS-5 contrast targets).
4. `C:\Git\BlissFramework\guidelines\CLAUDE.md` → Non-negotiable invariants
   #3 and #4 cover the dark-mode rules.

## Step 2 — Locate the component

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md`, `CHANGELOG.md` at the root.
- CSS source folder — typically `src/css/`. The dark-mode rules are usually
  in `dark-mode.css` (or `_dark-mode.css` for legacy projects). The
  `:host { color-scheme }` footgun could be anywhere — Grep all CSS.
- Test fixture for dark mode — typically `docs/test/dark-mode.html` or
  `e2e/dark-mode.spec.ts`. Adapt to the project's conventions.

If the layout is unfamiliar, report what you found and proceed with
best-effort path mapping.

## Step 3 — Run every check (C-CS-1 through C-CS-9)

For each check, execute the "How to verify" from `color-scheme.checks.md`
adapted to this component's actual paths. Notes:

- **C-CS-1** (no `:host { color-scheme }`): Grep `color-scheme` across all
  CSS. **Manually inspect each hit** — `color-scheme` is allowed inside
  `@media`, comments, or descendant rules, but NOT inside any `:host`
  block. This check is the #1 footgun and the #1 invariant in CLAUDE.md
  — be thorough.
- **C-CS-2** (`light-dark()` in color fallbacks): Grep
  `var\(--base-[a-z-]+,\s*#[0-9a-f]{3,6}\s*\)` in the variables file.
  Any match is a bare-color fallback that should be wrapped in
  `light-dark()`. A few exceptions exist (e.g., `--base-text-on-accent`
  which is `#ffffff` in both modes) — accept them if documented inline
  or in the README.
- **C-CS-3** (framework class selectors): confirm `:host-context()`
  selectors exist for every convention the component claims to support.
  If the component README says it supports Bootstrap, check for
  `:host-context([data-bs-theme="dark"])`. If it claims Tailwind/.dark,
  check `:host-context(.dark)`. Etc.
- **C-CS-4** (per-instance override): Grep for `:host([data-theme="dark"])`
  and `:host([data-theme="light"])`. Both must exist.
- **C-CS-5** (contrast test fixture): Glob for the test page (commonly
  `docs/test/dark-mode.html`, `examples/dark-mode/index.html`, or
  similar). Mark ⚠️ Manual if the fixture exists but you can't run it.
- **C-CS-6** (Playwright contrast assertions): Glob for
  `e2e/dark-mode.spec.ts` or equivalent. **Do not run Playwright** — just
  verify the spec exists and inspect its assertions. Mark the runtime
  pass/fail as ⚠️ Manual (the user runs the suite).
- **C-CS-7** (visual smoke in browser): Always ⚠️ Manual. List the
  browser-side things to verify (text readability, hover visibility,
  focus indicator, dropdown backgrounds, OS dark mode emulation,
  `body { color-scheme: dark }` removed but `data-theme` still works).
- **C-CS-8** (README documents theming contract): Read the component
  README. Look for sections covering: `--base-*` variables read (or
  manifest link), honored `data-theme` attributes (host + ancestors),
  honored framework class conventions, how OS preference is picked up,
  and any decisions documented in D-CS-1 through D-CS-6.
- **C-CS-9** (CHANGELOG entry): Read `CHANGELOG.md` head, look for
  Added/Changed entries describing the theming work concretely (not "fix
  dark mode").

## Step 4 — Cross-references

Check that the component honors **CLAUDE.md invariants #3 and #4**:

- Invariant #3: No JavaScript-based theme detection. Grep the component's
  TypeScript / JavaScript for `matchMedia\(.*prefers-color-scheme`,
  `localStorage.*theme`, runtime dark-mode toggling logic that writes
  styles. If any exists, it's a violation — flag it prominently.
- Invariant #4: No `:host { color-scheme: ... }` (overlaps C-CS-1).

## Step 5 — Produce the report

Output to the conversation:

```
# Color-Scheme Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Result:** N / 9 passing, M manual, K exceptions

## Check results

### C-CS-1 — no :host { color-scheme: ... }
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception
**Evidence:** <commands run, files inspected>
**Findings:**
- <file:line> — <what was found>

[repeat for all 9]

## Invariant cross-check
- JS-based theme detection: ✅ none / ❌ found at <file:line>
- :host color-scheme: ✅ clean / ❌ at <file:line>

## Manual verifications required (run these in browser)
1. C-CS-7 — visual smoke in dev server. Steps: …
2. C-CS-6 — `npx playwright test e2e/dark-mode.spec.ts`

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line summary the user can scan at a glance.

## Discipline

- Never mark ✅ without actually running the verification.
- Browser checks are always ⚠️ Manual with explicit steps.
- A documented exception in the component README counts as ⚠️ Exception
  (quote it), not a failure.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`.
- Run independent Grep/Read calls in parallel.
