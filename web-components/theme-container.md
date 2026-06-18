# Theme Container — Component Guideline

> **Applies to both web-components and Svelte components.** The folder is
> called `web-components/` for historical reasons; the rules below cover
> *any* KeenMate / Bliss component that exposes a single root element to
> the DOM. Where the two technologies differ, the doc spells out the
> per-technology shape.

The *theme container* is the single DOM element that a component owns
and that everything in its theming model anchors to: the CSS variables,
the default background, the dark-mode overrides, the per-instance theme
attribute, the layout context (offsetParent, focus-within scope).

If the container is wrong — declared on `:root`, missing, or split
across multiple elements — every other rule in the theming stack
silently breaks for subtree theming. This guideline exists because we
hit that exact bug in `svelte-treeview` rc10 and the fix forced us to
formalize the pattern.

See also: [base-variables.md](./base-variables.md) for the variable
taxonomy, [color-scheme.md](./color-scheme.md) for the dark-mode
machinery, [css-structure.md](./css-structure.md) for the file layout
the variables live in.

---

## TL;DR

> **Every component has exactly one *theme container* — the element that
> owns its `--<prefix>-*` variables, paints its default background,
> carries the per-instance `data-theme` attribute, and gets the dark-mode
> overrides. For web-components that container is `:host`. For Svelte
> components it's a class on the component's outermost rendered element
> (e.g. `.ltree-container`, `.ms-container`). Variables MUST NOT live on
> `:root` or `html` — that scope can't be overridden per subtree, so
> consumer wrappers that set `--base-*` don't reach the component.**

---

## Why the container scope matters

A consumer page may need:

1. The component to render correctly **standalone** on a plain HTML page
   with no theming setup.
2. The component to pick up **OS dark mode** automatically.
3. The component to honor a **framework theme class** somewhere up the
   tree (`[data-theme="dark"]`, `.dark`, etc.).
4. The component to honor a **per-instance** dark/light override.
5. The component to be **themed differently in different subtrees** of
   the same page (one wrapper sets `--base-accent-color: red`, another
   sets `--base-accent-color: blue`, two instances of the same component
   render in two different colors).

(5) is the one most easily broken. If the component declares its
variables on `:root`, the `var(--base-accent-color, fallback)`
substitution is evaluated *at the document root*, where the wrapper's
`--base-accent-color: red` is not visible. The wrapper is a descendant
of `:root`, not an ancestor.

The fix is to declare the variables on the **component's own root
element**. That element *is* a descendant of every wrapper the
consumer might wrap it in, so the substitution resolves against the
wrapper's `--base-*` value as expected.

### The svelte-treeview rc10 migration

Concrete motivating example. Before rc10, svelte-treeview declared:

```css
:root {
  --ltree-primary: var(--base-accent-color, #0d6efd);
  /* ...all other --ltree-* tokens... */
}
```

A consumer who wrote:

```html
<div class="my-theme" style="--base-accent-color: red">
  <Tree ... />
</div>
```

…got an unchanged tree, because `--ltree-primary` was computed at `:root`
where `--base-accent-color` was still its fallback (`#0d6efd`).

rc10 rescoped the declarations to `.ltree-container`:

```css
.ltree-container {
  --ltree-primary: var(--base-accent-color, #0d6efd);
  /* ...all other --ltree-* tokens... */
}
```

Now `--ltree-primary` is computed at `.ltree-container` (a descendant of
`.my-theme`), and the wrapper's `--base-accent-color: red` flows through
the substitution as expected. Two trees on the same page can be themed
differently via two different wrappers.

**The web-component equivalent of `.ltree-container` is `:host`.**
Web-components have had this right since day one because `:host` is the
shadow boundary, which is necessarily a descendant of any consumer
wrapper.

---

## The container by component type

### Web components — `:host`

For custom elements (`<web-multiselect>`, `<web-grid>`, etc.), the
container is `:host`. That's the only sensible choice — there is no
other element accessible to both the shadow stylesheet and the consumer
tree.

