---
description: Validate a component package against theme-container.checks.md (C-TC-1 through C-TC-15). Works for both web-components and Svelte components.
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the component at `$ARGUMENTS` against the
**theme-container** guideline. The component may be a web-component
(custom element with Shadow DOM, container `:host`) or a Svelte
component (light DOM, container `.<prefix>-container`). Be exhaustive
and concrete — file paths and line numbers, not vague summaries. Read-
only: do not edit any files in the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\theme-container.md`
   — rationale, the container-by-component-type table, the
   svelte-treeview rc10 motivating example, the anti-pattern list.
2. `C:\Git\BlissFramework\guidelines\web-components\theme-container.checks.md`
   — the 15 checks C-TC-1 through C-TC-15, with tier tags.
3. `C:\Git\BlissFramework\guidelines\web-components\theme-container.decisions.md`
   — to know which decisions the team should have made (especially
   D-TC-1 component type, D-TC-3 default background, D-TC-7 portal).
4. `C:\Git\BlissFramework\guidelines\CLAUDE.md` → Non-negotiable
   invariants #4 (no `color-scheme`) and #6 (two-layer variables
   live on the container).

## Step 2 — Detect the component type

This validator covers both component types. Detect which one you're
looking at:

- **Web component** signals: `customElements.define(...)` in the
  source, `attachShadow(...)`, CSS files referencing `:host`,
  `<element-name>` tag exported.
- **Svelte component** signals: `.svelte` files, `package.json` with
  `svelte` field or `svelte-package` build script,
  `<prefix>-container` class on a Svelte template root.

Report the detected type up front. If both signals are present (a
Svelte wrapper around a custom element, for instance), run BOTH sets of
checks per check.

## Step 3 — Locate the component

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md`, `CHANGELOG.md` at the root.
- CSS source — usually `src/css/` or `src/lib/styles/`. Find
  `variables.css` (where the container declaration lives) and
  `dark-mode.css` (where the overrides live).
- For Svelte: the top-level `.svelte` file (often `src/lib/Component.svelte`
  or similar) where the container div is rendered.

Identify the component's **prefix** (from manifest / variables.css /
README). The container class for a Svelte component is
`.<prefix>-container`. If the actual class differs from the prefix
convention (e.g. legacy `.ltree-container` vs prefix `ltree` — fine
match — vs hypothetical `.my-tree` vs prefix `ltree` — mismatch), flag
the mismatch.

### Step 3.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record deviations
the team has already accepted. Their content downgrades matching
`❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the note) and
removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):

  ```markdown
  ## C-TC-15 — D-TC-9 = B (no FOUC prevention)
  The component is an inline-style atom (switch / badge / icon
  button) with no pre-upgrade layout footprint, so the FOUC-
  prevention rule doesn't apply. Documented under D-TC-9 = B;
  the consumer-facing ## Known limitations also references it.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority") stays a Fail. See `/validate-web-component` Step 2.5 for
the full contract.

If neither file exists, proceed at face value.

