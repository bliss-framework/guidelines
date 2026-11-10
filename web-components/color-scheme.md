# Light / Dark Color Scheme — Web Component Guideline

How a KeenMate web component reacts to light / dark: who detects the theme, the one CSS block every
component carries, and the rules that keep every component on a page showing the same scheme.

Detection is **not** a per-component job any more. `@keenmate/web-components-core` detects the theme
once per page (SPEC §12.10, `src/environment/theme.ts`) and writes the result onto every
`BlissElement` host as `data-context-theme`. A component's job is two things: map that attribute
(and the per-instance `data-theme`) onto `color-scheme`, and write every color as a `light-dark()`
pair so it follows. See [theme-container.md](./theme-container.md) for *where* the rules anchor
(`:host` for web components, `.<prefix>-container` for Svelte).

Svelte components (no core) keep their own container rules per theme-container.md; the canonical
block and C-CS-3 / C-CS-11 below are for web components on core.

---

## TL;DR

> **Every color is `var(--base-*, light-dark(<light>, <dark>))`. `src/css/dark-mode.css` has exactly
> the four canonical rules below — context first, per-instance last. No `:host-context()`, no
> `prefers-color-scheme`, no JS detection, no per-instance switch other than `data-theme`. Every
> panel / tooltip / menu lives in the component's shadow root (or gets the host's scheme copied).**

---

## How the scheme is decided (highest first)

| # | Signal | Set by | Handled by |
|---|---|---|---|
| 1 | **Per-instance** `data-theme="dark"` / `"light"` on the component itself | the app, for one widget | the component's CSS (`:host([data-theme])`, declared last) |
| 2 | **Forced** `setThemeMode('dark' \| 'light')` | the app, once, for every component | core → `data-context-theme` |
| 3 | **Theme source** — `theme-source="closest"` (nearest ancestor with a signal), a CSS selector, or an element | the app, on the component | core → `data-context-theme` |
| 4 | **Page signal** — `data-theme`, `data-bs-theme`, `.dark` / `.light` on `<html>`, then `<body>` | the app's theme toggle (Bootstrap 5.3+, Tailwind, hand-rolled) | core → `data-context-theme` |
| 5 | **Nothing** | — | no rule: the host inherits the page's `color-scheme`. The OS applies **only** when the page declares `color-scheme: light dark`; nothing declared = light. |

What this means in practice:

- **The page signal beats the OS.** A page with `<html data-theme="light">` renders light on a dark
  OS. That is intended: the page's own toggle is the user's choice.
- **`theme-source="closest"` with no signal on any ancestor falls through to the page signal (4)**,
  not to the OS. A section that wants "follow the OS" has no signal of its own to express that.
- Only `dark` / `light` count. `data-theme="corporate"` is not a scheme; detection moves on.
- It is live: core re-detects when a signal attribute / class changes, and `closest` re-resolves when
  an ancestor gains or loses a signal.
- A signal on the host itself is never read by core (its walk starts at the parent). The host's own
  `data-theme` is pure CSS — rule 1 — which is why the component's CSS decides what counts there.

---

## The canonical block (`src/css/dark-mode.css`)

Every web component on core carries exactly this (multiselect, treeview, daterangepicker,
commandpalette, dropzone, grid):

```css
/* Page / theme-source signal: core mirrors it onto the host as data-context-theme
   (setThemeMode > theme-source > <html> > <body>). Replaces :host-context(), which Firefox
   doesn't support and Safari only partly. */
:host([data-context-theme="dark"]) {
  color-scheme: dark;
}

:host([data-context-theme="light"]) {
  color-scheme: light;
}

/* Per-instance attribute — declared last (same specificity), so it wins in both directions. */
:host([data-theme="dark"]) {
  color-scheme: dark;
}

:host([data-theme="light"]) {
  color-scheme: light;
}
```

That's all. The rules only flip `color-scheme`; every color in `variables.css` is a `light-dark()`
pair (C-CS-2), so the right branch resolves wherever the variable is used — and a consumer's
`--base-*` values keep flowing (nothing is redeclared per mode).

**The bare `:host` block never declares `color-scheme`** (C-CS-1). A bare declaration shadows the
page's inherited scheme for every instance — the multiselect v1.10 bug. The four rules above are
conditional: they fire only when a signal is present.

A component with an inner element that a programmatic (non-element) API mounts into the page, like
`new WebTreeView(container, …)`, may add that element to the per-instance selectors
(`:host([data-theme="dark"]), .wtv__container[data-theme="dark"]`) so the caller can put
`data-theme` on their own container. It adds no new attribute.

### Why `light-dark()` instead of `@media (prefers-color-scheme)`

`light-dark(<light>, <dark>)` resolves against the nearest used `color-scheme`. So the four rules
above flip it, the page's `color-scheme` flips it when no signal is set, and a page that wants the
OS declares `html { color-scheme: light dark }` once and every component follows, live. A
`prefers-color-scheme` block would hard-code dark values and override a page that forced light.

### Why `color-mix` for hover / active

Hardcoded hover colors (`#f0f0f0` / `#3a3a3a`) vanish when the page's background drifts. Mixing the
text color into the background by 8–14% always steps toward the text, so it stays visible:

```css
--my-hover-bg: var(--base-hover-bg,
  color-mix(in srgb, var(--my-text) 8%, var(--base-main-bg, light-dark(#fff, #1a1a1a))));
```

---

## Panels, tooltips, menus

A floating layer shows the host's scheme only if it inherits it:

- **Mount it in the component's shadow root** (the default — multiselect's dropdown, grid's cell
  dropdown and date editor, every core `/menu` and `createPopover()` panel a component hosts). It
  inherits `color-scheme` and every `--<prefix>-*` / `--base-*` from the host.