```css
/* variables.css */
:host {
  --ms-rem: 10px;
  --ms-bg:           var(--base-main-bg,     light-dark(#ffffff, #1a1a1a));
  --ms-text-color-1: var(--base-text-color-1, light-dark(#242424, #f5f5f5));
  --ms-accent-color: var(--base-accent-color, #0078d4);
  /* ...rest of the --ms-* taxonomy... */
}
```

### Svelte components — `.<prefix>-container`

For Svelte components, the container is a class applied to the
**outermost rendered element**. The class name follows the prefix
registered in [base-variables.md](./base-variables.md):

| Component | Prefix | Container class |
|-----------|--------|-----------------|
| `@keenmate/svelte-treeview` | `ltree` | `.ltree-container` |
| `@keenmate/svelte-switch` | `sw` | `.sw-container` |
| (future Svelte component) | `<prefix>` | `.<prefix>-container` |

```svelte
<!-- Tree.svelte -->
<div class="ltree-container" data-theme={theme}>
  {#each nodes as node}
    <Node {node} />
  {/each}
</div>
```

```css
/* variables.css */
.ltree-container {
  --ltree-rem: 10px;
  --ltree-bg:      var(--base-main-bg,     light-dark(#ffffff, #1a1a1a));
  --ltree-primary: var(--base-accent-color, #0d6efd);
  /* ...rest of the --ltree-* taxonomy... */
}
```

**The container element must be a single root.** A Svelte component
that renders a fragment (`<a/>{#each}<b/>{/each}<c/>`) cannot host a
theme container — wrap it in a `<div class="<prefix>-container">`.

### Future component types

