# Core Adoption — Pre-Implementation Decisions

Answer every decision below **before** writing the component's behaviour. Each decision has a
recommended default; deviating from the default requires a one-line justification (README,
CHANGELOG, or PR description).

Read [core-adoption.md](./core-adoption.md) first if any of these questions don't make sense.

---

## D-CA-1 — Technology gate

**Question:** Is this a web component (custom element) or a Svelte component?

| Option | Implication |
|--------|-------------|
| **A. Web component** *(triad applies)* | Extend `BlissElement`; walk every decision below. |
| B. Svelte component | No core dependency. For every core algorithm it needs (scroll container, search normalization, …) keep a copy that behaves exactly like core's, and record each in `docs/parity.md`. Only D-CA-5 and D-CA-9 apply. |

---

## D-CA-2 — Input reactivity

**Question:** For each public input: does a change rebuild the component, patch it in place, or
change nothing visible?

| Option | When |
|--------|------|
| `on: 'reinit'` | structure changes (mode, columns, data shape) |
| **`on: 'update'`** *(default)* | in-place patch (labels, flags, callbacks the engine reads live) |
| `on: 'none'` | read only on demand (pure callbacks invoked later) |

**Default:** `update`; pick `reinit` only when an in-place patch would be wrong.

---

## D-CA-3 — Boolean inputs

**Question:** For each boolean: what does a missing attribute mean, and should `x="false"` be
false?

| Option | When |
|--------|------|
| **A. `toBool('default-false')`** *(default)* | the usual opt-in flag |
| B. `toBool('default-true')` | on unless switched off |
| C. `toBool('tristate')` | "not set" must reach the engine (null-clear contract) |
| D. `toBool('presence')` | **only** `disabled` / `readonly` (the browser reads them by presence) |

The row's `default` must match the mode (or be omitted).

---

## D-CA-4 — Form association

**Question:** Does the component carry a value a `<form>` should submit?

| Option | Implication |
|--------|-------------|
| A. Yes | `static formAssociated = true`; `name`; light-DOM hidden inputs; `disabled` reflects; `setFormatError()` when a value can't be produced. |
| **B. No** *(default for display / navigation components)* | Nothing. |

---

## D-CA-5 — Programmatic scrolling

**Question:** Does the component bring inner elements into view on its own — keyboard moves,
search / `scrollTo*()` jumps, reveal-on-open, after paste / drop?

| Option | Implication |
|--------|-------------|
| A. Yes | Reveal with `scrollIntoContainer()` (keyboard: `nearest`; jumps: `center` + `shouldRevealContainer: true`). Expose **`beforeScrollCallback`** — ctx: the item in component vocabulary, `source`, `container` (core's find, `null` = page), the options; run through `runBeforeCallbackSync` (`false` skips, options replace). Document it and demo it. |
| B. Only virtual-list scrolling | Scroll by index in the virtual list; still expose `beforeScrollCallback` if the jumps are user-visible. |
| **C. No** | Nothing — but no `scrollIntoView()` either. |

**Default:** decide by inspection; any keyboard-navigable list is A.

---

## D-CA-6 — Interceptable operations

**Question:** Which user operations should the app be able to veto or adjust (select, open,
navigate, drop, delete, scroll, …)?

**Default:** every operation that changes the value or the user-visible state gets a
`before*Callback`, run through `runBeforeCallback*`. Buttons / toolbars go through `/actions`
(`beforeActionCallback` covers them).

---

## D-CA-7 — Floating UI

**Question:** What floats — tooltips, a dropdown panel, a context menu, nothing?

| Need | Core |
|------|------|
| tooltip | `createTooltip` |
| dropdown / panel | `createPopover` (+ `resolvePresentation` for phone, see responsive-overlay) |
| context / dropdown menu | `openMenu` |
| custom anchoring | `anchor` |

**Default:** none. Never import `@floating-ui/dom` directly.

---

## D-CA-8 — Loading states

**Question:** Which states load asynchronously (initial data, search, lazy children, upload)?

**Default:** each one calls `renderLoader()` with its own `context` name, documented in the
component's docs; the component exposes `renderLoadingCallback`.

---

## D-CA-9 — Search

**Question:** Does the component filter or highlight by user-typed text?

| Option | Implication |
|--------|-------------|
| A. Yes | `/search` (`search-behavior`, `search-match`, highlight ranges). Svelte: a parity copy. |
| **B. No** | Nothing. |

---

## D-CA-10 — Missing core capability

**Question:** Does the component need shared machinery core doesn't have?

**Default:** surface it (a core issue / SPEC section, "used by …") and build it in core first.
A private helper is acceptable only as a short-lived step with a TODO pointing at the core issue.