## Step 4 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script that handles every `[auto]`
check mechanically:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/theme-container.checks.sh "$ARGUMENTS" <css-prefix>
```

The CSS prefix can be omitted if `component-variables.manifest.json`
declares it. The script auto-detects web-component vs Svelte (picks
`:host` vs `.<prefix>-container` accordingly) and runs C-TC-1, 3, 5,
7, 15 — the five `[auto]` checks. Capture its output verbatim.

If the script fails to run, fall back to the `.checks.md` prose for
each `[auto]` check.

## Step 5 — Run the semi / manual checks (judgment path)

For every check the script doesn't cover, execute the "How to verify"
prose. Substitute `<prefix>` and `<container>` placeholders with the
real values found in Step 3.

- **C-TC-2** `[semi]` (default background — three patterns) — Grep the
  container block for `background: var(--<prefix>-bg`. Match the
  finding to one of the three D-TC-3 patterns:
  - A (self-painted host): match found → ✅
  - B (intentionally transparent): no match AND README's Theming
    section documents the transparency → ⚠️ Exception (quote the
    note)
  - C (wrapper-host with painted chrome): no `:host` background AND a
    specific internal element (`.<prefix>__input`, `.<prefix>__viewport`)
    paints AND README documents the pattern → ✅
- **C-TC-4** `[semi]` (no *bare* `color-scheme` on container) — Grep
  `color-scheme` across the CSS. Classify each hit per the verdict
  table in `theme-container.checks.md`: bare selector → ❌; conditional
  `:host([…])` / `:host-context(…)` / `.<prefix>-container[…]` selector
  → ✅; inside `@media` or comment → ✅.
- **C-TC-6** `[semi]` (overrides target the container, not descendants)
  — Read `dark-mode.css`. Every block should be either a `@media
  (prefers-color-scheme: dark)` wrapping the container, a
  `:host-context(...)` / `:host([…])` block, or a Svelte
  `[…] .<prefix>-container` block. Anything more specific than the
  container itself fails.
- **C-TC-8** `[semi]` (positioning context, or fixed-floating exception)
  — Grep `position: relative` on the container. If absent, fall to
  the fixed-floating exception: every floating panel (`.<prefix>__dropdown`,
  `.<prefix>__tooltip`, `.<prefix>__popover`, …) uses `position: fixed`
  AND every in-flow `position: absolute` descendant anchors to an
  internal `position: relative` wrapper. If both halves pass → ✅
  Exception (quote the wrapper element). Otherwise → ❌.
- **C-TC-9** `[semi]` (single root container — Svelte only) — Read the
  top-level `.svelte` file's template. The first element should be the
  container; no sibling containers, no `{#each}` at the template root.
  For web-components mark N/A.
- **C-TC-10** `[semi]` (Svelte `theme` prop forwards to `data-theme`) —
  Read the top-level `.svelte`. Look for the `theme` prop declaration
  (Svelte 5: `let { theme = $props() }` or similar; Svelte 4:
  `export let theme`) and the `data-theme={theme || null}` /
  `{theme ?? null}` idiom on the container element. For web-components
  mark N/A.
- **C-TC-11** `[manual]` (docs/theming.md documents the container
  contract) — Read `docs/theming.md`'s container section. Confirm
  coverage of the five points: container selector, default background
  + opt-out, per-instance `data-theme`, framework ancestor
  conventions, portal/popover quirks. If the component pre-dates the
  readme-structure triad and the content lives in `README.md`, mark
  ⚠️ Exception and recommend the readme-structure migration.
- **C-TC-12, C-TC-13, C-TC-14** `[manual]` — browser-required. Always
  ⚠️ Manual. Spell out the exact HTML fixture the user should paste
  (subtree theming smoke, standalone render, per-instance override) —
  copy the examples verbatim from the checks file.

If a check's bash snippet uses tools not available on Windows, use the
Read tool to load the relevant CSS files and reason about them
directly.

## Step 6 — Cross-cutting: the `:root` anti-pattern

Even outside C-TC-1, scan for the broader anti-pattern: any
`--<prefix>-*`-style variable declared anywhere other than the
container. This catches subtler bugs like declarations on a wrapper
class inside the component that aren't reachable from theme overrides.

If you find any, report them as candidates for moving to the container
(or removing if dead code).

## Step 7 — Produce the report

Output to the conversation (no file writes) a markdown report:

```
# Theme-Container Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Component type:** web-component / Svelte / hybrid
**Prefix:** <wg / ms / drp / ltree / sw / ...>
**Container selector:** :host / .<prefix>-container
**Result:** N / 15 passing, M manual, K exceptions

## Auto checks (via theme-container.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-TC-2 — Component renders a visible surface standalone
**Status:** ✅ / ❌ / ⚠️ Exception
**Evidence:** …
**Findings:** …

### C-TC-4 — No bare color-scheme on container
…

### C-TC-6 — Dark/light overrides target the container
…

### C-TC-8 — Container is positioning context (or fixed-floating exception)
…

### C-TC-9 — Single root container (Svelte only)
…

### C-TC-10 — Svelte theme prop forwards to data-theme
…

### C-TC-11 — README documents the container contract
…

## Cross-cutting findings
- Suspicious variable declarations outside container: <list or "none">
- :host, :root dual declaration (web-components only): <present? justified?>

## Manual verifications required (run in browser)
1. C-TC-12 subtree theming smoke — paste this fixture: …
2. C-TC-13 standalone render — paste this fixture: …
3. C-TC-14 per-instance override — paste this fixture: …

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line verdict ("X failures, Y manual checks pending").

## Discipline

- Never mark ✅ without actually running the verification.
- Browser checks are always ⚠️ Manual with explicit copy-pasteable
  fixture HTML.
- A check that's N/A because of component type (Svelte-only checks on
  a web-component, or vice versa) gets N/A with the reason.
- A documented exception in the component README (transparent
  container per D-TC-3 B, portal per D-TC-7 C, etc.) is ⚠️ Exception
  (quote the documentation).
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`.
- Run independent Grep/Read calls in parallel.
