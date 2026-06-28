---
description: Full component validation (web-components and Svelte). Runs all seven triads — component-structure, naming-conventions, css-structure, theme-container, base-variables, color-scheme, readme-structure. Invokes the .checks.sh scripts for [auto] checks then judges [semi]/[manual]. Produces a consolidated report in chat AND writes a punch-list file (validation_<timestamp>.md) to the target component folder.
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash, Write
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
2. `C:\Git\BlissFramework\guidelines\web-components\README.md` — index,
   the check-tier explanation, the mandatory checklist section.
3. `C:\Git\BlissFramework\guidelines\web-components\component-structure.md`
   and `component-structure.checks.md`.
4. `C:\Git\BlissFramework\guidelines\web-components\naming-conventions.md`
   and `naming-conventions.checks.md`.
5. `C:\Git\BlissFramework\guidelines\web-components\css-structure.md`
   and `css-structure.checks.md`.
6. `C:\Git\BlissFramework\guidelines\web-components\theme-container.md`
   and `theme-container.checks.md`.
7. `C:\Git\BlissFramework\guidelines\web-components\base-variables.md`
   and `base-variables.checks.md`.
8. `C:\Git\BlissFramework\guidelines\web-components\color-scheme.md`
   and `color-scheme.checks.md`.
9. `C:\Git\BlissFramework\guidelines\web-components\readme-structure.md`
   and `readme-structure.checks.md`.
10. Each of the `.decisions.md` files — to know which check skips/N/As
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

## Step 2.5 — Load accepted-deviation registers

Before evaluating any `[semi]` / `[manual]` check or composing the
report, load two files at the package root that record deviations the
team has already accepted. A check whose flag is covered by an entry
in either register is downgraded from `❌ Fail` to `⚠️ Exception` (or
`✅ Pass` per the note) and is **omitted from the punch-list's "Fixes
to apply" section** so it doesn't re-surface every run.

The two registers serve different audiences:

