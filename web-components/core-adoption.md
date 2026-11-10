# Core Adoption — Web Component Guideline

What a Keenmate web component must take from **`@keenmate/web-components-core`** instead of
writing its own. Core exists because five components re-implemented the same plumbing and drifted
apart; every private copy is a future inconsistency. This guideline is the "behaviour" sibling of
the CSS / naming / docs guidelines: it says *which shared machinery a component wires in*, and
which component-level hooks (callbacks, options) it must expose on top.

The source of truth for core's behaviour is core's `docs/SPEC.md` (section numbers below); this
file only says what a component must do with it.

Cross-references:
- [naming-conventions.md](./naming-conventions.md) — names of callbacks / events / booleans
  (`before*Callback`, `is*` / `should*`, the `ctx` rules). This file says *when* a component needs
  them; that one says *how they're named*.
- [component-structure.md](./component-structure.md) — the Element layer is the `BlissElement`
  subclass described here.
- [responsive-overlay.md](./responsive-overlay.md) — the phone presentation of a panel; core's
  `resolvePresentation` / `lockBodyScroll` / `observeKeyboardInset` implement its mechanics.
- [example-pages.md](./example-pages.md) — example pages; the e2e rule here (fixtures, not
  examples) is about tests.

**Svelte components** don't depend on core (light DOM, no custom element). They keep their own
copies — but each copy must follow core's algorithm exactly, and the pairing is recorded in the
component's `docs/parity.md`. The checks below are web-component only unless marked.

---

## TL;DR

> **Extend `BlissElement` and declare every public input in its one `static inputs` table. Use
> core for everything it already does — before-callbacks, actions, menus, positioning, loaders,
> scrolling, logging, search, forms, responsive rules, theme. Never `scrollIntoView()`, never a
> bare `toBool()`, never `console.*`, never a private floating-ui wrapper. If the component
> scrolls on its own, it offers `beforeScrollCallback`. Tests run on `test/` fixture pages.**

---

## The map: need → core API

| The component needs to… | Use (core) | Component adds | SPEC |
|---|---|---|---|
| Expose attributes / properties / callbacks | `BlissElement` + `static inputs` (`InputDef` rows, `to*` converters) | nothing else — no own `observedAttributes` / `attributeChangedCallback` / parse switch | §4–§6 |
| Rebuild vs patch on a change | `on: 'reinit' \| 'update' \| 'none'` per row; `reinit()` / `update(partial)` hooks | the two hooks | §6, §11.3 |
| Start / stop live resources | `connect()` / `disconnect()`; `destroy()` / `destroyCallback()` | the hooks | §6.5 |
| Hold the first build | `defer` / `release()` / `whenReady()` (built in) | nothing | §6.3 |
| Read back after a write | `whenSettled()` (async), `this.flush()` at the top of imperative methods | `flush()` calls | §12.7 |
| Fire events | `this.emit()` + the event table (`on<Name>` twins) | the event table | §12.5 |
| Let the app veto / adjust an operation | `runBeforeCallback` / `…Eager` / `…Sync` (`false` cancels, a value replaces) | the `before*Callback` input + its `ctx` | §12.12 |
| Buttons, toolbars, `data-action` triggers | `/actions` — `runAction`, `resolveActionItem`, `normalizeActionItems` | the item list input | §12.12 |
| Context / dropdown menus | `/menu` — `openMenu(entries, ctx, opts)` | the entries | §12.13 |
| Tooltips, popovers, anchored panels | `/positioning` — `createTooltip`, `createPopover`, `anchor` (never import `@floating-ui/dom` yourself) | placement options | §12.2 |
| Phone / tablet presentation of a panel | `resolvePresentation`, `lockBodyScroll`, `observeKeyboardInset` | the `presentation` input | §12.9 |
| Device / viewport / own-size reactions | `getEnvironment`, `observeEnvironment`, `observeViewport`, `observeElementSize`, `environmentChanged()` | the reaction | §12.9 |
| Per-device config | Responsive rules (`responsive`, `responsiveCallback`, page / per-tag maps) — automatic for every input | nothing (don't add own breakpoint inputs) | §6.7 |
| Dark / light | `data-context-theme` on the host (automatic), `theme-source` | CSS on `:host([data-context-theme=…])` | §12.10 |
| Loading states | `renderLoader(host, container, context, { label, prefix })` | `renderLoadingCallback` input + `.<prefix>-loader` CSS | §12.14 |
| **Bring an inner element into view** | **`scrollIntoContainer(el, opts)` / `findScrollContainer(el)`** | **`beforeScrollCallback` when the component scrolls on its own** | §12.15 |
| Search box / filtering / highlight | `/search` — `normalizeSearchText`, `prepareSearchTerm`, `matchesSearchTerm`, `findHighlightRanges` | `search-behavior` / `search-match` inputs | §12.11 |
| Logging | Instance loggers (`createLoggers`, `registerComponent`), core's `coreLog` | categories | §12.1 |
| Form participation | `static formAssociated`, `el.form`, `isEffectivelyDisabled`, `disabledChanged()`, `setFormatError()`, validity | light-DOM hidden inputs for the value | §6.4, §6.6 |
| Shadow-root CSS | `adoptStyles`, `createStyleSlot` (for `customStylesCallback`) | the CSS | §12.8 |
| Page-wide registration | `registerComponent()` (`window.components[tag]`) | the call | §12.3 |
| Editor metadata | `/cem` analyzer plugins (`blissAnalyzerConfig`, `withCoreDeclared`) | JSDoc on inputs | §12.6 |

---

## Inputs: one table, explicit converters

- Every public input is one `InputDef` row. A new input type is a new converter, never a branch
  in a switch.
- **`toBool(mode)` always names its mode** (core requires it since 1.0.0-rc16):
  - `'default-false'` — the usual flag; `x="false"` is `false`.
  - `'default-true'` — on unless switched off.
  - `'tristate'` — `null` = not set, the engine decides (null-clear contract).
  - `'presence'` — the native-HTML rule, ANY value is `true` (`x="false"` too). **Only for
    `disabled` / `readonly`**, where the browser itself reads the attribute by presence.
- A row's `default` must agree with what the converter returns for a missing attribute (or the
  converter returns `undefined` / `null`). Core warns `invalid input table: … the default never
  applies` otherwise — a page that logs it is failing C-CA-3.
