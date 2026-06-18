# Light / Dark Color Scheme — Web Component Guideline

How a custom-element library should detect and react to dark mode so it works
correctly across OS preferences, page-level settings, framework theme switches,
and per-instance overrides — without surprises.

This is a living doc. Update it when a new framework convention emerges or when
we find a foot-gun the current pattern doesn't catch. See
[theme-container.md](./theme-container.md) for *where* the dark-mode
overrides described below must anchor (the short answer: on the
component's container — `:host` for web-components,
`.<prefix>-container` for Svelte).

---

## TL;DR

> **Use `light-dark()` in CSS variable fallbacks AND honor framework
> class signals on ancestors AND per-instance attributes on the host.
> *Never* declare a bare `:host { color-scheme: ... }` — but a
> conditional `:host([data-theme="dark"]) { color-scheme: dark }` is
> not just allowed, it's often the cleanest dark-mode implementation
> (Strategy B below).**

If you do nothing else, do that.

---

## The five signals a library has to react to

A custom element can be asked to render in dark mode from five different
directions. A robust library catches all five — but the mechanisms differ.

| # | Signal | Set by | Mechanism to catch it |
|---|--------|--------|------------------------|
| 1 | **OS / device preference** | macOS, Windows, iOS, Android setting | `@media (prefers-color-scheme: dark)` — or `light-dark()` if `color-scheme` is declared anywhere up the chain |
| 2 | **Browser-forced scheme** | Browser DevTools, forced-colors accessibility mode | Same as #1 |
| 3 | **Page-level `color-scheme`** | App author writing `body { color-scheme: dark }` or `<meta name="color-scheme">` | `light-dark()` resolves the dark branch via inheritance |
| 4 | **Framework theme class** | Bootstrap `[data-bs-theme="dark"]`, Tailwind `.dark`, Pure Admin, MUI, etc. | `:host-context([data-bs-theme="dark"])`, `:host-context(.dark)`, etc. |
| 5 | **Per-instance override** | App author writing `<my-component data-theme="dark">` on a single instance | `:host([data-theme="dark"])` |

### Precedence (highest specificity wins)

```
per-instance override  →  framework class  →  page color-scheme  →  OS preference
```

This is what users expect: a `data-theme="dark"` attribute on a specific
component instance should override the page theme; the page theme should
override OS preference.

---

## The CSS pattern

The pattern below catches all five signals. Adapt the variable names and color
values to your component, but keep the *structure*.

```css
/* ============================================================================
   :host defaults — handles signals #1, #2, #3 via light-dark()
   ============================================================================
   DO NOT declare `color-scheme` here. It looks tempting (it makes light-dark()
   resolve inside the shadow root), but it BLOCKS the page's `body { color-
   scheme: dark }` from inheriting into the shadow root. Let inheritance work. */
:host {
  --my-bg:     var(--base-main-bg,        light-dark(#ffffff, #1a1a1a));
  --my-text:   var(--base-text-color-1,   light-dark(#242424, #f5f5f5));
  --my-border: var(--base-border-color,   light-dark(#e0e0e0, #3d3d3d));
  --my-hover:  var(--base-hover-bg,
    color-mix(in srgb, var(--my-text) 8%, var(--base-main-bg, light-dark(#ffffff, #1a1a1a))));
}

/* ============================================================================
   Framework theme classes — handles signal #4
   ============================================================================
   Many modern frameworks (Bootstrap 5.3+) DO set color-scheme alongside their
   theme class, in which case the light-dark() rules above would already
   resolve correctly. These selectors are a safety net for:
     - older framework versions
     - hand-rolled theme toggles that flip a class but forget color-scheme
     - frameworks that just don't set it (Tailwind's `.dark` is class-only) */
:host-context([data-theme="dark"]),
:host-context([data-bs-theme="dark"]),
:host-context(.dark) {
  --my-bg:     #1a1a1a;
  --my-text:   #f5f5f5;
  --my-border: #3d3d3d;
}

/* ============================================================================
   Per-instance override — handles signal #5
   ============================================================================
   Lets an app force ONE component instance to render differently from the
   surrounding page. Useful for dark-themed widgets on light pages and vice
   versa. */
:host([data-theme="dark"]) {
  --my-bg:     #1a1a1a;
  --my-text:   #f5f5f5;
  --my-border: #3d3d3d;
}

/* ============================================================================
   Explicit LIGHT override
   ============================================================================
   So an app on a dark page can force ONE widget back to light, and so the
   framework-class blocks can be undone at a more specific scope. */
:host([data-theme="light"]),
:host-context([data-theme="light"]),
:host-context([data-bs-theme="light"]),
:host-context(.light) {
  --my-bg:     var(--base-main-bg,      #ffffff);
  --my-text:   var(--base-text-color-1, #242424);
  --my-border: var(--base-border-color, #e0e0e0);
}
```

