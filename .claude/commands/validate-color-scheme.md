---
description: Validate a web-component package against color-scheme.checks.md (C-CS-1 through C-CS-10).
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
   — the 10 checks C-CS-1 through C-CS-10.
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

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record
deviations the team has already accepted. Their content downgrades
matching `❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the
note) and removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):
  ```markdown
  ## C-CS-10 — Tooltip portaled to document.body in standalone path
  The standalone JS-class path (consumers using `new DateRangePicker(...)`
  without setting `container`) intentionally portals the tooltip to
  `document.body`. The web-component path passes the shadow root, so
  Kind A applies there. Documented in docs/theming.md.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority") stays a Fail. See `/validate-web-component` Step 2.5 for
the full contract.

If neither file exists, proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/color-scheme.checks.sh "$ARGUMENTS"
```

The script runs C-CS-2 and C-CS-5 — the two `[auto]` checks — plus the
auto-checkable portion of C-CS-10 (hardcoded colors in a dedicated
tooltip CSS file). Capture its output verbatim.

Notes on script behavior:

- **C-CS-2** exempts the documented exception names —
  `--base-accent-color*`, `--base-text-color-on-accent`,
  `--base-color-on-accent`, `--base-text-on-accent` — that are
  legitimately the same in both modes. This matches the rule's
  "intentional exceptions OK if documented" wording.
- **C-CS-10 (partial)** only inspects files matching `*tooltip*.css`
  in the CSS folder (excluding `variables.css` and `dark-mode.css`,
  which are allowed to hold color literals). A SKIP from this sub-
  check means no dedicated tooltip CSS file exists — the full
  [semi] check still needs to run in Step 4.

If the script fails to run, fall back to the `.checks.md` prose for
each `[auto]` check.

## Step 4 — Run the semi / manual checks (judgment path)

For the eight checks the script doesn't fully cover:

- **C-CS-1** `[semi]` (no *bare* `:host { color-scheme: ... }`) — Grep
  `color-scheme` across all CSS. Classify each match per the verdict
  table in `color-scheme.checks.md`:
  - Bare `:host { color-scheme: ... }` → ❌
  - Conditional `:host([attr]) { color-scheme: ... }` /
    `:host-context(...) { color-scheme: ... }` → ✅
  - Inside `@media` / comment → ✅
  This check is the #1 footgun (CLAUDE.md invariant #4). Be
  thorough.
- **C-CS-3** `[semi]` (framework class selectors) — confirm
  `:host-context()` selectors exist for every convention the
  component's D-CS-2 commits to (`data-theme`, `data-bs-theme`,
  `.dark` / `.light`, …). If the component claims Bootstrap support,
  check `:host-context([data-bs-theme="dark"])`. Etc.
- **C-CS-4** `[manual]` (per-instance override works) — browser-
  required. Mark ⚠️ Manual with the exact HTML fixture from
  `color-scheme.checks.md`.
- **C-CS-6** `[semi]` (Playwright contrast assertions) — `ls
  e2e/dark-mode.spec.ts` confirms existence; running `npx playwright
  test e2e/dark-mode.spec.ts` confirms passes. Don't run it yourself;
  mark ⚠️ Manual with the command.
- **C-CS-7** `[manual]` (visual smoke in browser) — Always ⚠️ Manual.
  List the browser-side things to verify (text readability, hover,
  focus indicator, dropdown backgrounds, OS dark mode emulation, etc.).
- **C-CS-8** `[manual]` (README documents theming contract) — Read
  the component README. Confirm coverage of: `--base-*` variables
  read, honored `data-theme` attributes, honored framework class
  conventions, OS preference, D-CS-1..D-CS-6 deviations.
- **C-CS-9** `[semi]` (CHANGELOG entry) — Read `CHANGELOG.md`, look
  for entries describing the theming work concretely (not "fix dark
  mode" / "improve theming").
- **C-CS-10** `[semi]` (tooltips render correct contrast in dark
  mode) — the script's auto sub-check catches hardcoded colors in
  dedicated tooltip CSS files; the [semi] portion verifies theme
  propagation for each tooltip kind.

  **Classification discipline — trace the actual call site, not the
  constructor default.** The Tooltip class commonly defaults to
  `document.body` (`opts.container ?? document.body`), and the Logic
  class often forwards `this.options.container || document.body` to
  it — but in the web-component path the Element class typically
  passes the shadow root as `container` (e.g. web-multiselect's
  `web-component.ts:639` and web-daterangepicker's
  `web-component.ts:474` both use
  `container: this.shadow as unknown as HTMLElement`). Reading just
  the constructor / Logic-class fallback and concluding Kind B is a
  false positive for those components.

  For each `new Tooltip(...)` / `appendChild(tooltipEl)` site, walk
  the chain back: Logic-class options.container ← Element-class
  options arg. If the Element class hands in the shadow root, the
  tooltip lives in shadow scope (Kind A) — the `document.body` line
  in the Logic class is dead code for the web-component path. Don't
  propose a patch that uses `target.getRootNode().host` as the
  container either — `.host` is the host element in light DOM,
  outside its own shadow root, so that would *demote* a Kind-A
  tooltip into a Kind-B portal.

  - **Kind A — in-shadow-DOM / in-container custom tooltip.** Grep
    `src/css/` for the tooltip className the constructor sets
    (e.g. `.ms__badge-tooltip`, `.drp__tooltip`) and walk the
    variable chain back to a `light-dark()` literal. Pass if every
    background / color / border resolves through
    `var(--<prefix>-tooltip-*, var(--base-tooltip-*, light-dark(...)))`.
  - **Kind B — tooltip genuinely portaled to `document.body` /
    `<dialog>` / Popover API.** Only conclude Kind B after the
    call-site trace above confirms no shadow-root container is
    passed at the Element-class boundary. If confirmed, verify ONE
    of three propagation mechanisms is in place:
    1. `data-theme` mirrored from container onto the portal root at
       open time, with matching `[data-theme="dark"]` /
       `[data-theme="light"]` selectors in the tooltip CSS.
    2. Tooltip CSS reads `--base-tooltip-*` directly, with the
       limitation documented in `docs/theming.md`.
    3. Portal element has its own conditional `color-scheme: dark`
       block parallel to the host's signal selectors.
  - **Kind C — browser-native `title=""` tooltips.** Pass if C-CS-1
    is green and no JS rewrites `title` attributes; otherwise N/A.
  - **Kind A+B hybrid** — the component supports both web-component
    usage (shadow-root container, Kind A) and standalone JS-class
    instantiation (`document.body` fallback, Kind B). Document the
    duality: Kind A path is verified by the variable chain, Kind B
    path needs one of the three propagation mechanisms above OR a
    note in the README that the standalone path requires the
    consumer to pass an explicit container.
  - If the component has zero tooltips (no matches from the grep
    above), mark N/A with the grep output as evidence.
  - This is the check that catches the web-grid bug: dark-themed
    container, portaled tooltip with hardcoded `color: #...` literal,
    unreadable in dark mode.

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
**Result:** N / 10 passing, M manual, K exceptions

