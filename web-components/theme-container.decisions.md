# Theme Container — Pre-Implementation Decisions

Answer every decision below **before** scaffolding a new component, or
before refactoring an existing one's root element. Each decision has a
recommended default; deviating from the default requires a one-line
justification in the PR description.

Read [theme-container.md](./theme-container.md) first if any of these
questions don't make sense.

---

## D-TC-1 — Component type

**Question:** What technology hosts this component?

**Options:**

- **A — Web component (custom element with Shadow DOM)**. Container is
  `:host`. Default for new low-level UI primitives.
- **B — Svelte component**. Container is `.<prefix>-container` on the
  outermost rendered element.
- **C — Other framework** (React / Vue / Blazor / Razor / LiveView).
  Container is the framework's equivalent root-element selector.
  Document the choice; the rest of this guideline still applies in
  spirit.

**Default:** A for primitives consumed across multiple front-end stacks;
B for Svelte-only / SvelteKit-app-internal components. Don't mix shadow
DOM and Svelte in the same component.

**Your pick:** ____________

---

## D-TC-2 — Container selector

**Question:** What's the exact selector that owns the theme?

**Rules:**

- For (A): `:host` — no alternative.
- For (B): `.<prefix>-container` where `<prefix>` is the prefix chosen
  in [base-variables.decisions.md](./base-variables.decisions.md) D-BV-1.
  Append `-container` literally so the class is greppable and unique.
- For (C): pick a stable selector that names the component (not a
  generic `.root` or `.wrapper` that might collide).

**Your pick:** ____________ (e.g., `.ltree-container`, `:host`)

**Default:** Mechanical given D-TC-1 and the prefix; verify no other
component / library on the consumer's page is likely to use the same
class.

---

## D-TC-3 — Default background

**Question:** Where does the visible surface come from?

**Options:**

- **A — Self-painted host** *(default for composite components)*.
  `background: var(--<prefix>-bg)` on the container.
  `--<prefix>-bg` reads through `--base-main-bg` with a
  `light-dark()` fallback. Used by grids, players, calendars, tree
  views — components whose container *is* the visible surface.
- **B — Intentionally transparent.** The component is inline-style
  (a switch, a badge, an icon button) and lets the parent's
  background show through. Document in the component README's
  "Theming" section.
- **C — Wrapper-host with painted chrome** *(default for
  form-control components)*. The container is a layout wrapper; the
  visible surface is *one* internal element (typically
  `.<prefix>__input` or `.<prefix>__viewport`), which paints
  `background: var(--<prefix>-<element>-bg)`. The component is
  *not* invisible standalone — the chrome paints itself — but the
  host does not double-paint. Document in the component README's
  "Theming" section: name the painted element and note that the
  host is transparent. Example: `@keenmate/web-multiselect` —
  `:host` has no background; `.ms__input` paints
  `var(--ms-input-bg)`.

**Default:** A for composite UI (grid, player, calendar, tree),
C for form controls (multiselect, combobox, date picker, switch
wrapped in a labeled row, …), B for genuinely inline atoms.

**Your pick:** A / B / C

If B or C, justify briefly: ____________

---

## D-TC-4 — Per-instance override mechanism

**Question:** How does a consumer force one instance to dark or light?

**Options:**

- **A — `data-theme` attribute on the container (default).** For web-
  components, the attribute lands on `<my-element>` and the
  `:host([data-theme="dark"])` selector picks it up. For Svelte, expose
  a `theme: 'dark' | 'light' | null | undefined` prop and forward it as
  `data-theme={theme || null}` on the container.
- **B — `data-bs-theme` attribute only.** For components that target
  Bootstrap consumers exclusively. Uncommon.
- **C — Both `data-theme` and `data-bs-theme`.** Convenience for
  consumers who already use Bootstrap's attribute elsewhere. Acceptable
  but doubles the selector list.
- **D — CSS class on the container (`.theme-dark`, `.theme-light`).**
  Discouraged — class names collide with consumer's CSS more than
  attributes do.

**Default:** A. Symmetric — both `dark` and `light` selectors must exist
in the stylesheet so a dark-page consumer can opt one instance back to
light.

**Your pick:** A / B / C / D

If B / C / D, justify briefly: ____________

---

## D-TC-5 — Framework ancestor conventions honored

**Question:** Which framework theme classes/attributes on **ancestor**
elements should flip the component to dark/light?

This is the same question as [color-scheme.decisions.md](./color-scheme.decisions.md)
D-CS-2 — answer it once and reference it here. The container is *where*
the conventions are honored; D-CS-2 is *which* conventions.

**Default set:**

- [x] `[data-theme="dark"]` / `[data-theme="light"]` (generic)
- [x] `[data-bs-theme="dark"]` / `[data-bs-theme="light"]` (Bootstrap)
- [x] `.dark` / `.light` (Tailwind, Pure CSS, ad-hoc conventions)

Drop one if the component will never run in that ecosystem.

For web-components these are wired with `:host-context(...)`. For Svelte
they're plain descendant selectors (`[data-theme="dark"] .ltree-container`).

**Your set:** ____________

---

## D-TC-6 — Layout defaults

**Question:** Confirm the container has the layout defaults
[theme-container.md](./theme-container.md) requires.

**Tick each (default for most components):**

- [ ] `display: block`
- [ ] `position: relative`
- [ ] `box-sizing: border-box` (and a `* { box-sizing: inherit }` reset
      in `base.css`)

**Exceptions:**