1. **`README.md` → `## Known limitations`** — *consumer-facing*
   exceptions. Things consumers should know about ("we ship default
   styles for `.holiday` / `.event` as hooks for consumer-data-driven
   day classes"; "no FOUC prevention rule because the component is
   inline-style"). Grep:

   ```bash
   grep -nE "^## (Known limitations|Known Limitations)" "$ARGUMENTS/README.md"
   ```

   If present, read the section. When a check fires against a class,
   pattern, or behavior the limitation explicitly covers, downgrade
   the verdict and quote the limitation in the per-check status line.

2. **`VALIDATION-NOTES.md`** at the package root — *internal /
   technical* exceptions that don't belong in a consumer-facing
   README. Examples: "C-BV-9 false-positive because we use Strategy A
   for dark mode"; "C-CST-4 because the Logic class is split across
   namespace-style collaborators". Glob:

   ```bash
   ls "$ARGUMENTS/VALIDATION-NOTES.md" 2>&1
   ```

   If present, read the entire file. The convention is one section
   per accepted deviation, headed with the affected check ID(s) and a
   short title:

   ```markdown
   # Validation notes — accepted deviations

   ## C-BV-9 — Strategy A signal-override pattern
   21 `var(--base-*)` reads in `src/css/dark-mode.css:25-60` are
   variable redeclarations inside `:host-context(...)` / `:host(...)`
   selectors — the canonical Strategy A pattern documented in
   `color-scheme.md`. Not feature-rule reads. PASS with note;
   the C-BV-9 auto-script is too strict for Strategy A components.

   ## C-CST-4 / C-CST-10 — Logic-class module split
   `DateRangePicker` is split across `date-picker.ts` + 7
   namespace-style collaborators (`date-picker-{validation, …}.ts`)
   imported via `import * as Foo`. Not independent Service classes;
   one Logic class organized across files. The main class delegates
   through wrapper methods (`startDrag(...) { return Interaction.startDrag(this, ...); }`).
   ```

   When an auto-script flag's check ID matches a heading in
   `VALIDATION-NOTES.md`:

   - Downgrade `❌ Fail` → `✅ Pass` (with a "see VALIDATION-NOTES.md"
     citation) or `⚠️ Exception` (whichever fits the note's framing).
   - Do **not** include the flagged item in the punch-list's
     "Fixes to apply" section.
   - Cite the note in the chat report's per-check status line so a
     reader can find the rationale without re-deriving it.

If neither file exists, proceed at face value: every auto-script flag
is treated as a genuine finding. This is the default.

### Discipline — accepted reason, not lazy silencing

The registers are for deviations the team has reasoned through and
accepted as the right answer for this component. Not a holding pen
for deferred work.

A valid entry explains *why the deviation is the correct outcome*:
"Strategy A is documented in color-scheme.md and we're using it on
purpose"; "the consumer-data class convention is the contract — we
ship default styling for the common conventions consumers use".

An invalid entry defers without a reason: "we'll fix this later",
"low priority", "out of scope for this release". When you encounter
one of those, treat the underlying check as a regular `❌ Fail` and
include it in the punch-list with the deferral note quoted under the
fix — the team made a promise, not an architectural decision.

**Keep a running list of every deferral entry you encountered while
walking `VALIDATION-NOTES.md`** (check ID + one-line title from the
heading + file:line of the deferral note). Step 9b surfaces this list
to the user so they can decide whether to tackle any in this round.

When in doubt, prefer to surface a Fail and let the reader decide.
False positives in the punch-list are recoverable; silently
suppressing a real bug because an entry "looked plausible" is not.

## Step 3 — Run the `[auto]` checks via the seven `.checks.sh` scripts

Each triad ships a runnable bash script that mechanically executes its
`[auto]` checks. Run all seven in sequence first — this knocks out
roughly half the work in a few seconds with deterministic verdicts.
Capture each script's output verbatim for the report.

```bash
# Capture each script's stdout for the report (don't fail-fast — collect all)
bash C:/Git/BlissFramework/guidelines/web-components/component-structure.checks.sh "$ARGUMENTS"
bash C:/Git/BlissFramework/guidelines/web-components/naming-conventions.checks.sh   "$ARGUMENTS" <css-prefix>
bash C:/Git/BlissFramework/guidelines/web-components/css-structure.checks.sh         "$ARGUMENTS" <css-prefix>
bash C:/Git/BlissFramework/guidelines/web-components/theme-container.checks.sh       "$ARGUMENTS" <css-prefix>
bash C:/Git/BlissFramework/guidelines/web-components/base-variables.checks.sh        "$ARGUMENTS" <css-prefix>
bash C:/Git/BlissFramework/guidelines/web-components/color-scheme.checks.sh          "$ARGUMENTS"
bash C:/Git/BlissFramework/guidelines/web-components/readme-structure.checks.sh      "$ARGUMENTS"
```

The CSS prefix can be omitted from the calls that accept it if
`component-variables.manifest.json` declares it (each script auto-
discovers). If a script fails to run, note the failure and fall back
to the `.checks.md` prose for that triad's `[auto]` checks.

Across all seven scripts, the `[auto]` tier covers **43 of the 89
checks** (see `web-components/README.md` → "Check tiers"):

| Triad | Auto checks the script runs |
|-------|-----------------------------|
| component-structure | C-CST-1, 2, 3, 4, 5, 8, 11 |
| naming-conventions | C-NC-1, 2, 3, 6, 8, 9, 11 |
| css-structure | C-CSS-1, 2, 3, 4, 5, 6, 7, 8, 11 |
| theme-container | C-TC-1, 3, 5, 7, 15 |
| base-variables | C-BV-1, 2, 3, 5, 6, 9 |
| color-scheme | C-CS-2, 5, plus C-CS-10 (partial — hardcoded colors in dedicated tooltip CSS files only) |
| readme-structure | C-RS-1, 2, 3, 4, 5, 14, 15 |

## Step 4 — Run the `[semi]` and `[manual]` checks (judgment path)

For the remaining 46 checks (31 `[semi]`, 15 `[manual]`), execute the
"How to verify" prose from each `.checks.md`, following the discipline
in the matching individual validator command:

- `/validate-component-structure` notes for the four C-CST `[semi]` /
  `[manual]` checks.
- `/validate-naming-conventions` notes for the five C-NC `[semi]` /
  `[manual]` checks.
- `/validate-css-structure` notes for the three C-CSS `[semi]` /
  `[manual]` checks.
- `/validate-theme-container` notes for the ten C-TC `[semi]` /
  `[manual]` checks.
- `/validate-base-variables` notes for the eight C-BV `[semi]` /
  `[manual]` checks (including C-BV-13 input-size canonicalization
  and C-BV-14 tooltip-geometry canonicalization).
- `/validate-color-scheme` notes for the eight C-CS `[semi]` /
  `[manual]` checks (includes C-CS-10 tooltip verification —
  classify each tooltip code path as in-shadow / portal / native and
  verify the matching theme-propagation mechanism).
- `/validate-readme-structure` notes for the eight C-RS `[semi]` /
  `[manual]` checks.

Run **independent** Grep / Read calls in parallel — many checks
inspect the same files, so batch reads and reuse the content across
checks.

When two checks duplicate each other's evidence (C-BV-1 and C-CSS-8
both look for hardcoded colors in feature files; C-CST-8 and C-NC-11
both check TS interface suffixes), run the search once and reuse the
result for both.

## Step 5 — Cross-cutting invariants (from CLAUDE.md)

Beyond the 89 checks, verify the **Non-negotiable invariants** from
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

## Step 6 — Canonical taxonomy alignment

Beyond the checks, enumerate:

- Every `--base-*` the component consumes.
- Whether each appears in the canonical taxonomy table in
  `base-variables.md`.
- Canonical `--base-*` variables the component does *not* consume
  (informational).

Flag non-canonical reads for human review — they may indicate a new
variable that needs to be added to the taxonomy, or a typo.

## Step 7 — Produce the consolidated report

Output to the conversation:

```
# Component Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Component type:** web-component / Svelte / hybrid
**Prefix:** <wg / ms / drp / wp / wtv / stv / sw / ...>
**Container selector:** :host / .<prefix>__container
**Strategy:** canonical / lean
**Date:** <today>

## Headline result

| Topic                | Pass | Fail | Manual | Exception | N/A |
|----------------------|-----:|-----:|-------:|----------:|----:|
| Component structure  |  /11 |      |        |           |     |
| Naming conventions   |  /12 |      |        |           |     |
| CSS structure        |  /12 |      |        |           |     |
| Theme container      |  /15 |      |        |           |     |
| Base variables       |  /14 |      |        |           |     |
| Color scheme         |  /10 |      |        |           |     |
| Readme structure     |  /15 |      |        |           |     |
| **Total**            |  /89 |      |        |           |     |

## Auto-check script outputs

### component-structure.checks.sh
<paste verbatim>

### naming-conventions.checks.sh
<paste verbatim>

### css-structure.checks.sh
<paste verbatim>

### theme-container.checks.sh
<paste verbatim>

### base-variables.checks.sh
<paste verbatim>

### color-scheme.checks.sh
<paste verbatim>

### readme-structure.checks.sh
<paste verbatim>

## Invariant violations (CLAUDE.md)
- <#N — what's violated, at which file:line>
- (or: "All 10 invariants honored.")

## Component structure (C-CST-1 → C-CST-11) — semi/manual checks
### C-CST-6 — Element layer holds no business state
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception / N/A
**Findings:** ...
[...]

## Naming conventions (C-NC-1 → C-NC-12) — semi/manual checks
[...]

## CSS structure (C-CSS-1 → C-CSS-12) — semi/manual checks
[...]

## Theme container (C-TC-1 → C-TC-15) — semi/manual checks
[...]

## Base variables (C-BV-1 → C-BV-14) — semi/manual checks
[...]

## Color scheme (C-CS-1 → C-CS-10) — semi/manual checks
[...]

## Readme structure (C-RS-1 → C-RS-15) — semi/manual checks
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

## Required actions (priority order)

Every `❌ Fail` above and every `⚠️ Exception` that is *not* already
covered by an entry in `VALIDATION-NOTES.md` or the README's
`## Known limitations` section (per Step 2.5) maps to exactly one
concrete edit below. Items already covered by an accepted-deviation
register are **omitted** — they're settled architectural choices, not
pending fixes.

Do not list speculative improvements, "nice to haves", or
guideline-change proposals — those belong in the "Notes for the
guidelines maintainer" tail at the very end of this report, not
here.

1. <highest-impact failure: concrete file:line edit>
2. ...

## Notes for the guidelines maintainer (often empty — that's fine)

Only fill this section if you noticed a real ambiguity in the
guidelines themselves while validating *this* component — a rule
that was hard to apply, a check that produced a false positive, or
a missing decision that left you guessing. Each note must cite the
specific evidence in *this* component that triggered it (file:line
or check ID), so the maintainer can reproduce.

This section is **not** a holding pen for unrelated suggestions or
general improvements. If you can't tie the note to something you
observed in this component, drop it. Default state: "None." — and
that is the correct answer for most runs.

## PR-ready summary checklist

Paste into the PR description, tick every box (or attach the per-check
status above):

```
Component structure
[ ] C-CST-1  [auto]   Element class with Element suffix      (N/A Svelte)
[ ] C-CST-2  [auto]   Tag agrees with customElements.define  (N/A Svelte)
[ ] C-CST-3  [auto]   Logic class is framework-agnostic
[ ] C-CST-4  [auto]   Service classes don't import each other
[ ] C-CST-5  [auto]   Side-layer has no upward imports
[ ] C-CST-6  [manual] Element layer holds no business state
[ ] C-CST-7  [semi]   No premature Manager
[ ] C-CST-8  [auto]   TS interface suffixes match closed set
[ ] C-CST-9  [manual] No premature interfaces
[ ] C-CST-10 [semi]   Folder layout matches convention
[ ] C-CST-11 [auto]   Logic-class framework imports respect D-CST-9

Naming conventions
[ ] C-NC-1  [auto]   custom-element tag hyphenated + prefixed     (N/A Svelte)
[ ] C-NC-2  [auto]   CustomEvent names bare and short              (N/A Svelte)
[ ] C-NC-3  [auto]   boolean Config/Props fields use is*/should*/has*/can*
[ ] C-NC-4  [semi]   events use on* / callbacks use *Callback (return-value test)
[ ] C-NC-5  [semi]   interceptors use before*Callback
[ ] C-NC-6  [auto]   data extractors use get*Callback + *Member pair
[ ] C-NC-7  [semi]   ATTRIBUTE_TABLE single source of truth        (N/A Svelte)
[ ] C-NC-8  [auto]   CSS classes are <prefix>__element--modifier (BEM)
[ ] C-NC-9  [auto]   internal: handle* methods, *Handler stored refs
[ ] C-NC-10 [manual] validate* vs check* used per their semantics
[ ] C-NC-11 [auto]   TS interface suffixes from closed set
[ ] C-NC-12 [semi]   no magic strings inline

CSS structure
[ ] C-CSS-1  [auto]   canonical file set present
[ ] C-CSS-2  [auto]   no underscore-prefixed file names
[ ] C-CSS-3  [auto]   @layer declared and used
[ ] C-CSS-4  [auto]   empty file stub comment present
[ ] C-CSS-5  [auto]   every file imported by main.css
[ ] C-CSS-6  [auto]   section banners on files > 100 lines
[ ] C-CSS-7  [auto]   BEM convention followed
[ ] C-CSS-8  [auto]   no hardcoded colors in feature files
[ ] C-CSS-9  [manual] no mixed-bag files
[ ] C-CSS-10 [semi]   layer contract documented in README
[ ] C-CSS-11 [auto]   main.css has no rules
[ ] C-CSS-12 [semi]   bundle size sanity check

Theme container
[ ] C-TC-1  [auto]   no --<prefix>-* on :root / html / body
[ ] C-TC-2  [semi]   container paints default background
[ ] C-TC-3  [auto]   --<prefix>-bg chains through --base-main-bg with light-dark()
[ ] C-TC-4  [semi]   no bare color-scheme on container (conditional ok)
[ ] C-TC-5  [auto]   per-instance data-theme dark AND light selectors exist
[ ] C-TC-6  [semi]   dark/light overrides target the container
[ ] C-TC-7  [auto]   display: block (or documented exception)
[ ] C-TC-8  [semi]   position: relative on container (or fixed-floating exception)
[ ] C-TC-9  [semi]   single root container
[ ] C-TC-10 [semi]   Svelte: theme prop forwards to data-theme (N/A web-components)
[ ] C-TC-11 [manual] docs/theming.md documents the container contract
[ ] C-TC-12 [manual] subtree theming smoke test passed
[ ] C-TC-13 [manual] standalone render works
[ ] C-TC-14 [manual] per-instance override works in browser
[ ] C-TC-15 [auto]   FOUC rule tag matches customElements.define (web-component; N/A Svelte / D-TC-9 = B)

Base variables
[ ] C-BV-1  [auto]   every visible color resolves through a variable
[ ] C-BV-2  [auto]   every var(--base-*) read has a fallback
[ ] C-BV-3  [auto]   :host declares every component-local variable
[ ] C-BV-4  [semi]   component prefix is unique and reserved
[ ] C-BV-5  [auto]   manifest exists and is exported
[ ] C-BV-6  [auto]   manifest entries match the code
[ ] C-BV-7  [semi]   fallback chains match canonical patterns
[ ] C-BV-8  [manual] docs/theming.md documents the variable contract
[ ] C-BV-9  [auto]   no --base-* reads outside :host
[ ] C-BV-10 [manual] standalone render works
[ ] C-BV-11 [manual] theme override works end-to-end
[ ] C-BV-12 [semi]   CHANGELOG entry
[ ] C-BV-13 [semi]   input controls consume --base-input-size-*-height
[ ] C-BV-14 [semi]   tooltip geometry consumes canonical --base-tooltip-* scale

Color scheme
[ ] C-CS-1  [semi]   no bare :host { color-scheme: ... } (conditional ok)
[ ] C-CS-2  [auto]   light-dark() in color fallbacks
[ ] C-CS-3  [semi]   framework class selectors present (for chosen conventions)
[ ] C-CS-4  [manual] per-instance override works
[ ] C-CS-5  [auto]   contrast test fixture exists
[ ] C-CS-6  [semi]   Playwright contrast assertions pass
[ ] C-CS-7  [manual] visual smoke test passed
[ ] C-CS-8  [manual] docs/theming.md documents the color-scheme contract
[ ] C-CS-9  [semi]   CHANGELOG entry
[ ] C-CS-10 [semi]   tooltips render correct contrast in dark mode (in-shadow / portal / native)

Readme structure
[ ] C-RS-1  [auto]   README.md exists at package root
[ ] C-RS-2  [auto]   README.md ≤ 400 lines (target 200)
[ ] C-RS-3  [auto]   docs/ folder has usage / theming / examples / accessibility (last per D-RS-2)
[ ] C-RS-4  [auto]   README links every docs/ file at least once (relative path)
[ ] C-RS-5  [auto]   README has canonical section headings (What is it / Install / Quick start / License)
[ ] C-RS-6  [semi]   README "What is it" is tight (≤ 30 lines, 1–3 paragraphs)
[ ] C-RS-7  [semi]   README "What's new" links CHANGELOG.md (or D-RS-5 = C)
[ ] C-RS-8  [semi]   Deployed demo link present and returns 200 (or D-RS-1 = D)
[ ] C-RS-9  [manual] Quick-start snippet actually runs in a clean install
[ ] C-RS-10 [semi]   docs/usage.md covers full public surface (attributes, events, slots, methods)
[ ] C-RS-11 [semi]   docs/theming.md covers container + variable + color-scheme + layer contracts
[ ] C-RS-12 [semi]   docs/examples.md has at least one worked example beyond the README quick start
[ ] C-RS-13 [semi]   docs/accessibility.md covers keyboard + ARIA + focus (N/A if D-RS-2 = B)
[ ] C-RS-14 [auto]   README acknowledges BlissFramework guidelines + links to blissframework.dev
[ ] C-RS-15 [auto]   README has canonical ## About paragraph (KeenMate + Pure Admin + standalone + --base-*)
```
```

End with a single-sentence verdict ("X failures, Y manual checks
pending — see report above").

## Step 8 — Write the punch-list file to the target

In addition to the chat report from Step 6, write a focused
**punch-list file** to the target component folder so the fix
instructions live alongside the component code (where the developer
who'll actually do the work will see them).

### Compute the timestamp

Use `Bash` to compute a filesystem-safe sortable timestamp string:

```bash
date +%Y-%m-%d_%H%M
```

The output (e.g. `2026-06-14_1452`) becomes the filename suffix.

### Write the file

Use `Write` to create `$ARGUMENTS/validation_<timestamp>.md`. Keep it
**concise and action-oriented** — the full per-check report lives in
the chat transcript that just generated it; this file is the
punch-list, not a duplicate. Structure:

```markdown
# Validation — <component name>

**Date:** <YYYY-MM-DD HH:MM from the timestamp>
**Package:** <name@version from package.json>
**Component type:** web-component / Svelte
**Validator:** `/validate-web-component` (BlissFramework guidelines)

## About this report

This punch-list is a **snapshot of what the validator found**. Some
entries in "Fixes to apply" below may turn out to be **false
positives** — patterns the guidelines flag in general but that are
correct for *this* component (e.g. Strategy A signal-overrides,
namespace-style logic-class splits, intentional consumer-data class
hooks). The register for those is **`VALIDATION-NOTES.md`** at the
package root: each entry there is keyed by the affected check ID(s)
and explains *why the deviation is correct*. Next time validation
runs, any flag covered by a matching entry is downgraded from
❌ Fail to ✅ Pass / ⚠️ Exception and **omitted from this section**
— so it doesn't re-surface every run.

Before treating an entry below as a developer task:

1. Read the patch — does the fix actually apply to *this* component?
2. If yes → do the fix.
3. If no (the validator misjudged it) → add an entry to
   `VALIDATION-NOTES.md` keyed by the check ID, explaining why the
   deviation is the correct answer here. The validator that
   generated this file should have offered to do this interactively
   at the end of its run (Step 9a); if you're acting on the file
   after the fact, append the entry by hand.

Deferrals ("we'll fix this later", "low priority", "out of scope")
are **NOT valid `VALIDATION-NOTES.md` entries** — they get
re-promoted to Fails on every subsequent run by design. Only
architectural decisions belong in the register. If a deferral is
the right call, capture it as a TODO / issue in your tracker, not
in `VALIDATION-NOTES.md`.

## Result at a glance

| Topic                | Pass | Fail | Manual | Exception | N/A |
|----------------------|-----:|-----:|-------:|----------:|----:|
| Component structure  |   /11 |      |        |           |     |
| Naming conventions   |   /12 |      |        |           |     |
| CSS structure        |   /12 |      |        |           |     |
| Theme container      |   /15 |      |        |           |     |
| Base variables       |   /14 |      |        |           |     |
| Color scheme         |   /10 |      |        |           |     |
| Readme structure     |   /15 |      |        |           |     |
| **Total**            |   /89 |      |        |           |     |

## Fixes to apply

Every entry in this section is a **definitive action a developer
must take, grounded in something the validator observed in *this*
component's code and NOT already accepted in the deviation registers
(`VALIDATION-NOTES.md` / README `## Known limitations` — see Step 2.5
of `/validate-web-component` for the contract).** There are exactly
two kinds of qualifying items:

1. **❌ Fail** — the check fired against this component's code AND
   no accepted-deviation entry covers it. The fix is whatever brings
   *this* component back into conformance.
2. **⚠️ Exception that is not yet documented** — *this* component
   legitimately deviates from the rule (the deviation is visible in
   the code) but neither `VALIDATION-NOTES.md` nor the README's
   "Known limitations" section acknowledges it. The fix is to add
   the documentation, with the exact paragraph included in the
   patch. Choose the register by audience: consumer-facing (the
   deviation changes how a consumer integrates the component) →
   README; internal-only (validation quirk the consumer doesn't
   care about) → `VALIDATION-NOTES.md`.

The discriminator is **applicability to this specific component**.
A pattern that doesn't apply — for instance, the wrapper-host
documentation doesn't apply to a component where `:host` paints its
own background; the unlayered-reset footgun warning doesn't apply
unless the component's cascade is actually at risk — must not be
listed as a fix. "Optional" here means "not applicable to this
component's scenario", not "nice to have".

Do **not** include:
- Items already covered by an entry in `VALIDATION-NOTES.md` or the
  README's `## Known limitations`. Those are settled, not pending.
- Generic warnings or patterns that aren't observable in *this*
  component's code (e.g. "consumers might use a universal reset" —
  unless this component's README already discusses cascade layering,
  there is no specific gap to document).
