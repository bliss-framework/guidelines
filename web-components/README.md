# Component Guidelines — Index

This folder contains the project-wide rules for building UI component
libraries in the Bliss / Keenmate ecosystem — both **web-components**
(custom elements with Shadow DOM, e.g. `@keenmate/web-grid`,
`@keenmate/web-multiselect`, `@keenmate/web-daterangepicker`,
`@keenmate/web-player`) and **Svelte components** (light DOM,
e.g. `@keenmate/svelte-treeview`, `@keenmate/svelte-switch`).

> The folder is named `web-components/` for historical reasons. The
> rules apply to Svelte components too; each guideline calls out the
> per-technology shape where it differs. Future host technologies
> (React, Vue, Blazor / C#, LiveView / Elixir) inherit the same shape
> with their equivalent root-element selector.

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

### Check tiers

Each check inside a `.checks.md` carries a tier tag right under its heading:

- **`[auto]`** — purely mechanical. A regex / shell one-liner returns the
  pass/fail verdict. Runnable in CI with no agent in the loop. Today these
  live as inline `bash` blocks; the goal is a companion `.checks.sh` per
  triad that consolidates them into one runnable script.
- **`[semi]`** — mostly mechanical but needs minimal context (e.g. knowing
  the component's CSS prefix, web-component vs Svelte). Often runnable
  after a small detection prelude.
- **`[manual]`** — genuinely needs judgment: reading function bodies,
  observing the browser, judging accuracy of prose. An agent or human
  reads the code, runs the dev server, decides.

Current tier totals across the checks (CSS structure + theme container
+ base variables + color scheme + component structure + naming
conventions + readme structure + custom-elements-manifest +
responsive-overlay + publish-command + example-pages + core-adoption):

| Triad | auto | semi | manual | total |
|-------|-----:|-----:|-------:|------:|
| css-structure | 9 | 2 | 1 | 12 |
| theme-container | 5 | 6 | 4 | 15 |
| base-variables | 6 | 5 | 3 | 14 |
| color-scheme | 2 | 5 | 3 | 10 |
| component-structure | 7 | 2 | 2 | 11 |
| naming-conventions | 7 | 4 | 1 | 12 |
| readme-structure | 8 | 7 | 1 | 16 |
| custom-elements-manifest | 9 | 3 | 1 | 13 |
| responsive-overlay | 3 | 9 | 2 | 14 |
| publish-command | 11 | 0 | 0 | 11 |
| example-pages | 3 | 0 | 1 | 4 |
| core-adoption | 7 | 5 | 1 | 13 |
| **Total** | **77** | **48** | **20** | **145** |

That’s roughly 53% auto, 33% semi, 14% manual — most of the rulebook
*can* be mechanized; the open work is writing the runner script(s).

## When to consult which file

| If you are… | Read |
|-------------|------|
| Starting a brand-new component (picking technology, package name, CSS prefix) | [component-intake.md](./component-intake.md) — or run `/new-component` for an interactive walkthrough |
| Setting up or refactoring the component's internal architecture (Element / Logic / Service / Side layer split, file organization, class suffixes, TS interface suffixes) | [component-structure.md](./component-structure.md) → [.decisions](./component-structure.decisions.md) → implement → [.checks](./component-structure.checks.md) |
| Settling the component's public API names (custom-element tag, HTML attributes, `CustomEvent` names, callback hierarchy and `before*` contract, contexts + `controller`, action items / menus, verb glossary, state vs `get*()`, boolean key → attribute derivation, disabled / readonly, event shapes, counts, messages, `labels` / i18n, ready / defer / destroy, internal method naming, BEM prefix application) | [naming-conventions.md](./naming-conventions.md) → [.decisions](./naming-conventions.decisions.md) → implement → [.checks](./naming-conventions.checks.md) |
| Scaffolding a new component's CSS, or refactoring an existing one's structure | [css-structure.md](./css-structure.md) → [.decisions](./css-structure.decisions.md) → implement → [.checks](./css-structure.checks.md) |
| Choosing or refactoring the component's root container (`:host` for web-components, `.<prefix>-container` for Svelte), wiring per-instance `data-theme`, deciding default background | [theme-container.md](./theme-container.md) → [.decisions](./theme-container.decisions.md) → implement → [.checks](./theme-container.checks.md) |
| Adding or changing how a component reacts to dark mode | [color-scheme.md](./color-scheme.md) → [.decisions](./color-scheme.decisions.md) → implement → [.checks](./color-scheme.checks.md) |
| Defining new CSS variables on a component, or wiring `--base-*` hooks | [base-variables.md](./base-variables.md) → [.decisions](./base-variables.decisions.md) → implement → [.checks](./base-variables.checks.md) |
| Writing or restructuring a component's external documentation (slim README + `docs/` folder) | [readme-structure.md](./readme-structure.md) → [.decisions](./readme-structure.decisions.md) → implement → [.checks](./readme-structure.checks.md) |
| Making a web-component discoverable — shipping a Custom Elements Manifest (`custom-elements.json`), the `customElements` / `web-types` package.json fields, and editor autocomplete (VS Code / JetBrains) for webcomponents.org listing | [custom-elements-manifest.md](./custom-elements-manifest.md) → [.decisions](./custom-elements-manifest.decisions.md) → implement → [.checks](./custom-elements-manifest.checks.md) *(web-components only)* |
| Making a component that **opens a floating panel** (dropdown, calendar, autocomplete, menu) present well on phones — phone full-screen vs tablet/desktop anchored, `dvh` sizing, soft-keyboard, touch targets, safe-area insets | [responsive-overlay.md](./responsive-overlay.md) → [.decisions](./responsive-overlay.decisions.md) → implement → [.checks](./responsive-overlay.checks.md) *(panel-opening components only)* |
| Wiring a web-component's behaviour onto `@keenmate/web-components-core` — `BlissElement` + the `static inputs` table (`toBool` modes, dead defaults), before-callbacks, actions / menus / positioning, loaders, logging, forms, search, **scrolling inner elements into view (`scrollIntoContainer`, `beforeScrollCallback`)**, e2e on `test/` fixtures, svelte parity copies | [core-adoption.md](./core-adoption.md) → [.decisions](./core-adoption.decisions.md) → implement → [.checks](./core-adoption.checks.md) *(web-components; Svelte: parity only)* |
| Scaffolding or editing a component's `/publish` slash-command (release flow: pre-checks, version resolution, CHANGELOG / README handling, commit) | [publish-command.md](./publish-command.md) → implement → [.checks](./publish-command.checks.md) |
| Adding or changing examples on a component's example site (`examples-*.html`) — the permanent `TH07`-style section code on every example `<h2>` | [example-pages.md](./example-pages.md) → [.decisions](./example-pages.decisions.md) → implement → [.checks](./example-pages.checks.md) |
| Looking for a concrete worked example | [example-web-player.md](./example-web-player.md) |

If the task touches more than one topic, read every applicable `.md` before
you start, walk every applicable `.decisions.md` to scope the work, and run
every applicable `.checks.md` before declaring done.

**Starting a brand-new component?** Run the intake first
(`component-intake.md`, or `/new-component`) to lock down technology,
package identity, and CSS prefix. Then read in order:
`component-structure.md` → `naming-conventions.md` → `css-structure.md`
→ `theme-container.md` → `base-variables.md` → `color-scheme.md` →
`core-adoption.md` (web-components) → `readme-structure.md` →
`responsive-overlay.md` (panel-opening components) →
`example-web-player.md`. The ordering mirrors
how you'd actually build the component: intake first; then
architecture (layers / classes / interfaces); then naming (tag /
attributes / callbacks / events); then CSS (file layout, root
container scope, variables, dark-mode overrides); then external
documentation (slim README + `docs/` split); then, for web-components,
distribution (`custom-elements-manifest.md` — the Custom Elements
Manifest and editor tooling that make the package discoverable). The
CEM step slots in just before `/publish`, since the manifest is a
build/pack artifact the release flow ships.

---

## Mandatory checklist before declaring a web component "done"

Tick every box, or document the exception in a `## Known limitations` section
of the component's README.

### Component structure
- [ ] Element layer (`MultiSelectElement` etc.) is a thin I/O wrapper
      with no business state. See `component-structure.md`.
- [ ] Logic class is framework-agnostic (no `'svelte'` / `'react'` /
      `'vue'` runtime imports). Svelte 5 runes inside a `.svelte.ts`
      file are allowed.
- [ ] Service classes don't import each other; the Logic class brokers
      cross-Service calls.
- [ ] Side-layer files (`types.ts`, `logger.ts`, helpers) don't import
      from the Element / Logic / Service layers.
- [ ] No Manager layer unless it coordinates two or more Logic classes
      (Bliss "Management only if adds value" rule).
- [ ] TS interface suffixes from the closed set
      (`Config` / `EventDetail` / `Context` / `Spec` / none).
- [ ] No premature interfaces (`IFoo` with one implementation).

### Naming conventions
- [ ] Custom-element tag is hyphenated and family-prefixed
      (`<web-multiselect>`). See `naming-conventions.md`.
- [ ] Custom-element tag agrees with `customElements.define`.
- [ ] CustomEvent names are bare lowercase strings (`'select'`,
      `'change'`) — no `on*` prefix, no `Event` suffix.
- [ ] Boolean config fields use `is*Shown` / `is*Enabled` / `should*` /
      `is*` / `has*` / `can*`; attributes are derived mechanically
      (`show-x`, `enable-x`, `x`, `disabled` / `readonly` / `multiple`)
      and match the other components for the same concept (D-NC-15).
- [ ] Events are `<state>-change` (whole new state) or `<domain>-<verb>`,
      1–2 words; `change` only for the form value (D-NC-18).
- [ ] Events (return ignored — fire-and-forget) use `on*` and/or a bare
      `CustomEvent`. `on*` is reserved for event twins; `*Callback` is
      **reserved** for functions whose return value the component uses
      (plus options-bag notification hooks, D-NC-26).
- [ ] Callbacks (return consumed): interceptors use `before*Callback`;
      data extractors use `get*Callback` paired with a same-stem `*Member`;
      behavior providers use plain `*Callback`. One `ctx`, never
      positional.
- [ ] Public verbs follow the verb glossary (D-NC-13); state is a
      same-named property on element and controller, `get*()` only for
      lookups (D-NC-14).
- [ ] Enum values kebab-case; "off" is `'none'` (D-NC-25); form
      components have `disabled` + `readonly` (D-NC-16); `name`,
      `multiple`, `cssClass`, `::part(container)`, `labels` (D-NC-24,
      D-NC-27).
- [ ] One input table drives `observedAttributes`, initial parsing,
      and attribute changes — today core's `static inputs` on
      `BlissElement` (web-components only; see `core-adoption.md`).
- [ ] Internal methods use `handle*`; stored listener / callback
      references use `*Handler`.
- [ ] No magic strings inline — event names, attribute names, log
      categories live in top-of-file constants.

### CSS structure
- [ ] CSS folder follows the canonical file set (Tier 1 + Tier 2 always
      present; empty Tier-2 files have a stub comment). See `css-structure.md`.
- [ ] `main.css` declares `@layer variables, component, overrides;` and every
      `@import` specifies its layer.
- [ ] No underscore-prefixed file names (legacy SASS convention).
- [ ] BEM convention used for all class names.

### Theme container
- [ ] All `--<prefix>-*` variables declared on the container (`:host` for
      web-components, `.<prefix>-container` for Svelte) — never on
      `:root` / `html` / `body`. See `theme-container.md`.
- [ ] One of: container paints its own default background via
      `background: var(--<prefix>-bg, …)` (composite components), OR a
      named internal element (e.g. `.<prefix>__input`) paints and the
      README's Theming section documents the wrapper-host pattern
      (form-control components), OR the README documents intentional
      transparency (inline-style atoms). See D-TC-3 in
      `theme-container.decisions.md`.
- [ ] No *bare* `color-scheme` declaration on the container.
      The conditional canonical rules (`:host([data-context-theme])` /
      `:host([data-theme])`; Svelte `.<prefix>-container[...]`) are fine — see
      "The canonical block" in `color-scheme.md`.
- [ ] `display: block` (or documented `inline-block`) on the container.
- [ ] `position: relative` on the container — unless every floating
      panel uses `position: fixed` AND in-flow `position: absolute`
      descendants anchor to an internal positioned wrapper (the
      fixed-floating-UI exception in C-TC-8 / D-TC-6).
- [ ] Per-instance `data-theme="dark"` / `="light"` selectors exist and
      set a symmetric variable set.
- [ ] Svelte components: `theme` prop exposed and forwarded to
      `data-theme` on the container.

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
- [ ] No *bare* `:host { color-scheme: ... }` declaration — that
      shadows the page's inheritance for every instance. Conditional
      `:host([data-theme="dark"]) { color-scheme: dark }` (Strategy B)
      is fine and often preferred.
- [ ] `:host([data-context-theme="dark"|"light"])` map core's page / `theme-source`
      signal onto `color-scheme` (no `:host-context()`, no `prefers-color-scheme`).
- [ ] `:host([data-theme="dark"])` / `:host([data-theme="light"])` provide
      per-instance override.
- [ ] At least one Playwright spec asserts WCAG contrast in dark mode for the
      component's primary surfaces. Target ≥ 3:1 for non-text UI, ≥ 4.5:1 for
      body text.
- [ ] Tooltips (and any other surfaces portaled outside the
      container — popovers, dropdowns rendered to `document.body`)
      invert correctly in dark mode. Custom in-shadow tooltips chain
      through `var(--<prefix>-tooltip-*, var(--base-tooltip-*,
      light-dark(…)))`; portaled tooltips receive `data-theme` from
      the container at open time (or read `--base-tooltip-*`
      directly). See C-CS-10.

### Documentation
- [ ] `README.md` is a slim landing page (≤ 400 lines, target 200) — it
      covers what / what's-new / demos / install / one quick-start
      snippet / license, and links into `docs/`. See
      `readme-structure.md`.
- [ ] `docs/` folder exists with `usage.md`, `theming.md`,
      `examples.md`, and (unless D-RS-2 = B) `accessibility.md`. The
      README's "Demos & docs" section links each one via a relative
      path.
- [ ] `docs/theming.md` is the single home of the theming contract —
      container (C-TC-11), variables (C-BV-8), color-scheme (C-CS-8),
      cascade layers (C-CSS-10). The README no longer carries those
      sections.
- [ ] `docs/usage.md` covers every public attribute / prop, event /
      callback, slot, and imperative method (incl. the
      `ATTRIBUTE_TABLE` for web-components).
- [ ] `docs/accessibility.md` covers keyboard navigation, ARIA
      roles/states, focus management (N/A for purely display
      components per D-RS-2).
- [ ] CHANGELOG entry for the version that lands the theming work.

### Distribution & discoverability (web-components only)
- [ ] Ships a Custom Elements Manifest (`custom-elements.json`)
      generated by `@custom-elements-manifest/analyzer`, regenerated by
      the build. See `custom-elements-manifest.md`.
- [ ] `package.json` has the `customElements` field (→ the manifest)
      and the `web-types` field (→ `web-types.json`); `keywords`
      include `web-components` + `custom-elements`.
- [ ] Editor autocomplete files ship: `vscode.html-custom-data.json`
      (VS Code) and `web-types.json` (JetBrains), both derived from the
      manifest.
- [ ] All three artifacts are listed in `files` so they reach the npm
      tarball; the manifest is fresh (re-running `cem analyze` yields no
      diff).
- [ ] Public-facing members carry harvestable `/** */` JSDoc (not bare,
      not inline `//`) so autocomplete has hover text; enum members use
      the canonical intro-line + blank-line + bullet-per-value format.
- [ ] (N/A for Svelte / light-DOM components — D-CEM-1 = B.)

### Responsive overlay (panel-opening components only)
- [ ] Phone (≤ 600px) presents the panel **edge-to-edge full-screen**;
      tablet & desktop keep the anchored floating panel. Switched by a
      single `@media (max-width: 600px)` block. See `responsive-overlay.md`.
- [ ] Full-screen sizing uses `dvh`/`dvw`, never `vh`/`vw` (the bottom of
      the list / the Done button must not hide behind the mobile URL bar).
- [ ] The JS positioning engine **yields** to the full-screen media query
      — either `!important` on the full-screen geometry (D-RO-5 = A) or a
      `matchMedia` skip in the engine (D-RO-5 = B).
- [ ] An **explicit** close affordance (✕ / Done) exists in full-screen,
      plus Esc + hardware-back. Backdrop-only dismissal is not enough.
- [ ] Touch targets ≥ 44px (`--base-touch-target-min`), scroll container
      has `overscroll-behavior: contain`, full-screen chrome pads with
      `max(base, env(safe-area-inset-*))`.
- [ ] `docs/usage.md` documents the phone behavior and the two consumer
      viewport-meta duties (`interactive-widget=resizes-content`,
      `viewport-fit=cover`).
- [ ] (N/A for fully-inline components with no floating panel — D-RO-1 = B.)

### Core adoption (web-components only)
- [ ] Extends `BlissElement`; every public input is a row in `static inputs`;
      no own `observedAttributes` / `attributeChangedCallback`. See
      `core-adoption.md`.
- [ ] Every `toBool` names its mode; `'presence'` only on `disabled` /
      `readonly`; no `invalid input table` warning in the console.
- [ ] Inner elements are revealed with `scrollIntoContainer()`, never
      `scrollIntoView()`; a component that scrolls on its own exposes
      `beforeScrollCallback` (documented, demoed, tested).
- [ ] `before*Callback`s run through `runBeforeCallback*`; buttons via
      `/actions`, menus via `openMenu`, floating UI via `/positioning`
      (no direct `@floating-ui/dom`), loaders via `renderLoader`, search
      via `/search`.
- [ ] No `console.*` in component source (instance loggers only).
- [ ] e2e specs drive `test/` fixture pages, never `examples-*.html`
      (except the smoke spec).
- [ ] Every non-core copy of a core algorithm has a `docs/parity.md` row.
- [ ] `./core-adoption.checks.sh <package>` passes.

### Example pages
- [ ] Every example `<h2>` starts with a section code — `TH07 · Title`
      (page prefix + two-digit number); a plain `Summary` is exempt.
      See `example-pages.md`.
- [ ] Each prefix belongs to one page; no code is used twice.
- [ ] No code was renumbered or reused — new examples take the next
      free number, deleted codes are retired.

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
- **`data-context-theme`** — the host attribute core writes with the page / `theme-source`
  scheme (`dark` / `light`). It replaced `:host-context()` (unsupported in Firefox) for theme
  signals; see color-scheme.md.

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
- `packaging.md` — `dist/` layout, package.json `exports` field, CDN-friendliness. (The Custom Elements Manifest slice of packaging — the `customElements` / `web-types` fields, the tarball artifacts, webcomponents.org discoverability — is already covered by `custom-elements-manifest.md`; `packaging.md` would pick up the rest.)
- `svelte-component-shell.md` — the Svelte-specific equivalent of
  `theme-container.md`, expanded with SSR / hydration / stores notes once
  we have more than two Svelte components in the suite

If you're starting work in one of those areas and the file doesn't exist yet,
ask the user before inventing your own convention.