### Why `light-dark()` instead of more `@media (prefers-color-scheme)` blocks?

`light-dark(<light>, <dark>)` is a built-in CSS function. It resolves the
correct branch based on the nearest declared `color-scheme`. So:

- If the page sets `body { color-scheme: dark }` → dark branch wins.
- If no one declares `color-scheme` but OS is dark mode → still light branch
  wins. *This is correct behavior* — the OS preference alone is not enough to
  flip the page; the page has to opt in by declaring `color-scheme: light dark`
  or `color-scheme: dark`.
- A consumer who wants OS-aware behavior writes once at the root: `html {
  color-scheme: light dark; }`. After that, `light-dark()` in your fallbacks
  picks the OS branch automatically.

This is cleaner than maintaining a parallel `@media (prefers-color-scheme:
dark)` block that *hardcodes* dark values and clobbers consumer overrides.

### Why `color-mix` for hover / active?

Hardcoded fallback hover colors (`#f0f0f0` for light, `#3a3a3a` for dark)
become invisible when the page's main background drifts away from white or
near-black. Mixing the text color into the main background by 8–14% gives a
highlight that always steps toward the text, so it stays visible at any base
background luminance.

```css
--my-hover-bg: var(--base-hover-bg,
  color-mix(in srgb, var(--my-text) 8%, var(--base-main-bg, light-dark(#fff, #1a1a1a))));
```

---

## Two strategies for framework-class & per-instance signals

The CSS pattern above shows variables being overridden inside each
signal selector — `:host-context([data-theme="dark"]) { --my-bg:
#1a1a1a; }`. That's **Strategy A**, and it's the conservative choice.
There's also **Strategy B**, where the signal selectors flip
`color-scheme` on the host instead of overriding individual variables.
Both are sanctioned; pick per component (D-CS-7).

### Strategy A — override variables in each signal selector

```css
:host {
  --my-bg:   var(--base-main-bg,      light-dark(#ffffff, #1a1a1a));
  --my-text: var(--base-text-color-1, light-dark(#242424, #f5f5f5));
}

:host-context([data-theme="dark"]),
:host-context([data-bs-theme="dark"]),
:host-context(.dark),
:host([data-theme="dark"]) {
  --my-bg:   #1a1a1a;
  --my-text: #f5f5f5;
}
```

The framework-class selectors set hardcoded dark values for each
variable, overriding the consumer's `--base-*` for the scope of the
signal.

