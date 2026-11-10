---
description: Validate a component package against responsive-overlay.checks.md (C-RO-1 through C-RO-14). Verifies phone full-screen / tablet-anchored presentation, dvh sizing, positioning-yield, touch targets, safe-area insets, scroll containment, and docs. N/A for fully-inline components (no floating panel).
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the component at `$ARGUMENTS` against the
**responsive-overlay** guideline. Be exhaustive and concrete — file
paths and line numbers, not vague summaries. Read-only: do not edit any
files in the target.

## Step 0 — Applicability gate (D-RO-1)

This triad applies **only to components that open a floating panel /
overlay** (dropdown, calendar, autocomplete, menu, command palette). If
the component is fully inline — no opened panel, no open/close state, no
positioning engine — the entire triad is **N/A**: report every check as
N/A with the reason and stop. The `.checks.sh` script makes a best-effort
detection and skips when it finds no panel signals, but this is a
heuristic — confirm with C-RO-1 by reading the template / CSS.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\responsive-overlay.md`
   — the phone-vs-tablet model, the CSS pattern, the eight technical
   constraints (breakpoint literal, dvh, keyboard, safe-area,
   positioning-yield, dismissal, scroll lock, `<dialog>` top-layer), the
   anti-patterns.
2. `C:\Git\BlissFramework\guidelines\web-components\responsive-overlay.checks.md`
   — the 14 checks C-RO-1 through C-RO-14, with tier tags.
3. `C:\Git\BlissFramework\guidelines\web-components\responsive-overlay.decisions.md`
   — D-RO-1 (applicability) through D-RO-10 (container / scroll lock), so
   you know which non-defaults are legitimate.

## Step 2 — Locate the component

Use Glob / Grep to discover the layout under `$ARGUMENTS`:

- The CSS source folder (typically `src/css/`) — the panel rules, the
  `@media (max-width: …)` block, `dvh`/`vh` usage, `overscroll-behavior`,
  `env(safe-area-inset-*)`, touch-target `min-height`.
- `src/**` for the positioning engine (`matchMedia`, `computePosition`,
  `getBoundingClientRect`, inline `style.top`/`style.left`) and the panel
  template (close/Done control, Esc / `popstate` handlers).
- `docs/usage.md` for the responsive section + consumer viewport-meta
  notes.
- `CHANGELOG.md`.

Identify the component's **prefix** (from the manifest / variables.css /
README) and the **D-RO-5 mechanism** (CSS `!important` vs mode-aware
`matchMedia`) so you evaluate C-RO-5 against the right mechanism.

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for the two files that record
deviations the team has already accepted; a covering entry downgrades a
matching `❌ Fail` to `⚠️ Exception`.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only), one section per
  accepted deviation headed with the check ID(s), e.g.:

  ```markdown
  ## C-RO-4 — bare 100vw is intentional (decorative, not full-screen)
  The two `100vw` reads in floating.css:67-68 size a full-bleed
  divider, not the panel; the panel itself uses 100dvh. Not a clip risk.
  ```

An entry that explains *why the deviation is correct* downgrades the
verdict; a deferral ("fix later") stays a Fail. If neither file exists,
proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

```bash
bash C:/Git/BlissFramework/guidelines/web-components/responsive-overlay.checks.sh "$ARGUMENTS" <css-prefix>
```

The script runs the three `[auto]` checks (C-RO-2 breakpoint, C-RO-4
bare vh/vw, C-RO-8 overscroll-behavior) and performs the D-RO-1
heuristic gate. The css-prefix argument is optional (the auto checks are
prefix-independent). Capture the output verbatim. If the script fails to
run, fall back to the `.checks.md` prose for each `[auto]` check.

## Step 4 — Run the semi / manual checks (judgment path)

For the eleven checks the script doesn't cover:

- **C-RO-1** `[semi]` (applicability) — confirm the panel is real: a
  positioned opened-panel element with open/close state. If genuinely
  inline, N/A the whole triad.
- **C-RO-3** `[semi]` (full-screen geometry) — read the phone `@media`
  block; confirm `position: fixed` + `inset: 0` + `100dvh`/`100dvw` +
  border/radius/shadow reset.
- **C-RO-5** `[semi]` (positioning yields) — per D-RO-5: either
  `!important` on the full-screen geometry, or a `matchMedia('(max-width:
  <phone>)')` gate in the positioning JS with a `change` listener. For
  mode B, verify the `matchMedia` literal **equals** the CSS `@media`
  literal (C-RO-2) — a mismatch is anti-pattern #6.
- **C-RO-6** `[semi]` (explicit close) — a ✕/Done control renders in the
  full-screen chrome; Esc + hardware-back close. Backdrop-only is a fail.
- **C-RO-7** `[semi]` (touch targets) — rows and the close/Done button
  get `min-height` (and `min-width` for icon-only) ≥ 44px in the phone
  block, ideally via `--base-touch-target-min`.
- **C-RO-9** `[semi]` (safe-area insets) — full-screen chrome uses
  `max(<base>, env(safe-area-inset-*))`; N/A only if D-RO-9 = B is
  documented.
- **C-RO-12** `[semi]` (BEM + variables) — the mode is a prefixed BEM
  modifier / `data-*` attribute; the phone block touches geometry only
  (no `#hex`, no `--<prefix>-*` redeclarations). Reuse C-NC-8 / C-CSS-7 /
  C-BV-1 evidence if you've already gathered it.
- **C-RO-13** `[semi]` (docs) — `docs/usage.md` covers the phone
  behavior, the breakpoint, and the two consumer duties
  (`interactive-widget=resizes-content`, `viewport-fit=cover`).
- **C-RO-14** `[semi]` (CHANGELOG) — entry for the version landing the
  work, with the D-RO decision summary.
- **C-RO-10** `[manual]` (soft keyboard) — Always ⚠️ Manual. Give the
  steps: open panel in a mobile emulator/device, focus the search field,
  confirm the list scrolls and the close/Done control is reachable with
  the keyboard up, in both orientations.
- **C-RO-11** `[manual]` (visual smoke) — Always ⚠️ Manual. Give the
  steps: DevTools device toolbar at ≤ 600px (full-screen edge-to-edge),
  at 601–1024px (anchored, or D-RO-4 = B modal), at desktop (anchored),
  and drag across 600px to confirm a clean flip with no dead band.

If a check's bash snippet uses tools unavailable on Windows, use Read to
load the file and reason about it directly.

## Step 5 — Produce the report

Output to the conversation:

```
# Responsive-Overlay Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Applicability:** opens a panel / inline (N/A)
**D-RO-5 mechanism:** CSS !important / mode-aware matchMedia / not found
**Result:** N / 14 passing, M manual, K exceptions

## Auto checks (via responsive-overlay.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-RO-1 — Applicability gate
**Status:** ✅ / ❌ / N/A
**Evidence:** <panel class + positioning at file:line>

### C-RO-3 — Full-screen block uses fixed/inset + dvh/dvw
**Status:** …
**Evidence:** <phone @media block at file:line>

[... one block per remaining check ...]

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line verdict ("X failures, Y manual checks pending", or
"N/A — no floating panel").

## Discipline

- Never mark ✅ without actually running the verification.
- If Step 0 gates the package out (no floating panel), report every check
  N/A with the reason — don't invent failures.
- C-RO-10 and C-RO-11 are ⚠️ Manual (they need a device / emulator).
- A documented N/A per a decision (D-RO-9 = B, D-RO-10 = B) is N/A with
  citation, not a failure.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`. Run
  independent Grep/Read calls in parallel.
