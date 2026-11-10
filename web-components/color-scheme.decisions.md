# Color-Scheme — Pre-Implementation Decisions

Answer every decision below **before** writing any CSS for light/dark
handling. Each decision has a recommended default; deviating from the default
requires a one-line justification (write it down somewhere — README, CHANGELOG,
PR description).

Read [color-scheme.md](./color-scheme.md) first if any of these questions
don't make sense.

---

## D-CS-1 — Dark mode strategy — DECIDED (core)

Not a per-component choice any more. Web components on core: `light-dark()` in every color
fallback + the canonical four-rule block ([color-scheme.md](./color-scheme.md)); core detects page
signals and writes `data-context-theme`. Svelte components: per theme-container.md.

---

## D-CS-2 — Framework theme classes to support — DECIDED (core)

Core reads `data-theme`, `data-bs-theme` and `.dark` / `.light` on `<html>` / `<body>` (or the
`theme-source` element) for every component. A component adds no selectors of its own. A new
convention (e.g. MUI's `data-mui-color-scheme`) is a core change (`readThemeSignal()`), never a
component one.

---

## D-CS-3 — Per-instance override attribute — DECIDED

`data-theme="dark"` / `"light"` on the component, and nothing else (2026-11-10: not
`data-bs-theme` on the host, no `theme` attribute, no class). C-CS-11.

---

## D-CS-4 — Hover/active fallback strategy

**Question:** How should hover and active backgrounds compute their fallbacks?

| Option | When to pick |
|--------|--------------|
| **A. Adaptive via `color-mix`** *(default)* | The hover highlight should stay visible regardless of how dark or light the surface is. |
| B. Flat literal | Only if `color-mix` is unsupported (very old browsers) OR if the component has a fixed/known background that won't drift. |

**Default: A. Adaptive.** Use:
```css
color-mix(in srgb, var(--<prefix>-text) 8%, var(--<prefix>-main-bg))
```
for hover, and `14%` for active.

---

## D-CS-5 — Contrast testing scope

**Question:** Which signals will the dark-mode test suite cover?

Default: every row of the table in [color-scheme.md](./color-scheme.md) → "Testing strategy"
(inherited scheme, page signals, `theme-source="closest"`, per-instance both ways, `data-bs-theme`
on the host is not a switch, every floating layer).

**Rule:** every signal the component *claims* to support must have at least
one Playwright test asserting WCAG contrast ≥ 3:1 against a representative
text element.

---

## D-CS-7 — Signal handling strategy — DECIDED

Flip `color-scheme` (the former "Strategy B"); never redeclare `--<prefix>-*` / `--base-*` per
mode. Every web component on core does this since Oct 2026.

---

## D-CS-6 — Forced-colors / high-contrast support

**Question:** Will the component respect Windows High Contrast mode and
similar accessibility modes?

| Option | When to pick |
|--------|--------------|
| **A. No special handling** *(default for now)* | Component uses system-aware colors via `light-dark()` and accent-color; forced-colors will typically work passably. |
| B. Explicit `@media (forced-colors: active)` block | Component has interactive elements (buttons, focus rings, indicators) that need to be visible in forced-colors mode. Worth doing for production-critical components. |

**Default: A.** Revisit when the component lands an accessibility audit.

If you pick B, see the (TBD) `accessibility.md` for the forced-colors pattern.

---

## Decision summary table

Fill this out and paste it into the component's CHANGELOG entry or PR
description so future maintainers know what was decided.

```
D-CS-4 hover/active fallback     : [adaptive color-mix | flat literal]
D-CS-5 contrast tests cover      : [the cases in color-scheme.md → Testing strategy]
D-CS-6 forced-colors             : [no special handling | @media block]
(D-CS-1 / 2 / 3 / 7 are decided — core detection, data-theme, flip color-scheme)
```

---

When done deciding, proceed to implementation. Use
[color-scheme.checks.md](./color-scheme.checks.md) before declaring it done.