The pattern generalizes to any host technology that emits a single root
element (React, Vue, Blazor / C# Razor components, Elixir LiveView). The
rule is always the same: pick the component's outermost element, give
it a stable container class, anchor every theme rule there. Don't
attempt this guideline for technologies where a "component" expands to
unanchored fragments — fix the fragment problem first.

---

## What lives on the container

Every component's container declares the same five things:

```css
/* :host  for web-components             */
/* .<prefix>-container  for Svelte/light DOM */

:host /* or .<prefix>-container */ {
  /* 1. Layout sanity */
  display: block;
  position: relative;
  box-sizing: border-box;

  /* 2. The full --<prefix>-* variable set, reading through --base-* */
  --<prefix>-rem:           10px;
  --<prefix>-bg:            var(--base-main-bg,      light-dark(#ffffff, #1a1a1a));
  --<prefix>-text-color-1:  var(--base-text-color-1, light-dark(#242424, #f5f5f5));
  --<prefix>-accent-color:  var(--base-accent-color, #0078d4);
  /* ...etc. */

  /* 3. The component's default background */
  background: var(--<prefix>-bg);

  /* 4. The default text color so descendants inherit something sensible */
  color: var(--<prefix>-text-color-1);

  /* 5. The default font family / size */
  font-family: var(--<prefix>-font-family, var(--base-font-family, inherit));
  font-size:   var(--<prefix>-font-size-base);
}
```

### `display: block` — components must be visible

Custom elements and Svelte `<div>`s both default to inline-block /
inline behavior in unfortunate ways. Pin to `block` (or `inline-block`
if the component is genuinely inline) so width/height behave
predictably and the default background actually paints a surface.

### `position: relative` — offsetParent anchor

The container is the offsetParent for any absolutely-positioned
descendants (tooltips, popovers, dropdown chrome that floats inside
the component). It also scopes `:focus-within` and `:has()` queries
sanely. Always relative, unless either:

- The component is *intended* to escape its parent's stacking context, OR
- All floating UI panels (tooltips, popovers, dropdowns) use
  `position: fixed` (typical for Floating-UI-based components), AND
  any in-flow `position: absolute` descendants anchor to an
  internal `position: relative` wrapper (`.ms__input-wrapper`,
  `.wg__viewport`, etc.) — *not* to `:host` — so `:host` is never
  asked to be the offsetParent for anything.

In that second case, declaring `position: relative` on the container
is harmless but unnecessary. Multiselect's pattern: `.ms__input-wrapper
{ position: relative }` anchors the absolute `.ms__toggle` /
`.ms__counter`; every floating panel uses `position: fixed`; `:host`
has no positioned descendants needing it. C-TC-8 accepts both styles.

### `box-sizing: border-box`

Saves every internal rule from `width: calc(100% - 2 * var(--padding))`
gymnastics. Set it once on the container; descendants inherit via the
`* { box-sizing: inherit }` reset (which Tier-1 `base.css` should
include).

### The variable block

This is the same block documented in [base-variables.md](./base-variables.md).
The point of this guideline is to insist it lives **here**, on the
container, never on `:root`. See "Anti-patterns" below for the failure
modes.

### Default background

The container paints its own surface so the component is visible
standalone. This is non-obvious for web-components historically —
they've often relied on the page background showing through `:host`.
Don't. A component dropped into a transparent slot or popover should
still render with a visible surface.

There are three legitimate cases for what "default background" means
on a component (D-TC-3):

1. **Self-painted host** *(default)*. The container declares
   `background: var(--<prefix>-bg, …)`. Used by most composite
   components — grids, players, calendars, tree views.

2. **Intentionally transparent** — inline-style controls like a
   switch, a badge, a standalone icon button. The host lets the
   parent's background show through. Document the opt-out in the
   component README's "Theming" section.

3. **Wrapper-host with painted chrome** — form-control components
   where the visible surface is *one* internal element (typically
   the `<input>`-like chrome), not the host itself. The host is a
   layout wrapper; the chrome paints. The component is *not*
   invisible standalone — the chrome paints itself — but the host
   does not double-paint. Example: `@keenmate/web-multiselect` has
   no `:host { background }`; `.ms__input` paints
   `background: var(--ms-input-bg)` instead. Document in the README
   that this is a form-control component and the host is a
   transparent wrapper around the visible chrome.

For (1) the C-TC-2 check expects `:host { background: ... }`. For (2)
and (3) the check is satisfied by the documentation, not by a
declaration on the host.

### `color-scheme` — bare on `:host` is forbidden; conditional is fine

The rule the team learned the hard way (multiselect v1.10 → v1.11
fix): a **bare** `:host { color-scheme: ... }` (or
`.<prefix>-container { color-scheme: ... }`) shadows the page's
inherited `color-scheme` for *every* instance, breaking dark mode on
pages that set `body { color-scheme: dark }`. That bare declaration
is the #1 footgun and is forbidden.

```css
/* WRONG — bare, unconditional */
:host                 { color-scheme: light dark; }
.ltree-container      { color-scheme: light dark; }
```

However, a **conditional** declaration on `:host(...)` /
`:host-context(...)` / `.<prefix>-container[...]` / ancestor-class
selectors fires *only* when the consumer has explicitly signalled
dark or light. It amplifies the consumer's intent rather than
fighting their page inheritance. This is a legitimate, often
*cleaner* dark-mode strategy — see
[color-scheme.md](./color-scheme.md) → "Strategy A vs Strategy B."

```css
/* RIGHT — conditional, fires only when consumer signalled dark */
:host([data-theme="dark"]),
:host-context([data-bs-theme="dark"]),
:host-context(.dark) {
  color-scheme: dark;   /* amplifies the consumer's signal */
}
```

For the default `:host` block — the one that fires for *every*
instance regardless of theme — let `color-scheme` inherit. Use
`light-dark()` in CSS variable fallbacks instead:

```css
:host {
  --ms-bg: var(--base-main-bg, light-dark(#ffffff, #1a1a1a));
}
```

C-TC-4 enforces the bare-vs-conditional distinction.

---

## Dark mode at the container

The four signals from [color-scheme.md](./color-scheme.md) — OS
preference, framework class on an ancestor, framework class on the
container itself, per-instance `data-theme` — all flip variables on
the container. The exact selectors differ between web-components and
Svelte.

### Web components

```css
/* OS preference */
@media (prefers-color-scheme: dark) {
  :host {
    --ms-bg:            #1a1a1a;
    --ms-text-color-1:  #f5f5f5;
  }
}

/* Framework class on ANY ancestor (light DOM) */
:host-context([data-theme="dark"]),
:host-context([data-bs-theme="dark"]),
:host-context(.dark) {
  --ms-bg:            #1a1a1a;
  --ms-text-color-1:  #f5f5f5;
}

/* Per-instance attribute on the component element itself */
:host([data-theme="dark"]) {
  --ms-bg:            #1a1a1a;
  --ms-text-color-1:  #f5f5f5;
}

/* SYMMETRIC light selectors so a dark page can opt one instance back to light */
:host([data-theme="light"]) {
  --ms-bg:            #ffffff;
  --ms-text-color-1:  #242424;
}
```

### Svelte components

```css
/* OS preference */
@media (prefers-color-scheme: dark) {
  .ltree-container {
    --ltree-bg:            #1a1a1a;
    --ltree-body-color:    #f5f5f5;
  }
}

/* Framework class on any ancestor */
[data-theme="dark"]     .ltree-container,
[data-bs-theme="dark"]  .ltree-container,
.dark                   .ltree-container {
  --ltree-bg:            #1a1a1a;
  --ltree-body-color:    #f5f5f5;
}

/* Per-instance attribute on the container itself */
.ltree-container[data-theme="dark"] {
  --ltree-bg:            #1a1a1a;
  --ltree-body-color:    #f5f5f5;
}

/* SYMMETRIC light selectors */
.ltree-container[data-theme="light"] {
  --ltree-bg:            #ffffff;
  --ltree-body-color:    #242424;
}
```

The cascade order matters: list the most-specific selector last so a
per-instance `data-theme="light"` beats an ancestor `.dark`.

---

## Per-instance override

### Web components

The consumer sets `data-theme` on the custom element. No prop wiring
needed — the attribute lands directly on the host:

```html
<web-multiselect data-theme="dark">…</web-multiselect>
```

The `:host([data-theme="dark"])` selector picks it up.

### Svelte components

Expose a `theme` prop on the component and forward it to the container:

```svelte
<script lang="ts">
  export let theme: 'dark' | 'light' | null | undefined = undefined;
</script>

<div class="ltree-container" data-theme={theme || null}>
  …
</div>
```

The `{theme || null}` ensures `data-theme=""` doesn't render when the
prop is unset (an empty `data-theme` attribute would match neither
`[data-theme="dark"]` nor the absence-of-attribute, and is just noise
in the DOM).

Document the prop's three states in the README:
- `undefined` (default) — inherit from page (OS + framework class + ancestor `data-theme`).
- `"dark"` / `"light"` — force this instance.

---

## Portaled / floating UI escaping the container

Some components render UI **outside** their container — popovers,
tooltips, dropdowns that mount to `document.body` to escape `overflow:
hidden` or stacking-context traps. Those nodes are not descendants of
the container, so they don't see the container's CSS variables.

Two options:

**(a) Render the portal inside the container.** Use a wrapping div with
`position: fixed`, `inset: auto`, and explicit positioning math. The
node is still a DOM descendant of the container; theming flows through.
Preferred when feasible.

**(b) Mirror the relevant variables onto the portal's own root.**
Compute `--<prefix>-bg`, `--<prefix>-text-color-1`, `--<prefix>-accent-color`
etc. in JavaScript by reading `getComputedStyle(container).getPropertyValue(...)`,
and set them on the portal node at mount time. Brittle, but sometimes
necessary.

For web-components specifically: `@keenmate/web-daterangepicker`
declares its variables on `:host, :root` for exactly this reason — the
date picker's dropdown is a popover. The `:root` declaration is a
*safety net* for the portal case, not a replacement for `:host`. Do
not use the dual `:host, :root` declaration unless you actually have
escaped UI.

Document portal behavior explicitly in the component README — it's a
common source of "why doesn't my theme apply" support questions.

---

## Reading `--base-*` directly inside the container is fine; outside is not

This rule lives in [base-variables.md](./base-variables.md) (C-BV-9)
and gets reiterated here because it's a common container mistake:

```css
/* RIGHT — read --base-* inside the container's :host / .container block */
:host {
  --ms-accent-color: var(--base-accent-color, #0078d4);
}
.ms__button {
  background: var(--ms-accent-color);   /* reads the component-local var */
}

/* WRONG — read --base-* in a descendant rule */
.ms__button {
  background: var(--base-accent-color); /* skips the --ms-* layer */
}
```

The container is the only place `--base-*` reads happen. Everywhere
else reads `--<prefix>-*`. Two layers, never three.

---

## FOUC prevention — handling the pre-upgrade window (web-components only)

> Svelte components render light DOM directly; there's no upgrade
> phase and this section doesn't apply.

Between the moment the browser parses `<web-multiselect>` and the
moment JS calls `customElements.define(...)`, the element is an
*unknown element* — `:not(:defined)` matches it, the browser gives it
`display: inline` by default, and any child text (placeholder
attributes, declarative `<option>` children) renders unstyled. On
fast connections it's invisible but causes a layout shift when the
component upgrades and reserves its real footprint; on slow
connections users see the flash.

The canonical fix is a light-DOM rule in `base.css` (Tier-1
skeleton):

```css
/* base.css */
web-multiselect:not(:defined) {
  display: block;                              /* unknown defaults to inline */
  min-height: calc(3.5 * var(--ms-rem));      /* reserve post-upgrade height */
  color: transparent !important;               /* hide placeholder / child text */
  background: transparent;                     /* let page background show */
}
```

`min-height` matches the component's default rendered height so the
page doesn't reflow when it upgrades. `color: transparent !important`
hides any text content that might flash (`!important` because consumer
selectors may have higher specificity). The rule stops applying the
moment `customElements.define(...)` runs and the element becomes
defined.

### How a light-DOM rule reaches the host

`:host` only applies *inside* the shadow root, which doesn't exist
until upgrade — so it can't help here. The FOUC rule must target the
custom element by tag, in the light DOM. It reaches the host because
the component's entry point side-effect-imports `main.css`:

```ts
// src/index.ts
import './css/main.css';   // bundler injects <style> into the consumer document
```

If your component skips that import (loading CSS only via the shadow
root's inline injection), the FOUC rule has nowhere to land — add
the side-effect import alongside the `?inline` one.

### The tag-name trap

The tag in the CSS selector MUST equal the string passed to
`customElements.define(...)`. They live in separate files, nothing
links them, and renames break the link silently — the old selector
stops matching, FOUC reappears, the build is silent. Two real
failure modes:

- **Tag rename without CSS update.** `@keenmate/web-multiselect`
  carried `multi-select:not(:defined)` in `base.css` after renaming
  the registered tag to `web-multiselect` — dead rule, FOUC
  prevention silently broken from the rename onward.
- **CSS prefix mistaken for tag.** Don't write `ms:not(:defined)`;
  `ms` is the variable prefix, not the tag. Write the full registered
  tag name.

C-TC-15 catches both by comparing the tag in `base.css` to every
`customElements.define(...)` call in the TS source. D-TC-9 covers
*when* the rule should be present at all (default yes for visible-chrome
components, optional for inline atoms with no layout footprint).

---

## Anti-patterns

1. **Variables on `:root` / `html` / `body`.** Subtree theming breaks
   (the svelte-treeview rc10 bug). Always container scope.

2. **No container class on a Svelte component.** Variables end up on
   some inner element (or worse, `:global(...)` on `:root`), and the
   consumer has no stable selector to override.

3. **Multiple container classes per component.** Each component owns
   exactly one container. If you find yourself writing
   `.ltree-container, .ltree-wrapper { --ltree-bg: ... }` you've drifted
   — pick one element and consolidate.

4. **Bare `color-scheme` on the container.** Blocks page inheritance.
   Equally wrong for `:host { color-scheme }` and
   `.ltree-container { color-scheme }`. Conditional
   `:host([data-theme="dark"]) { color-scheme: dark }` is fine — it
   only fires when the consumer has signalled their intent.

5. **No default background AND no painted chrome AND no documented
   transparency.** Component is invisible when dropped on a page
   that doesn't pre-paint a surface. Fix: either set
   `background: var(--<prefix>-bg)` on the container, OR ensure
   the component's primary visible element paints its own background
   (the form-control "wrapper host" pattern — see "Default background"
   above), OR document the intentional transparency in the README's
   Theming section.

6. **Container without `display: block`.** Custom elements collapse to
   inline by default; Svelte `<div>` is block but if you `display: contents`
   the container disappears as a layout box.

7. **Container without `position: relative`.** Tooltips and dropdowns
   inside the component anchor to `<body>` instead.

8. **Mixing component-local variable declarations between container and
   feature files.** Feature files (`base.css`, `controls.css`, etc.)
   may reference `--<prefix>-*`; they must not define them. All defs
   live on the container.

9. **Reading framework classes via `:host-context` for Svelte
   components.** `:host-context` is shadow-DOM only. Svelte components
   use plain descendant selectors (`[data-theme="dark"] .ltree-container`).

10. **Asymmetric dark/light selectors.** If you flip variables on
    `[data-theme="dark"]`, also flip them back on `[data-theme="light"]`.
    Otherwise a dark page with one `data-theme="light"` instance shows
    the dark variables (because the user's `light` override only undoes
    *some* of them).

---

## Reference implementations

- `@keenmate/web-multiselect` (v1.12.0-rc01+) — **wrapper-host**
  pattern (host is a layout wrapper; `.ms__input` paints), no
  `position: relative` on `:host` (all floating panels are
  `position: fixed` via Floating UI; in-flow `.ms__toggle` /
  `.ms__counter` anchor to `.ms__input-wrapper`), and
  **color-scheme-flipping** dark-mode strategy (conditional
  `color-scheme: dark` on `:host([data-theme="dark"])` /
  `:host-context(...)` instead of overriding `--ms-*` variables —
  preserves consumer `--base-*` overrides). The reference
  implementation for form-control components. Inspect
  `src/css/variables.css` + `src/css/dark-mode.css`.
- `@keenmate/web-grid` — same pattern, larger variable surface area.
- `@keenmate/web-daterangepicker` — `:host, :root` dual declaration
  for the popover portal. The non-default case; read the README for
  the rationale.
- `@keenmate/svelte-treeview` (rc10+) — `.ltree-container` Svelte
  pattern, `theme` prop forwarded to `data-theme`, container paints
  default `--ltree-bg`. The reference implementation for Svelte
  components.

---

## Open questions / future work

- **Web Components in Light DOM.** A custom element with
  `attachShadow({ mode: 'open' })` skipped — i.e. light-DOM custom
  elements — sits between the two patterns. The container is the
  custom element itself; selectors look like `web-foo { --foo-bg: ... }`
  but you lose `:host`'s shadow-boundary scoping benefits. Not covered
  here; if we adopt this pattern, this guideline gets a third section.
- **SSR considerations.** For Svelte (and any framework with
  server-side rendering), the `data-theme` attribute must be set
  during SSR if the page's framework class is known server-side, to
  avoid a flash of wrong theme on hydration. Implementation-specific;
  not formalized here.
- **Container inheritance.** When one component is rendered *inside*
  another component's container, the inner reads `--base-*` from the
  outer's container (because the outer's `:host` / `.container` is an
  ancestor of the inner). This is mostly what we want, but it means
  "themed pages" can be implemented as just a big component with
  `--base-*` set on its container. Worth documenting once a real
  consumer hits it.
