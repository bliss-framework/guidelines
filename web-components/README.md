# Web Component Guidelines — Index

This folder contains the project-wide rules for building custom-element libraries
in the Bliss / KeenMate ecosystem (`@keenmate/web-grid`,
`@keenmate/web-multiselect`, `@keenmate/web-daterangepicker`,
`@keenmate/web-player`, etc.).

**For AI agents:** This README is an index, not a guideline. Read it to figure
out *which* guideline file applies to the work you're doing, then read that
file. Don't act on guidance from here alone.

---

## File structure

Each guideline topic comes as up to three files:

- **`<topic>.md`** — the rules and rationale. Read once to understand the
  topic. Re-read when something feels unclear.
- **`<topic>.decisions.md`** — the questions you must answer *before* you
  start writing code. Use this as a checklist when scoping new work.
- **`<topic>.checks.md`** — the verifications you must run *after* you finish
  the code. Use this as a checklist before declaring the work done.

If a topic only has `<topic>.md`, the decisions/checks haven't been formalized
yet (TBD).

## When to consult which file

| If you are… | Read |
|-------------|------|
| Scaffolding a new component's CSS, or refactoring an existing one's structure | [css-structure.md](./css-structure.md) → [.decisions](./css-structure.decisions.md) → implement → [.checks](./css-structure.checks.md) |
| Adding or changing how a component reacts to dark mode | [color-scheme.md](./color-scheme.md) → [.decisions](./color-scheme.decisions.md) → implement → [.checks](./color-scheme.checks.md) |
| Defining new CSS variables on a component, or wiring `--base-*` hooks | [base-variables.md](./base-variables.md) → [.decisions](./base-variables.decisions.md) → implement → [.checks](./base-variables.checks.md) |
| Looking for a concrete worked example | [example-web-player.md](./example-web-player.md) |

If the task touches more than one topic, read every applicable `.md` before
you start, walk every applicable `.decisions.md` to scope the work, and run
every applicable `.checks.md` before declaring done.

**Starting a brand-new component?** Read in order: `css-structure.md` →
`base-variables.md` → `color-scheme.md` → `example-web-player.md`. The
ordering mirrors how you'd actually build the component.

---

## Mandatory checklist before declaring a web component "done"

Tick every box, or document the exception in a `## Known limitations` section
of the component's README.

### CSS structure
- [ ] CSS folder follows the canonical file set (Tier 1 + Tier 2 always
      present; empty Tier-2 files have a stub comment). See `css-structure.md`.
- [ ] `main.css` declares `@layer variables, component, overrides;` and every
      `@import` specifies its layer.
- [ ] No underscore-prefixed file names (legacy SASS convention).
- [ ] BEM convention used for all class names.

### CSS variables
- [ ] Every visible color in the shadow DOM resolves through a CSS variable —
      no hardcoded color literals in non-`:host` rules.
- [ ] Every component variable (`--<prefix>-*`) provides a `--base-*` lookup
      with a sensible final fallback. See `base-variables.md`.
- [ ] The component publishes a `component-variables.manifest.json` enumerating
      every `--base-*` it reads and every `--<prefix>-*` it exposes.
- [ ] Fallbacks for color variables use `light-dark(<light>, <dark>)`, not bare
      light literals. See `color-scheme.md`.

### Dark mode
- [ ] No `:host { color-scheme: ... }` declaration anywhere — this breaks
      inheritance from the page.
- [ ] `:host-context()` selectors catch the framework conventions
      (`data-theme`, `data-bs-theme`, `.dark`, `.light`).
- [ ] `:host([data-theme="dark"])` / `:host([data-theme="light"])` provide
      per-instance override.
- [ ] At least one Playwright spec asserts WCAG contrast in dark mode for the
      component's primary surfaces. Target ≥ 3:1 for non-text UI, ≥ 4.5:1 for
      body text.

### Documentation
- [ ] Component `README.md` documents which `--base-*` variables it consumes,
      which `--<prefix>-*` it exposes, and the supported theme conventions
      (`data-theme`, etc.).
- [ ] CHANGELOG entry for the version that lands the theming work.

---

## Vocabulary

To avoid confusion across docs:

- **`--base-*`** — cross-component theming hook. Set once (typically by
  `@keenmate/theme-designer` or by the consumer at the document root), applies
  to every component that reads it. Example: `--base-main-bg`,
  `--base-accent-color`.
- **`--<prefix>-*`** — component-local CSS variable. Example: `--wg-cell-padding`
  in web-grid, `--ms-option-bg` in multiselect. The component owns these and
  defines their defaults at `:host`.
- **Component-specific variable** — same as `--<prefix>-*`. Each component
  picks a short prefix (`wg`, `ms`, `drp`, `wp`) and uses it consistently.
- **Theme designer** — `@keenmate/theme-designer`. Centralized package that
  sets all `--base-*` variables at `:root` based on a chosen theme.
- **Light DOM** — the consumer's HTML outside the shadow root.
- **`:host-context(selector)`** — the only way for shadow-DOM CSS to see
  ancestors in light DOM. Use it for framework theme classes.

---

## Project-wide invariants

These hold across every component. If you find yourself wanting to break one,
stop and check with the team first.

1. **Components must work standalone.** Loading a component without
   theme-designer must produce a usable default appearance. Achieved by the
   `--base-*` fallback chain — `var(--base-X, var(--<prefix>-X, <default>))`.
2. **Components must opt in to theme-designer, not depend on it.** Setting
   `--base-*` from outside should override defaults, but the component must
   never require theme-designer to be present.
3. **No JavaScript-based theme detection.** Dark mode, framework theme, and
   per-instance overrides are 100% CSS. JS is for component behavior, not for
   color-scheme decisions.
4. **One component, one prefix.** A component picks `--xx-*` once and uses it
   for every internal variable. Cross-component variables are `--base-*`.
5. **Fallback chains, never single-value reads.**
   `var(--base-main-bg)` alone is a bug — always provide the default:
   `var(--base-main-bg, light-dark(#ffffff, #1a1a1a))`.

---

## Where this lives

Path: `C:\Git\BlissFramework\guidelines\web-components\`

Future guideline files that might land here (TBD; placeholders, not yet
written):

- `accessibility.md` — keyboard navigation, ARIA, focus visibility
- `shadow-dom-events.md` — composed events, slot composition, event bubbling
- `typescript.md` — type exports, declaration files, dual UMD/ESM publishing
- `testing.md` — Playwright fixtures, contrast suites, snapshot conventions
- `packaging.md` — `dist/` layout, package.json `exports` field, CDN-friendliness

If you're starting work in one of those areas and the file doesn't exist yet,
ask the user before inventing your own convention.