- "Nice to have" suggestions, polish ideas, or refactoring proposals
  the validator didn't explicitly flag against *this* code.
- Documentation additions for patterns this component doesn't use.
- Guideline-change proposals — open an issue against the guidelines
  repo instead.

If there are no Fails and no undocumented Exceptions in *this*
component, write "No fixes required — everything actionable is
already passing." and stop. Do not invent fixes to fill the section.

Order: real component bugs first, then undocumented exceptions.
Each block:

### N. <Short imperative title>

**Check:** C-XX-N — one-line description
**File:** `path/to/file.ext:LINE`
**Why this matters:** one-line user-facing explanation
**Patch:**
\`\`\`diff
- exact old text
+ exact new text
\`\`\`

For README documentation additions, give the exact paragraph to
insert and where ("Add this paragraph to the Theming section, after
the line that says X"). For multi-line patches, keep the diff fenced
so a developer can copy-paste.

## Manual checks still pending

The validator can't run these — they need a browser, a build, or a
running dev server. Run them before declaring the validation done.
For each, give the step-by-step:

1. <Browser check title> — <terminal command to start the server,
   URL to open, what to look at, what passing looks like>
2. <Playwright check title> — exact `npx playwright test <path>` command
3. <Build check title> — exact `npm run build && …` command

## Status of every check

Paste the same PR-ready checkbox block from Step 6 here, with the
correct ticks already filled in, so this file is self-contained for
the PR description.

## See also

- Full per-check evidence and findings: in the chat transcript that
  generated this file
- Live guidelines: `C:\Git\BlissFramework\guidelines\web-components\`
- Auto-check scripts (run them directly without the agent if you want
  fast deterministic verdicts):
  - `bash <guidelines>/web-components/component-structure.checks.sh <pkg>`
  - `bash <guidelines>/web-components/naming-conventions.checks.sh   <pkg> <prefix>`
  - `bash <guidelines>/web-components/css-structure.checks.sh         <pkg> <prefix>`
  - `bash <guidelines>/web-components/theme-container.checks.sh       <pkg> <prefix>`
  - `bash <guidelines>/web-components/base-variables.checks.sh        <pkg> <prefix>`
  - `bash <guidelines>/web-components/color-scheme.checks.sh          <pkg>`
  - `bash <guidelines>/web-components/readme-structure.checks.sh      <pkg>`
- Individual topic validators: `/validate-component-structure`,
  `/validate-naming-conventions`, `/validate-css-structure`,
  `/validate-theme-container`, `/validate-base-variables`,
  `/validate-color-scheme`, `/validate-readme-structure`
```