**Pros:** Explicit. Easy to reason about ("dark mode means *these
exact colors*"). Works even if the consumer didn't wrap the page in
`color-scheme: dark`.

**Cons:** N variables × M signals = N×M overrides to keep in sync. A
consumer who set `--base-main-bg: #163768` on `:root` (their themed
dark) gets that value *replaced* by our `#1a1a1a` inside the signal
scope — silently. Our hardcoded value wins over their themed value
because we shadowed it.

### Strategy B — flip `color-scheme` in each signal selector

```css
:host {
  --my-bg:   var(--base-main-bg,      light-dark(#ffffff, #1a1a1a));
  --my-text: var(--base-text-color-1, light-dark(#242424, #f5f5f5));
}

:host-context([data-theme="dark"]),
:host-context([data-bs-theme="dark"]),
:host-context(.dark),
:host([data-theme="dark"]) {
  color-scheme: dark;
}

:host-context([data-theme="light"]),
:host-context([data-bs-theme="light"]),
:host-context(.light),
:host([data-theme="light"]) {
  color-scheme: light;
}
```

The signal selectors set `color-scheme: dark` on the host. The
`light-dark()` inside the `--my-bg` fallback then resolves to the
dark branch — at the same moment, in the same evaluation pass — but
*only if* the consumer hasn't set `--base-main-bg` to something else.
If they have, their themed value flows through untouched.

**Pros:** One declaration per signal — `color-scheme: dark` — instead
of N variable overrides. Consumer's `--base-*` remains the source of
truth: their themed dark colors keep applying. Smaller `dark-mode.css`
(multiselect's is ~60 lines for the same coverage that Strategy A
would take ~300 lines to express).

**Cons:** Requires every visible color in the component to chain
through a `light-dark()` fallback (which the guideline already
mandates — C-CS-2). If any variable hardcodes a single-mode literal,
that variable won't flip with the signal.

**Important constraint:** Strategy B only works because the
declaration is **conditional** — it fires only when the consumer has
explicitly signalled their intent. A *bare* `:host { color-scheme:
light dark }` would unconditionally shadow the page's inherited
`color-scheme` for every instance, which is the bug that multiselect
v1.10 → v1.11 fixed. See "Anti-patterns we've actually seen" #1.

### Which to pick

Default: **Strategy B**, *if* the component already follows the
fallback-chain discipline (`light-dark()` in every color fallback,
no hardcoded single-mode literals in feature files). The wins in
maintainability and consumer-theming respect are real.

Use **Strategy A** if:

- The component has hardcoded single-mode literals it can't easily
  remove (legacy code being incrementally migrated).
- The component needs dark-mode values that *don't* derive from
  `light-dark(<light>, <dark>)` — e.g., a dark-mode tint that uses a
  completely different hue rather than a darker version of the same
  hue.
- The team's mental model favors "dark mode = these literal colors"
  over "dark mode = flip the switch and trust the chain."

Reference implementations: **Strategy A** — web-grid (legacy);
**Strategy B** — `@keenmate/web-multiselect` v1.12.0-rc01+
(`src/css/dark-mode.css`, with a long explanatory comment block).

---

## Rules of the road

### Always

1. **Every visible color must be a CSS variable.** Never write
   `background: #1a1a1a` in a non-`:host` rule. Variables are the only way
   theme overrides flow through.

2. **Use `light-dark()` in fallbacks**, not just literal light colors.
   `var(--my-bg, light-dark(#fff, #1a1a1a))` is one extra character per
   declaration but gets you free OS-aware mode for any consumer who declares
   `color-scheme`.

3. **Provide a fallback chain**: `var(--base-X, var(--my-X, light-dark(...)))`.
   This lets theme designers (or a shared theme package like
   `@keenmate/theme-designer`) override at the `--base-*` level for ALL
   components at once, or at the component level for one component, or fall
   back to sensible defaults if nothing is set.

4. **Use `:host-context()` for ancestor matching.** Shadow DOM CSS cannot see
   light DOM elements with regular selectors. `:host-context(.dark)` is how a
   custom element reacts to a `<html class="dark">` ancestor.

5. **Use `:host([attr])` for per-instance overrides.** A `data-theme="dark"`
   attribute on the component itself is the highest-specificity override and
   the right escape hatch when an app wants one widget themed differently.

6. **Document the contract** in the README. Tell consumers what attributes,
   classes, and CSS variables you support. List the supported framework class
   conventions. Otherwise people will guess and get it wrong.

7. **Provide explicit LIGHT overrides too.** Apps sometimes need to force a
   single widget back to light on an otherwise-dark page. Without
   `:host([data-theme="light"])` and the like, the dark-mode blocks become
   unforceable.

8. **Test all five signals in CI.** A dark-mode test fixture that mounts the
   component on a dark page and asserts WCAG contrast ratios (≥ 3:1 for
   non-text UI, ≥ 4.5:1 for body text) catches theming regressions that
   visual smoke-testing misses. Web-grid's `e2e/dark-mode.spec.ts` is the
   reference implementation.

### Never

1. **Never declare a *bare* `color-scheme` on `:host`** — i.e., on
   the unqualified `:host` selector that fires for every instance
   regardless of theme signals. It looks tempting (it makes
   `light-dark()` inside the shadow root resolve), but it shadows
   the page's `body { color-scheme: dark }` from inheriting into the
   shadow root. The user ends up with a component that ignores the
   page's dark setting. This is the #1 footgun in this whole topic —
   multiselect ate this bug in v1.10 (declared `:host { color-scheme:
   light dark }`), the fix in v1.11 was removing the bare declaration.

   **Conditional declarations are different and allowed.** A
   `:host([data-theme="dark"]) { color-scheme: dark }` fires only
   when the consumer has explicitly signalled their intent — it
   amplifies their signal rather than fighting their page
   inheritance. That's Strategy B above and is the recommended
   pattern for components whose `--base-*` chains are all
   `light-dark()`-fallback'd. C-CS-1 enforces the bare-vs-conditional
   distinction.

2. **Never detect dark mode in JavaScript.** `window.matchMedia('(prefers-
   color-scheme: dark)')` works but is brittle: doesn't react to runtime
   changes without an explicit listener, doesn't see page-level
   `color-scheme`, doesn't see framework classes. CSS does all of this
   natively — use it.

3. **Never hardcode dark colors at the use site.** Any `background: #1a1a1a`
   that's not a `var(--...)` is a maintenance landmine. Two weeks from now,
   the theme designer changes the dark surface to `#1f1f1f` and one element
   doesn't update.

4. **Never assume `prefers-color-scheme` alone is enough.** Apps override OS
   preference all the time (Bootstrap theme toggles, Pure Admin layout
   settings, user-level prefs). The framework class and page `color-scheme`
   win over the OS.

5. **Never assume framework class auto-sets `color-scheme`.** Bootstrap 5.3+
   does, Tailwind does not, hand-rolled toggles often forget. Always have
   the `:host-context()` fallback.

6. **Never invert specific colors without inverting the system.** If you
   flip surface from light to dark, you have to also flip every color
   *layered* on top of it — text, borders, shadows, semitransparent tints.
   Use CSS variables consistently so the cascade does this for you.

---

## Testing strategy

For each of the five signals, you should be able to render the component in a
dark state and assert it looks correct.

```javascript
// e2e/dark-mode.spec.ts — minimal coverage matrix

describe('dark mode', () => {

  test('OS preference + color-scheme: light dark on root', /* ... */)
  // Sets <html style="color-scheme: light dark"> and emulates OS dark.
  // light-dark() should resolve to dark.

  test('body { color-scheme: dark }', /* ... */)
  // Sets <body style="color-scheme: dark"> on a light-OS page.
  // light-dark() should resolve to dark via inheritance.

  test('.dark class on body (Tailwind convention)', /* ... */)
  // No color-scheme declared. :host-context(.dark) should kick in.

  test('data-bs-theme="dark" on body (Bootstrap 5.3+)', /* ... */)
  // No color-scheme declared. :host-context([data-bs-theme="dark"]) should kick in.

  test('data-theme="dark" on the component itself', /* ... */)
  // Per-instance override. :host([data-theme="dark"]) should kick in.
})
```

For each case, compute the WCAG contrast ratio between rendered text and the
composited background. Assert ≥ 3:1 (non-text UI) or ≥ 4.5:1 (body text).
Helper code in `web-grid/e2e/dark-mode.spec.ts` is reusable — it handles
`color(srgb ...)` notation that browsers emit for `color-mix()` results and
walks the shadow-DOM ancestor chain to composite translucent backgrounds.

---

## Decision: how much explicit dark CSS should we keep?

There are three positions a library can take. We've taken position **(3)** for
new components and **(3)** for any component that previously shipped with
position (2).

| # | Strategy | Pros | Cons | When to use |
|---|----------|------|------|-------------|
| 1 | **`light-dark()` only** | Cleanest CSS, fewest lines, most modern | Misses framework classes that don't set `color-scheme`. Rare in 2026 but possible (Tailwind without explicit color-scheme line, hand-rolled toggles) | Greenfield component with a small/known consumer base |
| 2 | **Explicit `@media` + `:host-context()` overrides only** | Predictable, explicit, no light-dark() math to debug | No zero-config OS mode — consumer must set the theme class. Older convention. | Pre-`light-dark()` browser support requirements |
| 3 | **Belt-and-suspenders: `light-dark()` in fallbacks AND `:host-context()` overrides** | Catches every case in every consumer setup | More CSS to maintain. Light-dark() and explicit overrides can drift if not kept in sync. | Components with existing adoption (preserving prior behavior matters), or when consumer environments are heterogeneous |

If you're refactoring an existing component, prefer **(3)**. If you're starting
fresh and your audience is small enough to dictate conventions, **(1)** is
defensible.

---

## Anti-patterns we've actually seen

These are real bugs that have shipped. Don't repeat them.

1. **Bare `:host { color-scheme: light dark }`** — caused multiselect
   v1.10 to ignore the consumer page's `body { color-scheme: dark }`
   because the shadow root's own *unconditional* declaration shadowed
   the inherited one. Fix in v1.11: remove the bare declaration.
   Multiselect v1.12 then re-introduced `color-scheme` declarations
   *only on conditional selectors* (`:host([data-theme="dark"])`,
   `:host-context(...)`, etc.) as part of Strategy B — those fire
   only when the consumer has signalled and don't shadow page
   inheritance for unmarked instances.

2. **`@media (prefers-color-scheme: dark) { :host { --my-bg: #1a1a1a; } }` with
   no consumer override path** — caused web-grid to render dark when the OS
   was dark even on apps that explicitly forced light mode via
   `data-theme="light"`. The `@media` query's hardcoded values clobbered the
   consumer's `--base-*` variables. Fix: add an explicit `:host([data-theme=
   "light"])` block that restores the `--base-*` fallback chain.

3. **`background: #f5f5f5` written directly in a rule** — became invisible on
   dark themes because it wasn't a variable. Fix: convert every hardcoded
   color to `var(--my-X, light-dark(...))`.

