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

**Question:** Does the container paint its own background?

**Options:**

- **A — Yes (default).** `background: var(--<prefix>-bg)` on the
  container. `--<prefix>-bg` reads through `--base-main-bg` with a
  `light-dark()` fallback. The component is visible standalone on any
  page.
- **B — No, transparent.** The component is intentionally inline /
  layered (e.g. a switch, a badge, an inline button) and should let the
  parent's background show through. Document in the component README's
  "Theming" section.

**Default:** A. Almost every component should paint a surface. B is the
exception, not the rule.

**Your pick:** A / B

If B, justify briefly: ____________

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
- `position: static` is allowed only if the component has no
  internally-positioned descendants (tooltips, popovers, dropdown chrome).

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

## Decision summary

Paste into PR description / CHANGELOG entry:

```
Theme container decisions:
- D-TC-1 component type:                  A / B / C : <name>
- D-TC-2 container selector:              <selector>
- D-TC-3 default background:              yes / no   : <reason if no>
- D-TC-4 per-instance override:           A / B / C / D
- D-TC-5 ancestor conventions honored:    data-theme / data-bs-theme / .dark
- D-TC-6 layout defaults (block, rel, border-box):  yes / exception: <…>
- D-TC-7 portaled UI:                     A / B / C  : <strategy if C>
- D-TC-8 symmetric dark/light selectors:  yes / no   : <reason if no>
```