- `display: inline-block` for genuinely inline components (switches,
  badges).
- `display: contents` is **forbidden** — the container disappears as a
  layout box and no longer hosts the background, focus-within, or
  offsetParent.
- `position: static` (i.e. no `position` declaration on the container)
  is acceptable in two cases:
  1. The component has no internally-positioned descendants and won't
     grow one, OR
  2. The component uses the **fixed-floating-UI pattern** — every
     floating panel uses `position: fixed` (typical for Floating-UI
     consumers) AND every in-flow `position: absolute` descendant
     anchors to an internal `position: relative` wrapper
     (`.<prefix>__input-wrapper`, `.<prefix>__viewport`, …) rather
     than to the container. The host is then never asked to be the
     offsetParent for anything.

  Example of (2): `@keenmate/web-multiselect` —
  `.ms__input-wrapper { position: relative }` anchors the absolute
  `.ms__toggle` / `.ms__counter`; the dropdown / hint / tooltip /
  popover are all `position: fixed`; `:host` has no `position`
  declaration.

**Your settings:** ____________

If you deviate from the defaults, justify briefly: ____________

---

## D-TC-7 — Portaled / floating UI

**Question:** Does the component render any UI **outside** the container
(popovers / tooltips / dropdowns mounted to `document.body`)?

**Options:**

- **A — No.** Everything renders inside the container. Default and
  preferred.
- **B — Yes, rendered inside container via `position: fixed`**. The
  portal node is a DOM descendant of the container so theme variables
  flow through. Works for most popover use cases on modern browsers
  (no need to escape stacking-context unless you actually hit one).
- **C — Yes, rendered to `document.body`.** The portal node is **not**
  a descendant of the container. You must either:
  - mirror `--<prefix>-*` onto the portal at mount time
    (JavaScript `getComputedStyle` + `setProperty`), or
  - declare variables on `:host, :root` (web-components) so the portal
    inherits from `:root`. Justify in the README's "Theming" section.

**Default:** A. B is fine. C is a last resort.

**Your pick:** A / B / C

If C, describe how the portal sees the theme: ____________

---

## D-TC-8 — Symmetric dark/light selectors

**Question:** Are dark *and* light overrides both present for every
signal honored in D-TC-5?

**Why this matters:** Without a symmetric `[data-theme="light"]`
override on a dark page, a consumer's per-instance opt-out only undoes
*some* variables (the ones inside the user's `light` block), leaving
the rest stuck on dark values from the ancestor `.dark` selector.

**Default:** Yes for all signals. The dark and light blocks should set
the **same variable set**; failing to mirror is a bug.

**Your answer:** Yes / No

If No, list which signals are dark-only and why: ____________

---

## D-TC-9 — FOUC prevention (web-components only)

**Question:** Does the component ship a light-DOM
`<tag>:not(:defined)` rule in `base.css` to prevent
flash-of-unstyled-content during the pre-upgrade window?

**Background:** Between the moment the browser parses
`<my-component>` and the moment JS calls
`customElements.define(...)`, the element is *unknown* — it defaults
to `display: inline`, has no height, and any text content
(placeholder attributes, declarative children) renders unstyled. On
fast connections this is invisible but still causes a layout shift
when the component upgrades and takes its real footprint; on slow
connections users see the flash. See
[theme-container.md](./theme-container.md) → "FOUC prevention" for the
full discussion.

| Option | When to pick |
|--------|--------------|
| **A — Yes, ship FOUC prevention** *(default for visible-chrome components)* | Inputs, lists, dropdowns, calendars, players, anything that reserves meaningful layout space after upgrade (~16px or more in any axis). The pre-upgrade flash and the layout shift are both real. |
| B — No FOUC prevention | Inline atoms with no pre-upgrade layout footprint — a switch with `display: inline-block`, a badge, an icon button. Document under "Known limitations" in the component README. |

**Default: A** for any web-component that reserves > ~16px of
vertical or horizontal space when fully rendered.

**N/A for Svelte components** — they render light DOM directly,
there's no upgrade phase.

**If A:** the rule lives in `base.css` (Tier-1 skeleton) and the tag
in the selector MUST match the string passed to
`customElements.define(...)` (C-TC-15 enforces this). Minimum-viable
rule:

```css
<registered-tag>:not(:defined) {
  display: block;                   /* or inline-block for inline-ish atoms */
  min-height: <reserved-height>;    /* match the default rendered height */
  color: transparent !important;
  background: transparent;
}
```

For multi-tag components (one library registering several tags),
declare one block per tag.

**If B:** add a one-line note to the README's "Known limitations":
"No FOUC prevention — component is inline-style with no pre-upgrade
layout footprint."

**Your pick:** A / B

If B, justify briefly: ____________

---

## Decision summary

Paste into PR description / CHANGELOG entry:

```
Theme container decisions:
- D-TC-1 component type:                  A / B / C : <name>
- D-TC-2 container selector:              <selector>
- D-TC-3 default background:              A self-paint / B transparent / C wrapper-host : <painted element if C>
- D-TC-4 per-instance override:           A / B / C / D
- D-TC-5 ancestor conventions honored:    data-theme / data-bs-theme / .dark
- D-TC-6 layout defaults (block, rel, border-box):  yes / exception: <…>
- D-TC-7 portaled UI:                     A / B / C  : <strategy if C>
- D-TC-8 symmetric dark/light selectors:  yes / no   : <reason if no>
- D-TC-9 FOUC prevention:                 A ship rule / B no — reason  (N/A for Svelte)
```
