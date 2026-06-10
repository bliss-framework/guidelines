---
description: Validate a component package against theme-container.checks.md (C-TC-1 through C-TC-14). Works for both web-components and Svelte components.
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
   — the 14 checks C-TC-1 through C-TC-14.
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

## Step 4 — Run every check (C-TC-1 through C-TC-14)

For each check, execute the "How to verify" from
`theme-container.checks.md` adapted to this component's actual paths
and prefix. Substitute `<prefix>` and `<container>` placeholders with
the real values found in Step 3.

Notes per check:

- **C-TC-1** (no `--<prefix>-*` on `:root`/`html`/`body`): Grep all
  CSS for variable declarations under document-root selectors. Any
  match is a failure UNLESS this is a web-component using the
  `:host, :root` pattern for a documented portal (D-TC-7 option C) —
  in that case the `:root` declaration is acceptable; mark ⚠️ Exception
  and quote the README portal section.
- **C-TC-2** (default background): Grep the container block for
  `background: var(--<prefix>-bg`. If absent, check the README for a
  documented transparent-container exception (D-TC-3 option B).
- **C-TC-3** (bg chains through `--base-main-bg` + `light-dark()`):
  Read the `--<prefix>-bg` declaration and confirm the chain shape.
- **C-TC-4** (no `color-scheme` on container): Grep `color-scheme`,
  manually inspect each hit, fail if any is inside the container's
  block. Overlaps with C-CS-1.
- **C-TC-5** (per-instance `data-theme` dark AND light): both selectors
  must exist. For web-components Grep
  `:host\(\[data-theme="(dark|light)"\]\)`. For Svelte Grep
  `\.<prefix>-container\[data-theme="(dark|light)"\]`. Confirm both
  blocks set the same variable keys.
- **C-TC-6** (overrides target the container, not descendants): Read
  `dark-mode.css` and visually scan each block's selector. Anything
  more specific than the container itself is suspicious.
- **C-TC-7, C-TC-8** (display + position): Grep the container block
  for `display:` and `position:`. Pass requires `block`/`inline-block`
  + `relative`. Document and pass if `static` is justified for a
  component with no positioned descendants.
- **C-TC-9** (single root container, Svelte only): Read the top-level
  `.svelte` file's template. The first element should be the container;
  no sibling containers, no `{#each}` at the template root. For web-
  components mark N/A (`:host` is single by construction).
- **C-TC-10** (Svelte `theme` prop forwards to `data-theme`): Read the
  top-level `.svelte`. Look for `export let theme` (or `$props` in
  Svelte 5) and the `data-theme={theme || null}` / `{theme ?? null}`
  idiom on the container. For web-components mark N/A.
- **C-TC-11** (README documents the container contract): Read the
  component README, find Theming section, confirm the four points are
  covered.
- **C-TC-12, C-TC-13, C-TC-14**: browser-required. Always ⚠️ Manual.
  Spell out the exact HTML fixture the user should paste (subtree
  theming smoke, standalone render, per-instance override) — copy the
  examples verbatim from the checks file.

If a check's bash snippet uses tools not available on Windows, use the
Read tool to load the relevant CSS files and reason about them directly.

## Step 5 — Cross-cutting: the `:root` anti-pattern

Even outside C-TC-1, scan for the broader anti-pattern: any
`--<prefix>-*`-style variable declared anywhere other than the
container. This catches subtler bugs like declarations on a wrapper
class inside the component that aren't reachable from theme overrides.

If you find any, report them as candidates for moving to the container
(or removing if dead code).

## Step 6 — Produce the report

Output to the conversation (no file writes) a markdown report:

```
# Theme-Container Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Component type:** web-component / Svelte / hybrid
**Prefix:** <wg / ms / drp / ltree / sw / ...>
**Container selector:** :host / .<prefix>-container
**Result:** N / 14 passing, M manual, K exceptions

## Check results

### C-TC-1 — no --<prefix>-* on :root / html / body
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception / N/A
**Evidence:** <commands run, files inspected>
**Findings:**
- <file:line> — <what was found>

[repeat for all 14]

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
