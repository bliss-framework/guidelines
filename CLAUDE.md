# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

**Documentation only — no source code, no build, no tests, no `package.json`.**

It is the rulebook that governs how the KeenMate / Bliss component
libraries — both web-components (`@keenmate/web-grid`,
`@keenmate/web-multiselect`, `@keenmate/web-daterangepicker`,
`@keenmate/web-player`, …) and Svelte components
(`@keenmate/svelte-treeview`, `@keenmate/svelte-switch`, …) — are
structured. The components themselves live in *other* repositories
under `C:\Git\BlissFramework\` (and a few under `C:\Git\KM\`). Agents
working on those components should consult the files here before
scaffolding CSS, theming, or refactoring.

The folder `web-components/` is a historical name; the rules inside
apply equally to Svelte components, with per-technology shapes called
out in each file.

There are no build/lint/test commands at this level. The shell snippets
inside `web-components/*.checks.md` are intended to be run inside a
*component* package (e.g. `packages/web-grid/`), not at this repo's root.

## Directory map

```
web-components/
├── README.md                              ← Index. Read first to pick the right topic.
├── component-intake.md                    ← Pre-flight: technology, package, prefix
├── component-structure.md / .decisions.md / .checks.md   ← Layers, files, classes, TS suffixes
├── naming-conventions.md  / .decisions.md / .checks.md   ← Tags, attributes, callbacks, events, BEM
├── css-structure.md       / .decisions.md / .checks.md
├── theme-container.md     / .decisions.md / .checks.md   ← :host vs .<prefix>-container
├── base-variables.md      / .decisions.md / .checks.md
├── color-scheme.md        / .decisions.md / .checks.md
├── readme-structure.md    / .decisions.md / .checks.md   ← Slim README + docs/ folder split
└── example-web-player.md                  ← Worked example applying the topics.
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

For a **brand-new component**, run the intake first
(`component-intake.md`, or `/new-component`) to fix technology, package
name, and prefix. Then the canonical reading order mirrors how you'd
build it: `component-structure.md` → `naming-conventions.md` →
`css-structure.md` → `theme-container.md` → `base-variables.md` →
`color-scheme.md` → `readme-structure.md` → `example-web-player.md`.

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
4. **A *bare* `color-scheme` MUST NOT be declared on the component
   container** — neither bare `:host` (web-components) nor bare
   `.<prefix>-container` (Svelte). The unconditional version shadows
   the page's inherited `color-scheme` and breaks dark mode; this is
   the #1 footgun the guidelines exist to prevent.
   **Conditional declarations are allowed and often preferred**:
   `:host([data-theme="dark"]) { color-scheme: dark }`,
   `:host-context([data-bs-theme="dark"]) { color-scheme: dark }`,
   `.<prefix>-container[data-theme="dark"] { color-scheme: dark }`,
   etc. fire only when the consumer has signalled their theme intent
   and are the basis of Strategy B in `color-scheme.md`. See
   `color-scheme.md` → "Two strategies for framework-class &
   per-instance signals" and check C-CS-1 for the bare-vs-conditional
   distinction.
5. **One component → one short prefix.** Existing reservations:
   `wg` (web-grid), `ms` (web-multiselect), `drp` (web-daterangepicker),
   `wp` (web-player), `wtv` (web-treeview), `stv` (svelte-treeview),
   `sw` (svelte-switch). New components reserve their prefix in
   `base-variables.md` before coding.
6. **Two layers of CSS variables, never three.**
   - `--base-*` = cross-component theming hook (set by theme-designer or
     consumer at `:root` or on a subtree wrapper).
   - `--<prefix>-*` = component-local, defined on the container (`:host`
     or `.<prefix>-container`), consumed by feature rules. A parallel
     taxonomy like `--wp-base-*` is wrong.
   - `--<prefix>-*` declarations MUST live on the container — never on
     `:root` / `html` / `body`. Subtree theming breaks otherwise; see
     `theme-container.md` and the svelte-treeview rc10 migration for
     the concrete failure mode.
7. **`@layer variables, component, overrides;`** is the canonical cascade in
   every `main.css`. Every `@import` must specify its layer.
8. **Every visible color resolves through a variable** — no hex/rgb literals
   in feature files. `variables.css` and `dark-mode.css` are the only files
   that may hold color literals.
9. **Fallbacks live at the definition site, not the read site.** Every
   `var(--base-X)` read inside a container's variable declaration
   needs a fallback (literal or chain); color fallbacks use
   `light-dark(<light>, <dark>)`. Feature-file reads of
   `var(--<prefix>-X)` deliberately do *not* duplicate the fallback —
   the container's chain already guarantees the variable resolves. See
   `base-variables.md` → "Fallbacks live at the definition site".
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
