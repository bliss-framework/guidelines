# Base Variables — Pre-Implementation Decisions

Answer every decision below **before** writing any CSS variables for a new
component, or before adding a new `--base-*` to the canonical taxonomy.

Each decision has a recommended default; deviating from the default requires
a one-line justification.

Read [base-variables.md](./base-variables.md) first if any of these questions
don't make sense.

---

## D-BV-1 — Component prefix

**Question:** What's the component-local variable prefix?

**Rules:** 2–4 lowercase letters, mnemonic, unique within the KeenMate
component suite. Reserve it by adding to the table in `base-variables.md` →
"Component prefix convention" *before* you start coding.

**Existing prefixes (do not reuse):**

| Prefix | Component |
|--------|-----------|
| `wg` | web-grid |
| `ms` | web-multiselect |
| `drp` | web-daterangepicker |
| `wp` | web-player |

**Pick yours:** __________ (e.g., `wc` for web-chart, `wt` for web-tree, …)

**Default:** there is no default — every component is different. Just pick
something mnemonic and reserve it.

---

## D-BV-2 — Which `--base-*` variables to consume

**Question:** Which entries from the canonical taxonomy will the component
actually read?

Go through the canonical table in [base-variables.md](./base-variables.md) and
mark every entry that maps to a real visual element in the component. Don't
read variables you don't use — it's noise and confuses theme designers.

**Minimum set most components need:**

- [x] `--base-text-color-1` (primary text)
- [x] `--base-main-bg` (primary surface)
- [x] `--base-border-color` (separators)
- [x] `--base-accent-color` (focus, primary action)

**Common additions:**

- [ ] `--base-text-color-2`, `--base-text-color-3` (secondary text)
- [ ] `--base-elevated-bg` (if the component has a header / striped pattern)
- [ ] `--base-hover-bg`, `--base-active-bg` (if the component has interactive elements)
- [ ] `--base-input-*` (if the component has text inputs)
- [ ] `--base-danger-color`, `--base-danger-bg-light` (if validation/errors)
- [ ] `--base-dropdown-bg` (if the component has floating panels)
- [ ] `--base-tooltip-bg`, `--base-tooltip-color` (if the component has tooltips)
- [ ] `--base-font-*` (if the component renders text)
- [ ] `--base-border-radius-*` (if the component has rounded corners)

**Rule:** Every checkbox you tick must map to a `--<prefix>-*` definition on
`:host`. Document every checkbox in `component-variables.manifest.json` under
`baseVariables`.

---

## D-BV-3 — New `--base-*` variables to propose

**Question:** Does the component need a `--base-*` variable that doesn't yet
exist in the canonical taxonomy?

| Answer | Implication |
|--------|-------------|
| **No** *(default)* | Use existing variables, or use a component-local `--<prefix>-*` if the need is component-specific. Proceed. |
| Yes | Stop. Adding to the canonical taxonomy is a coordination move — every other component should honor the new variable. See "Adding a new `--base-*` variable" in [base-variables.md](./base-variables.md). Requires team agreement before implementation. |

**Default: No.**

**If you're proposing a new `--base-*`:** write down the name, purpose, why
existing variables don't fit, and the proposed fallback. Then check with the
team.

```
Proposed: --base-_____________
Purpose:  ____________________
Why existing variables don't fit: ____________________
Proposed fallback: ____________________
```

---

## D-BV-4 — Component-local variables

**Question:** What `--<prefix>-*` variables will the component expose?

Inventory the component's visual surface and list every distinct property
that should be themeable. Each item becomes a `--<prefix>-*` variable.

Typical categories (adapt to your component):

- **Container** — bg, border, border-radius, shadow, padding
- **Interactive controls** — bg, color, padding, border-radius, hover-bg,
  active-bg, disabled opacity
- **Text** — colors for primary/secondary/muted, font sizes
- **State indicators** — focus outline, error, success, warning colors
- **Floating elements** (if any) — bg, shadow, border, padding for tooltips
  / dropdowns / popovers