4. **Hover color hardcoded as a flat light gray** — disappeared on dark themes
   (gray ≈ dark surface). Fix: `color-mix(in srgb, var(--my-text) 8%,
   var(--base-main-bg))` adapts to either mode.

5. **JS-based dark-mode detection that fired on `DOMContentLoaded`** — didn't
   react when the user switched OS theme mid-session. Fix: drop the JS, use
   CSS.

6. **Tooltip displays dark background + dark text in dark mode** —
   `@keenmate/web-grid`. The tooltip CSS reads
   `var(--wg-tooltip-bg)` / `var(--wg-tooltip-color)` and the
   variables are defined on `:host` with `light-dark()` literals
   as fallbacks. The dark-mode CSS uses Strategy B (conditional
   `color-scheme: dark` on `:host([data-theme="dark"])`). Yet the
   tooltip still rendered with the light-mode branch when the grid
   was in dark mode. The cause is subtle and varies by component;
   the three shapes it has taken across our codebase:
   - **Hardcoded literal in the tooltip rule.** Someone adds
     `color: #fff` or `background: #333` directly in the tooltip
     selector, shadowing the variable chain entirely. The script's
     auto sub-check catches this when tooltip CSS lives in a
     dedicated file; a grep at the [semi] tier catches the
     shared-file case (web-grid's tooltip rules live in
     `floating.css` alongside dropdowns and popovers).
   - **Variable chain anchored on a non-`light-dark()` literal.**
     `--<prefix>-tooltip-color: var(--base-tooltip-color, #000)`.
     The chain looks fine but the final fallback doesn't flip with
     `color-scheme`.
   - **Theme signal doesn't reach the tooltip element.** The
     tooltip is appended to a part of the DOM that doesn't inherit
     the host's `color-scheme` flip — usually because it's
     portaled to `document.body` to escape the container's
     `overflow` / stacking context. The portal element lives in
     light DOM and reads the consumer's page-level `color-scheme`,
     not the host's `[data-theme="dark"]` flip.

   See C-CS-10 for the matching check. The check enumerates the
   three tooltip kinds (in-shadow, portal-escaped, browser-native)
   and forces verification of the theme-propagation mechanism for
   each. Any component that portal-renders tooltips, popovers, or
   dropdowns to `document.body` has the same exposure as the third
   shape above.

---

## Reference implementations

- **`@keenmate/web-grid`** — full belt-and-suspenders pattern. See
  `packages/web-grid/src/css/_variables.css` (light-dark in fallbacks) and
  `packages/web-grid/src/css/_dark-mode.css` (framework-class overrides).
  Tests: `e2e/dark-mode.spec.ts` with 18 WCAG contrast assertions.
- **`@keenmate/web-multiselect`** — v1.11 was light-dark()-only.
  v1.12.0-rc01 added the framework-class + per-instance signal layer
  using **Strategy B** (conditional `color-scheme` flipping in
  `src/css/dark-mode.css` — ~60 lines for all four signals plus
  symmetric light selectors). The reference implementation for
  Strategy B.
- **`@keenmate/web-daterangepicker`** — being aligned with multiselect at the
  same time as this document was written.

---

## Open questions / future work

- Should we add a `:host-context([data-mui-color-scheme="dark"])` selector for
  MUI? Verify how MUI v6+ exposes color scheme to the DOM.
- Should we support `prefers-contrast: more` for high-contrast accessibility
  mode? Currently no component does.
- Should the dark-mode contrast suite be a shared helper rather than
  duplicated in each component's `e2e/`? Probably yes — extract once we have
  three+ components using it.
