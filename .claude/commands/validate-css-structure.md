---
description: Validate a web-component package against css-structure.checks.md (C-CSS-1 through C-CSS-12).
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the web-component at `$ARGUMENTS` against the
**css-structure** guideline. Be exhaustive and concrete — file paths and
line numbers, not vague summaries. Read-only: do not edit any files in
the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\css-structure.md` —
   the canonical file set (Tier-1 + Tier-2), `@layer` cascade
   conventions, BEM rules, section-banner format.
2. `C:\Git\BlissFramework\guidelines\web-components\css-structure.checks.md`
   — the 12 checks C-CSS-1 through C-CSS-12.
3. `C:\Git\BlissFramework\guidelines\web-components\css-structure.decisions.md`
   — to know what decisions the team should have made (canonical vs lean
   strategy at D-CSS-1, @layer choice at D-CSS-3, naming convention at
   D-CSS-4, BEM choice at D-CSS-6, banner threshold at D-CSS-7).
4. `C:\Git\BlissFramework\guidelines\CLAUDE.md` → Non-negotiable
   invariants #7 (`@layer variables, component, overrides;`) and #10 (BEM).

## Step 2 — Locate the component

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md` at the root.
- CSS source folder — typically `src/css/`. List every `.css` file in it.
- The entry CSS file — usually `main.css` (or the file referenced from
  `package.json`'s `style` / `exports.style` field).

If the README documents a "lean strategy" (D-CSS-1 option B), some checks
(C-CSS-1, C-CSS-4) become N/A. Identify this up front so you don't
spuriously fail the component.

Identify the component's **prefix** from the README / variables.css /
manifest — most BEM checks need it.

## Step 3 — Run every check (C-CSS-1 through C-CSS-12)

For each check, execute the "How to verify" from `css-structure.checks.md`
adapted to this component's actual paths. Notes:

- **C-CSS-1** (canonical file set: `main.css`, `variables.css`, `base.css`,
  `controls.css`, `floating.css`, `states.css`, `animations.css`,
  `dark-mode.css`): use Glob to list `src/css/*.css`. If any of the eight
  is missing AND the README does not document the lean strategy, fail.
  Skip this check if D-CSS-1 chose lean (document the skip).
- **C-CSS-2** (no underscore prefix): Glob `src/css/_*.css`. Any match is
  a failure — unless D-CSS-4 chose underscore convention (legacy) and the
  README documents it.
- **C-CSS-3** (`@layer` declared and used): Read `main.css`. Confirm
  exactly one `@layer variables, component, overrides;` declaration and
  that every `@import` includes `layer(...)`. Skip if D-CSS-3 chose option
  C (no layers, legacy).
- **C-CSS-4** (stub comment in empty Tier-2 files): for each empty Tier-2
  file, Read line 1 and confirm a `/* ... */` stub.
- **C-CSS-5** (every file imported by main.css): list all `.css` files
  except `main.css` itself, Grep `main.css` for each. Files not imported
  are orphans.
- **C-CSS-6** (section banners on files > 100 lines): for each `.css`
  file with > 100 lines, Grep for `==========`. The threshold may be
  different per D-CSS-7 — check the README.
- **C-CSS-7** (BEM convention): Grep all class selectors and verify each
  starts with `.<prefix>__`. False positives include pseudo-selectors
  (`:hover`, `::before`) — these are not classes, ignore them. Skip if
  D-CSS-6 chose options B or C (different convention).
- **C-CSS-8** (no hardcoded colors in feature files): same regex as
  C-BV-1 in base-variables.checks.md, but the scope here is the feature
  files (everything except `variables.css` and `dark-mode.css`). Cross-
  references base-variables — if you're running both validators, you can
  share the result.
- **C-CSS-9** (no mixed-bag files): inspect each Tier-3 file (or any
  feature file) and confirm its rules all relate to one feature. This is
  a judgment call — flag any file whose name does not describe its actual
  content.
- **C-CSS-10** (README documents layer contract): Read the README, find
  a Theming or Code-structure section, confirm it covers: the layer
  names, the override contract, how to set `--base-*` and `--<prefix>-*`.
- **C-CSS-11** (`main.css` has no rules): Read `main.css`. Every non-
  blank line should start with `@`, `/`, or whitespace.
- **C-CSS-12** (bundle size sanity): ⚠️ Manual — requires running the
  build. List the command the human should run (`npm run build` then
  `ls -lh dist/*.css`).

## Step 4 — Produce the report

Output to the conversation:

```
# CSS-Structure Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Prefix:** <wg / ms / drp / wp / ...>
**Strategy:** canonical / lean (per D-CSS-1)
**Result:** N / 12 passing, M manual, K exceptions

## Check results

### C-CSS-1 — canonical file set present
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception / N/A
**Evidence:** <commands run, files inspected>
**Findings:**
- <file:line> — <what was found>

[repeat for all 12]

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line summary the user can scan at a glance.

## Discipline

- Never mark ✅ without actually running the verification.
- A check that's N/A because of a documented decision (lean strategy,
  underscore convention, no-layers strategy) gets N/A with a citation of
  the README section that documents it. Do not silently pass.
- Documented exceptions in `## Known limitations` of the component README
  are ⚠️ Exception (quote the limitation), not failures.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`. Prefer Glob
  over `Bash` + `ls`.
- Run independent Grep/Read calls in parallel.