### Confirm and surface the path

After `Write` succeeds, end the chat report with a one-line pointer
to the file:

> Punch-list written to `<absolute path>`.

If `Write` fails (read-only filesystem, permission denied, target
folder doesn't exist), **don't silently skip** — surface the error,
suggest the user check the path / permissions, and offer to paste the
punch-list contents into the chat as a fallback.

### Don't accumulate stale files

Each run writes a new timestamped file; old ones stay in place so
the team can see the validation trail over time. If the developer
wants only the latest, they can `.gitignore` the pattern
`validation_*.md` and consult the live chat transcript instead.

## Step 9 — Interactive follow-up

After the chat report and punch-list file are written, walk these
three prompts so the user can act on the findings while the context
is fresh. Pose each question in chat (a numbered list + free-form
reply is fine; `AskUserQuestion` with `multiSelect: true` is a
tidier UX when the item count is ≤ 4).

If 9a, 9b, **and 9c** all have zero items, skip Step 9 entirely
with a single line: *"No follow-up needed — no undocumented
exceptions, no deferred entries, and no Strategy A migration
opportunity."*

### 9a — Offer to record undocumented exceptions in `VALIDATION-NOTES.md`

Collect every item the punch-list flagged as "⚠️ Exception that is
not yet documented" (bucket 2 from Step 8). For each, the
punch-list already includes the exact paragraph that would be
appended to `VALIDATION-NOTES.md` so that future runs treat the
deviation as accepted and stop surfacing it.

If there are none, skip 9a.

Otherwise, list them in chat as a numbered table — index, check ID,
short title, one-line rationale — and ask:

> I flagged N undocumented exceptions. For each, the punch-list
> includes the exact paragraph I'd append to `VALIDATION-NOTES.md`
> so it stops surfacing in future runs. Which should I append now?
> Reply with the indices (e.g. "1, 3"), "all", or "none".

For each accepted item, use `Edit` (or `Write` if the file doesn't
exist yet — initialize with `# Validation notes — accepted
deviations\n`) to append the paragraph. After applying, confirm:

> Appended N entries to `VALIDATION-NOTES.md`. Re-run
> `/validate-web-component` to see the updated verdicts (those
> checks will downgrade from ❌ Fail to ✅ Pass / ⚠️ Exception and
> drop out of the punch-list).

Items the user declines stay in the punch-list as undocumented
exceptions — they'll re-surface next round, by design.

### 9b — Offer to tackle deferred entries already in `VALIDATION-NOTES.md`

Use the running list of deferral entries captured in Step 2.5
(headings whose body amounts to "we'll fix this later" rather than
an architectural reason). Per policy these are re-promoted to
❌ Fail on every run and already appear in the current punch-list,
but the user usually doesn't realize an old deferral is still
counting against them. Surface the list explicitly:

> `VALIDATION-NOTES.md` has N deferred entries that are currently
> being treated as Fails per policy:
>   1. C-XX-N — <short title> (deferral note: "<quoted reason>")
>   2. ...
> Do you want to tackle any of them as part of this round's fixes?
> Reply with the indices, "all", or "none".

For each accepted item, echo it in chat under a **"Deferrals
promoted to this round"** heading with the check ID, the file:line
of the underlying flag, and the fix from the punch-list — so the
developer has one clear list of what to do next. Don't rewrite the
punch-list file; the chat callout is enough, and the deferral will
naturally disappear from `VALIDATION-NOTES.md` once the developer
fixes the code and removes the entry.

Items the user declines remain Fails in the punch-list and stay as
deferrals in `VALIDATION-NOTES.md` — they'll re-surface next run,
by design.

### 9c — Offer to migrate Strategy A → Strategy B (color-scheme)

`color-scheme.md` documents two dark-mode strategies. Strategy B is
the recommended default for any component that already follows the
fallback-chain discipline; Strategy A is the legacy / opt-in path for
components that can't migrate cheaply. **Every validation run must
prompt the user when Strategy A is detected**, because Strategy A's
hardcoded literals silently shadow consumer `--base-*` overrides and
make the dark-mode file ~5× longer than it needs to be.

**Detect Strategy A.** Read the component's dark-mode CSS file
(usually `src/css/dark-mode.css` or `src/css/_dark-mode.css`) and
look for either pattern:

1. **Variable redeclaration inside a conditional theme-signal
   selector** — e.g. `:host([data-theme="dark"]) { --xx-bg: #1a1a1a;
   --xx-text: #f5f5f5; ... }`, or the same shape on `:host-context(...)`,
   `[data-theme="dark"] .<prefix>-container`, `.<prefix>-container[data-theme="dark"]`,
   `@media (prefers-color-scheme: dark)`. Two or more `--<prefix>-X:`
   declarations inside any such block is the Strategy A signature.
2. **Absence of `color-scheme: dark` declarations on conditional
   selectors.** A Strategy B component would have lines like
   `:host([data-theme="dark"]) { color-scheme: dark; }`. If those are
   missing AND the file contains theme-signal selectors, the component
   is doing Strategy A by elimination.

Skip 9c **only** when the dark-mode file genuinely contains no
theme-signal selectors at all (Strategy 1 — `light-dark()`-only, no
framework signals) — that's neither A nor B, just the cleanest case.

**If Strategy A is detected, ask once per run, every run, even if a
`VALIDATION-NOTES.md` entry already covers C-BV-9 / similar.** The
register entry stops the check from re-surfacing as a Fail, but the
migration question is orthogonal: A is a legitimate strategy, and B
is a better one — the team needs the prompt to decide whether *this*
round is when they switch.

Phrase the prompt with the **short pitch for why B is better** so the
user can answer without re-reading `color-scheme.md`. Use
`AskUserQuestion` with two single-select options ("Migrate now" /
"Stay on A this round"). The pitch:

> This component is using **Strategy A** in `<dark-mode file>` — it
> overrides each `--<prefix>-*` variable inside every theme-signal
> selector. Strategy B flips `color-scheme: dark` on the same
> selectors instead and lets `light-dark()` in the `--base-*`
> fallbacks resolve automatically. Why B is better:
>
> - **One declaration per signal**, not N variables × M signals. Past
>   migrations have shrunk `dark-mode.css` by ~5× for the same
>   coverage.
> - **Consumer `--base-*` overrides survive.** Strategy A's hardcoded
>   literals (e.g. `#1a1a1a` inside the signal block) silently
>   replace a consumer's themed dark color; Strategy B leaves the
>   consumer's value untouched.
> - **The two halves stay in sync automatically.** Strategy A
>   requires every new variable to be added to every signal block;
>   Strategy B updates itself because the variable's own
>   `light-dark()` fallback flips.
>
> Switch this component to Strategy B in this round?

**Prerequisite check.** Before offering the migration, verify the
component is *eligible*: every color fallback in `variables.css`
must already use `light-dark(<light>, <dark>)`. If not (grep for
`light-dark\(` returns zero matches, or many color fallbacks are
bare literals), state the prerequisite up front so the user knows
the migration includes that work:

> ⚠️ Prerequisite: the component currently has `N` color fallbacks
> as bare literals (no `light-dark()`). Strategy B requires all of
> them to use `light-dark(<light>, <dark>)` — that work is part of
> the migration.

**If the user accepts**, do NOT migrate in this validation pass
(the validator is read-only per Step 0). Instead, write the
migration as a top-priority entry in the punch-list file you just
produced — append it as fix #0 (before existing fixes) with the
concrete edits required:

1. Replace every bare-literal color fallback in `variables.css` with
   `light-dark(<light>, <dark>)`.
2. Replace every variable-redeclaration block in `dark-mode.css`
   with `color-scheme: dark` (or `light`) on the same selectors.
3. Remove the now-stale `C-BV-9` entry from `VALIDATION-NOTES.md`
   (it covered the Strategy A signal-overrides; Strategy B doesn't
   need it).

Then confirm in chat:

> Added Strategy A → B migration as fix #0 in
> `validation_<timestamp>.md`. Run the migration; the next
> validation will detect Strategy B and skip 9c.

**If the user declines**, note it in chat and move on:

> Staying on Strategy A this round. I'll ask again next validation.

Do not record the decline in `VALIDATION-NOTES.md` — declining is
not an architectural decision, it's a "not this round" deferral.
The next run re-asks.

## Discipline

- Never mark ✅ without actually running the verification.
- A check that can't run (missing file, no tool) is ❌ with the reason.
- Browser / build checks are ⚠️ Manual with explicit steps.
- Before declaring a check `❌ Fail`, consult the accepted-deviation
  registers loaded in Step 2.5 (`VALIDATION-NOTES.md` and the
  README's `## Known limitations`). A covering entry that explains
  *why the deviation is correct* downgrades the verdict to
  `⚠️ Exception` (or `✅ Pass`) and removes the item from the
  punch-list. A covering entry that's a deferral ("we'll fix this
  later") stays a Fail — the team made a promise, not an
  architectural decision.
- Documented exceptions in the component README count as ⚠️ Exception
  (quote the limitation), not failures.
- A check that's N/A because of a documented decision (lean strategy,
  underscore convention, etc.) gets N/A with citation.
- The punch-list contains only items a developer must act on, and
  every item must be grounded in something the validator observed in
  *this* component's code. "Optional" means "not applicable to this
  component's scenario", not "nice to have" — if a pattern doesn't
  apply to this component (the component doesn't use the wrapper-host
  pattern, the cascade isn't at risk from unlayered resets, etc.),
  don't write a fix for it. There is no "optional polish" tier;
  every entry is a commitment.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`; prefer Glob
  over `Bash` + `ls`.
- Batch independent file reads in parallel — performance matters when
  scanning 89 checks against the same handful of files.