- **Animations** — transition durations, easing functions (rarely themeable)

**Rule of thumb:** if a designer might want to tweak it, expose it as a
variable. If it's purely structural (e.g. `display: flex`), hardcode it.

**Naming:** follow `--<prefix>-<component-part>-<property>`. Examples for a
hypothetical web-player:

- `--wp-control-bg`
- `--wp-control-padding-block`
- `--wp-progress-bar-height`
- `--wp-progress-bar-fill-color`

Don't use generic names like `--wp-bg` or `--wp-color` — they're ambiguous.

---

## D-BV-5 — Fallback chain depth

**Question:** Which component-local variables need *chained* `--base-*`
fallbacks (vs a direct `--base-*` lookup)?

Three fallback patterns to choose between, per variable:

| Pattern | When to use |
|---------|-------------|
| Direct: `var(--base-X, <literal>)` | The component's need maps 1:1 to a `--base-*` variable. Most variables. |
| Chained: `var(--base-X, var(--base-Y, <literal>))` | The component's need is a more specific version of a broader `--base-*` token (e.g., dropdown bg → elevated bg). |
| Computed: `var(--base-X, color-mix(...))` | The fallback should adapt to other variables (e.g., hover bg → text + main mix). |

**Canonical chains** already established (use these exact forms):

```css
/* dropdown / floating UI surface */
var(--base-dropdown-bg, var(--base-elevated-bg, var(--base-main-bg, light-dark(#fff, #2b2b2b))))

/* tooltip surface */
var(--base-tooltip-bg, var(--base-inverse-bg, light-dark(#333, #f5f5f5)))

/* hover bg */
var(--base-hover-bg, color-mix(in srgb, var(--<prefix>-text) 8%, var(--<prefix>-main-bg)))

/* active bg */
var(--base-active-bg, color-mix(in srgb, var(--<prefix>-text) 14%, var(--<prefix>-main-bg)))
```

**Decision:** for each variable in D-BV-4, pick one of the three patterns.
Most will be "direct."

---

## D-BV-6 — Manifest scope

**Question:** Does the component publish a `component-variables.manifest.json`?

| Option | When to pick |
|--------|--------------|
| **A. Yes — full manifest** *(default)* | Component is published as an npm package or otherwise consumed by people who aren't on the team. |
| B. No manifest | Component is internal-only and never themed by anyone outside the team. Acceptable but inconsistent with the rest of the suite. |

**Default: A.** The manifest is small, easy to maintain, and pays off the
moment someone (or theme-designer) needs to introspect available variables.

---

## D-BV-7 — `--<prefix>-rem` base unit

**Question:** What's the component's base unit for size scaling?

| Option | When to pick |
|--------|--------------|
| **A. `--<prefix>-rem: 10px`** *(default)* | Default for standalone use. Clean pixel arithmetic (`calc(1.4 * 10px) = 14px`). |
| B. `--<prefix>-rem: 1rem` set at host level | Component will be used inside Pure Admin / a system that sets `html { font-size: 10px }`. Inherits the page's font-size scaling. |
| C. No `--<prefix>-rem`, hardcode `1px` units throughout | Component is small/simple and doesn't need scalable sizing. Acceptable for tiny components. |

**Default: A.** Lets consumers override to `1rem` if they want page-font-size
scaling.

---

## Decision summary table

Fill this out and paste it into the component's CHANGELOG entry or PR
description:

```
D-BV-1 component prefix          : ____
D-BV-2 base vars consumed        : [list, or "see manifest baseVariables"]
D-BV-3 new --base-* proposed     : [none | name + justification]
D-BV-4 component vars exposed    : [see manifest componentVariables]
D-BV-5 fallback chains used      : [direct everywhere | dropdown chain | tooltip chain | computed hover/active]
D-BV-6 manifest published        : [yes | no — reason]
D-BV-7 --<prefix>-rem base       : [10px | 1rem | hardcoded px]
```

---

When done deciding, proceed to implementation. Use
[base-variables.checks.md](./base-variables.checks.md) before declaring it
done.
