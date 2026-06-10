# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

**Documentation only — no source code, no build, no tests, no `package.json`.**

It is the rulebook that governs how the KeenMate / Bliss custom-element
libraries (`@keenmate/web-grid`, `@keenmate/web-multiselect`,
`@keenmate/web-daterangepicker`, `@keenmate/web-player`, …) are structured.
The components themselves live in *other* repositories under
`C:\Git\BlissFramework\`. Agents working on those components should consult
the files here before scaffolding CSS, theming, or refactoring.

There are no build/lint/test commands at this level. The shell snippets
inside `web-components/*.checks.md` are intended to be run inside a
*component* package (e.g. `packages/web-grid/`), not at this repo's root.

## Directory map

```
web-components/
├── README.md                       ← Index. Read first to pick the right topic.
├── css-structure.md / .decisions.md / .checks.md
├── color-scheme.md  / .decisions.md / .checks.md
├── base-variables.md / .decisions.md / .checks.md
└── example-web-player.md           ← Worked example applying all three topics.
```

Each topic ships as a triad:
- **`<topic>.md`** — rules and rationale. Read once to understand.
- **`<topic>.decisions.md`** — scoping checklist to walk *before* writing code.
- **`<topic>.checks.md`** — verification checklist to walk *before* declaring done.

If a topic has only `<topic>.md`, the decisions/checks haven't been
formalized yet — flag and ask before inventing your own.

## Workflow when applying these guidelines elsewhere

1. From the task, identify which topics are touched (CSS structure, dark mode,
   variable taxonomy — often multiple).
2. Read every applicable `.md` end-to-end.
3. Walk every applicable `.decisions.md` to scope the work; record the picks
   in the PR description / CHANGELOG using the decision-summary tables.
4. Implement.
5. Walk every applicable `.checks.md` and tick every box, or document the
   exception under `## Known limitations` in the component README.

For a **brand-new component**, the canonical reading order mirrors how
you'd build it: `css-structure.md` → `base-variables.md` → `color-scheme.md`
→ `example-web-player.md`.

## Non-negotiable invariants (cross-cutting; details in the topic files)

These hold across every component the guidelines govern. Don't break them
without checking with the team first.

1. **Components must work standalone.** Loading a component without
   `@keenmate/theme-designer` must produce a usable default. Achieved by the
   `var(--base-X, var(--<prefix>-X, <default>))` fallback chain.
2. **Components opt in to theme-designer; they never depend on it.** Setting
   `--base-*` overrides defaults; absence of `--base-*` must not break the
   component.
3. **No JavaScript-based theme detection.** Dark mode, framework theme, and
   per-instance overrides are 100% CSS. JS is for component behavior only.
4. **`color-scheme` MUST NOT be declared on `:host`** — it shadows the
   page's inherited `color-scheme` and breaks dark mode. This is the #1
   footgun the guidelines exist to prevent.
5. **One component → one short prefix.** Existing reservations:
   `wg` (web-grid), `ms` (web-multiselect), `drp` (web-daterangepicker),
   `wp` (web-player). New components reserve their prefix in
   `base-variables.md` before coding.
6. **Two layers of CSS variables, never three.**
   - `--base-*` = cross-component theming hook (set by theme-designer or
     consumer at `:root`).
   - `--<prefix>-*` = component-local, defined on `:host`, consumed by feature
     rules. A parallel taxonomy like `--wp-base-*` is wrong.
7. **`@layer variables, component, overrides;`** is the canonical cascade in
   every `main.css`. Every `@import` must specify its layer.
8. **Every visible color resolves through a variable** — no hex/rgb literals
   in feature files. `variables.css` and `dark-mode.css` are the only files
   that may hold color literals.
9. **Fallbacks for colors use `light-dark(<light>, <dark>)`**, not bare light
   literals. Never write a single-value `var(--base-X)` with no fallback.
10. **BEM with the component prefix on every class** —
    `<prefix>__element--modifier`. Two underscore levels max.

## Editing the guidelines themselves

When updating these docs:
- The `.md`, `.decisions.md`, and `.checks.md` files for a topic are
  interlocking. A change in one usually requires a touch in the others
  (e.g. a new rule needs both a decision question and a check).
- `web-components/README.md` is an **index**, not a guideline — keep the
  cross-references and tables in sync when files are added or renamed.
- The "Existing prefixes" table in `base-variables.md` and
  `base-variables.decisions.md` is the registry of reserved component
  prefixes. Update both when a new component is added.
- The canonical `--base-*` taxonomy table in `base-variables.md` is the
  source of truth for cross-component variables. Adding an entry is a
  coordination move — flag it as such.