## Auto checks (via color-scheme.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-CS-1 — No bare :host { color-scheme: ... } (conditional ok)
**Status:** ✅ / ❌ / ⚠️ Exception
**Evidence:** <files inspected>
**Findings:** <what was found>

### C-CS-3 — Framework class selectors present
…

### C-CS-4 — Per-instance override (browser)
…

### C-CS-6 — Playwright contrast assertions
…

### C-CS-7 — Visual smoke (browser)
…

### C-CS-8 — README documents theming contract
…

### C-CS-9 — CHANGELOG entry
…

### C-CS-10 — Tooltips render correct contrast in dark mode
**Status:** ✅ / ❌ / ⚠️ Manual / N/A
**Tooltip kinds detected:** A (in-shadow) / B (portal) / C (native) / none
**Evidence:** <file:line of each tooltip code path>
**Findings:** <per-kind verdict and propagation mechanism>

## Invariant cross-check
- JS-based theme detection: ✅ none / ❌ found at <file:line>
- :host color-scheme: ✅ clean / ❌ at <file:line>

## Manual verifications required (run these in browser)
1. C-CS-7 — visual smoke in dev server. Steps: …
2. C-CS-6 — `npx playwright test e2e/dark-mode.spec.ts`
3. C-CS-4 — per-instance override fixture

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