- `isDisabled` (attribute `disabled`) **reflects** on a form-associated component.

## Scrolling: one container, never the page

`Element.scrollIntoView()` scrolls every scrollable ancestor, the page included — a search jump
or an arrow key makes the whole page jump. Components reveal inner elements (a row, an option, a
day) with core's **`scrollIntoContainer(el, { block, inline, behavior, container?,
shouldRevealContainer? })`**: it scrolls only the nearest real scroll container (across shadow roots and
slots), honours `scroll-padding` / `scroll-margin` (so a sticky header is a CSS matter), and with
no container hands the same request to the page.

- **Keyboard moves:** `block: 'nearest'`, `behavior` from the component's
  `--<prefix>-scroll-behavior` token (instant under reduced motion).
- **Jumps** (search hit, `scrollToX()`, reveal-on-open): `block: 'center'` and
  `shouldRevealContainer: true`, so a component further down the page is brought into view too.
- **Virtual lists** scroll by index themselves; the helper is for real DOM elements.
- **`beforeScrollCallback`** — a component that scrolls *on its own initiative* (keyboard,
  search, paste, reveal-on-open, `scrollTo*()` methods) exposes it:
  `beforeScrollCallback(ctx)` with the component's own vocabulary (the item / node / option,
  `source: 'keyboard' | 'search' | …`), the `container` core found (`null` = the page) and the
  options it is about to use. Run it through `runBeforeCallbackSync`: `false` skips the scroll,
  returned options replace the defaults. It does not exist in core — `ctx` is component vocabulary.

## Before-callbacks, actions, menus

- Every `before*Callback` runs through core's `runBeforeCallback*` — never a hand-rolled
  `if (cb(ctx) === false)`. Same cancel / replace / async semantics everywhere.
- Buttons and toolbars are `ActionItem`s through `/actions` (`runAction` order:
  `beforeActionCallback` → item `onClick` → built-in → `action` event).
- Context and dropdown menus are `openMenu()`; the component supplies entries, not a menu.

## Loading, logging, search, forms

- Loading states call `renderLoader()` with a per-state `context`; the component exposes
  `renderLoadingCallback` and draws `.<prefix>-loader` from the shared `--base-loader-*` tokens.
- No `console.*` in component source — loggers only, so `window.components.logging` and
  `disableLogging()` silence everything.
- A search box uses `/search`; never a private `toLowerCase()` + `includes()`.
- A form value is submitted through light-DOM hidden inputs (not `setFormValue`); `el.form`,
  disabled and validity come from core.

## Tests: fixtures, not examples

e2e specs drive dedicated minimal pages under `test/` (one per feature area, styled by a
`test-fixtures.css`, no example chrome). Example pages are for humans; the only spec allowed to
open them is a smoke test (pages load, elements defined). A `test/COVERAGE.md` maps features to
specs. Use `whenSettled()` (or core's `/testing` helpers) instead of timeouts for read-after-write.

---

## Rules of the road

### Always
- Extend `BlissElement`; declare inputs in `static inputs`; react in `reinit()` / `update()`.
- Define the tag through core's `registerComponent(tag, Class, { config, … })` — no own guarded
  `customElements.define` (the rulebook's tag checks recognise either; C-CST-2 / C-NC-1 / C-TC-15 / C-CEM).
- Name the `toBool` mode; keep `default` consistent with the converter.
- Reveal with `scrollIntoContainer()`; offer `beforeScrollCallback` if you scroll on your own.
- Route `before*Callback`s through `runBeforeCallback*`.
- Use `/positioning`, `/menu`, `/actions`, `/search`, `renderLoader` for what they cover.
- A data-input component (the user enters / changes data — value, selection, files, text, cells, a
  tree's checks / edits / moves) has the pair `isDisabled` + `isReadonly` (`disabled` / `readonly`,
  `toBool('presence')`, reflect), native semantics: disabled = no interaction, not focusable; readonly =
  no data change, still focusable / navigable / copyable (core SPEC §6.4). A show / launch component
  (command palette) has neither.
- Type the input properties with the one-line merge `export interface <Class> extends <ElementConfig> {}`
  (core `docs/usage.md`, C-CA-16).
- Offer custom CSS through `createCustomStyles()` exactly as core `docs/usage.md` shows (the two
  input rows, one handle, no `position`) — one implementation everywhere (C-CA-15). Every registered
  tag applies it (its class or its shared base class), not just one class of the package.
- Persist user-arranged UI state (a popover size, column widths / order) through core `createStateStore()`
  with the input rows `storageKey` (`storage-key`, unset = off), `loadStateCallback`, `saveStateCallback`
  (whole state) — core `docs/usage.md` → "Persisted UI state", SPEC §12.17. No own `localStorage` /
  `sessionStorage` code (C-CA-17).
- Record the svelte-side copy of any core algorithm in `docs/parity.md`.

### Never
- `scrollIntoView()` on an inner element.
- `toBool()` without a mode; `'presence'` on anything but `disabled` / `readonly`.
- `console.log/warn/error` in component source.
- `import … from '@floating-ui/dom'` in a component.
- A private copy of a core helper ("just a small `findScrollableAncestor`").
- Own `observedAttributes` / `attributeChangedCallback` / attribute parse switch.
- A core hook made public (`reinit()`, `update()`, `connect()`, `disconnect()`, `destroyCallback()`, the
  `*Changed()` hooks, …): overrides stay `protected`. Writing many inputs at once is core's public
  `el.setAttributes(props)` / `el.batch()`, never a component's own `el.update(props)` — that bypasses
  parsing, validation and `this.config`, so the next flush restores the old values (C-CA-14).
- e2e specs against `examples-*.html` (except the smoke spec).

When core lacks something, **surface the gap** (core issue / SPEC section) instead of working
around it in the component.

---

## Reference implementations

| Component | Shows |
|---|---|
| web-multiselect | inputs table, `/search`, `/positioning`, virtual scroll, form hidden inputs |
| web-daterangepicker | presentation (`resolvePresentation`, `lockBodyScroll`, keyboard inset), before-callbacks, actions |
| web-treeview | `/menu`, null-clear tristate inputs, scrolling (`scrollIntoContainer` + `beforeScrollCallback`, in progress) |
| web-components-core `examples-scroll.html` | native `scrollIntoView` vs `scrollIntoContainer`, sticky header, shadow / slot search, `shouldRevealContainer` |