- **Only if it must leave the shadow root** (a top-layer escape): position it with core `anchor()` /
  `createPopover()` and `inheritThemeFrom: <host>`, which copies `data-theme`, `data-bs-theme`,
  `data-context-theme` and `data-motion` onto the panel, and give the panel's own CSS the same four
  rules on its root class. A `document.body` panel with `<head>` styles and no copy follows the
  **page**, not the component (grid's date editor did, until 2026-11-10).

C-CS-10 checks tooltips; the same applies to every floating layer.

---

## Rules of the road

### Always

1. **Every visible color is a CSS variable** whose final fallback is `light-dark()` (role fills and
   the text on them excepted — C-CS-2).
2. **Fallback chain:** `var(--base-X, light-dark(...))` (or `var(--<prefix>-X, var(--base-X, …))`), so
   a theme sets `--base-*` once for every component.
3. **The canonical four-rule block**, in that order (C-CS-3).
4. **`data-theme` is the only per-instance switch.** Not `data-bs-theme` on the host, not a `theme`
   attribute, not a class. One switch, the same in every component (decided 2026-11-10).
5. **Floating layers live in the shadow root**, or get the host's scheme copied (section above).
6. **Document the contract** in `docs/theming.md`: the order above, `theme-source`, `data-theme`,
   and that the OS applies only through the page's `color-scheme`.
7. **Example pages:** a demo card's "Auto" option removes the card's `data-theme` and nothing else.
   The card's own chrome uses `light-dark()` so card and component inherit the same scheme. Never set
   `color-scheme: light dark` on a demo card while the component inside follows the page: the two
   disagree whenever the OS and the page toggle differ (multiselect TH01, fixed 2026-11-10). The devkit
   always puts `data-theme` on `<html>`, so on a devkit page "Auto" means "follow the page".

### Never

1. **Never a bare `:host { color-scheme: … }`** (C-CS-1).
2. **Never `:host-context()`** — core's `data-context-theme` replaced it (Firefox has no
   `:host-context()`, Safari only partly). C-CS-11.
3. **Never `@media (prefers-color-scheme)`** in component CSS, and **never detect the theme in JS**
   (`matchMedia('(prefers-color-scheme…')`, observers on `<html>` / `<body>`). Core does detection
   once per page; the OS reaches the component through the page's `color-scheme`. C-CS-11.
4. **Never a second per-instance switch** (`:host([data-bs-theme])`, `:host([theme])`, `:host(.dark)`).
   C-CS-11.
5. **Never hardcode a color at the use site** (`background: #1a1a1a` outside a variable).
6. **Never invert some colors without the rest** — text, borders, shadows and tints layered on a
   surface must flip with it; variables make the cascade do it.

---

## Testing strategy

Per component (fixture page under `test/`, e2e spec), with the contrast helper from
`web-grid/e2e/dark-mode.spec.ts` (handles `color(srgb …)` and composites translucent backgrounds):

| Case | Expect |
|---|---|
| No signal, page `color-scheme` unset | light |
| `<html style="color-scheme: dark">`, no signal | dark (inherited) |
| OS dark + page `color-scheme: light dark` | dark |
| `data-theme` / `data-bs-theme` / `.dark` on `<html>` | dark (`data-context-theme="dark"` on the host) |
| a dark section + `theme-source="closest"` | dark |
| per-instance `data-theme="dark"` on a light page | dark |
| per-instance `data-theme="light"` on a dark page | light |
| `data-bs-theme="dark"` on the host itself | **no change** (not a switch) |
| every floating layer, opened in a dark host on a light page | dark |

Assert WCAG contrast ≥ 4.5:1 for body text, ≥ 3:1 for non-text UI.

---

## Anti-patterns we've actually seen

1. **Bare `:host { color-scheme: light dark }`** — multiselect v1.10 ignored the page's dark scheme.
2. **`@media (prefers-color-scheme: dark)` with hard-coded values** — web-grid rendered dark on a dark
   OS even when the app forced light.
3. **Literal colors in rules** (`background: #f5f5f5`, a flat gray hover) — invisible on dark.
4. **JS detection on `DOMContentLoaded`** — missed a mid-session switch.
5. **`:host-context()` for page signals** — never matched in Firefox; replaced by core's
   `data-context-theme` (Oct 2026).
6. **A floating layer in `document.body`** with `<head>` styles — web-grid's date editor showed the
   page's scheme, not the grid's (fixed 2026-11-10 by mounting it in the shadow root). Tooltips had the
   same shape earlier (C-CS-10).
7. **Two per-instance switches** — daterangepicker and grid also forced on `:host([data-bs-theme])`,
   treeview had its own `theme` attribute; the same markup behaved differently per component (removed
   2026-11-10).
8. **A demo card that follows the OS around a component that follows the page** — multiselect TH01's
   "Auto" set `color-scheme: light dark` on the card (fixed 2026-11-10, rule "Always" #7).
9. **Docs describing a mechanism that no longer exists** — treeview's TH01 said "follows the OS via
   `prefers-color-scheme`" after that rule was gone. When the theme model changes, grep the example
   pages and docs too.

---

## Reference implementation

`@keenmate/web-multiselect` — `src/css/dark-mode.css` (the four rules with the explanatory comment),
`src/css/variables.css` (the bare `:host` block, `light-dark()` fallbacks, the comment on why no
`color-scheme` there), every floating layer in the shadow root. Example: `examples-theming.html` TH01.

---

## Open questions / future work

- `prefers-contrast: more` / forced colors — no component handles them yet (D-CS-6).
- The dark-mode contrast helper is still copied per component; extract it once it is needed again.
