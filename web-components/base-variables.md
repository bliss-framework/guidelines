# Base CSS Variables — Web Component Guideline

The `--base-*` CSS variable taxonomy: what it is, why it exists, the full
canonical set, the patterns for consuming it in a new component, and how to
document what a component reads.

This is a living doc. Update it when the taxonomy grows or shifts. See
[color-scheme.md](./color-scheme.md) for how `--base-*` variables interact
with light/dark mode.

---

## TL;DR

> **Every visible style in a custom-element library should resolve through a
> chain: `var(--<prefix>-X, var(--base-Y, light-dark(<light>, <dark>)))`. The
> `--base-*` layer is the cross-component theming hook; the `--<prefix>-*`
> layer is the component-local override; the `light-dark()` fallback is the
> standalone default. Never read a single-segment `var()` without a
> fallback.**

---

## Why a separate `--base-*` taxonomy?

A KeenMate page might mount four custom-element libraries simultaneously
(web-grid, web-multiselect, web-daterangepicker, web-player). Without a shared
taxonomy, theming the page means setting:

```css
web-grid           { --wg-main-bg: #1a1a1a; --wg-accent: #0070f3; ... }
web-multiselect    { --ms-main-bg: #1a1a1a; --ms-accent: #0070f3; ... }
web-daterangepicker{ --drp-main-bg: #1a1a1a; --drp-accent: #0070f3; ... }
web-player         { --wp-main-bg: #1a1a1a; --wp-accent: #0070f3; ... }
```

…which is duplication, doesn't stay in sync, and forces consumers to know every
component's private prefix. The `--base-*` taxonomy fixes this:

```css
:root {
  --base-main-bg:      #1a1a1a;
  --base-accent-color: #0070f3;
  /* ...one declaration, all four components update */
}
```

`@keenmate/theme-designer` (or any equivalent theme package) sets `--base-*`
on `:root` once. Every component that follows this guideline reads them.

---

## The two-layer pattern

Every color, font, radius, etc. in a component follows this shape:

```css
:host {
  /* Component-local variable. Defaults via --base-* chain. */
  --<prefix>-X: var(--base-Y, <fallback>);
}

.some-element {
  /* Always consume the component-local variable, NEVER the --base-* directly. */
  background: var(--<prefix>-X);
}
```

**Why two layers?**

1. **Consumers can override at either level.** Setting `--base-Y` themes every
   component at once. Setting `--<prefix>-X` themes one component only. Both
   work without code changes.
2. **Components stay standalone.** If `--base-Y` is never set, the fallback
   takes over. The component still looks correct.
3. **Code reads cleanly.** Internal CSS rules reference one short name
   (`var(--wp-control-bg)`), not a 5-deep `var()` chain.

### The fallback should always be `light-dark()` for colors

```css
:host {
  --wp-bg: var(--base-main-bg, light-dark(#ffffff, #1a1a1a));
}
```

This gives free OS-aware dark mode when a consumer declares `color-scheme`.
See `color-scheme.md` for why and when.

### Component-local fallback chains for adaptive values

For values that should *adapt* to other variables (not just be a literal),
chain through `color-mix` or `calc`:

```css
:host {
  --wp-text:     var(--base-text-color-1, light-dark(#242424, #f5f5f5));
  --wp-main-bg:  var(--base-main-bg,      light-dark(#ffffff, #1a1a1a));

  /* Hover should always be visible — derive it from text + main-bg. */
  --wp-hover-bg: var(--base-hover-bg,
    color-mix(in srgb, var(--wp-text) 8%, var(--wp-main-bg)));
}
```

This is how we get hover backgrounds that stay visible against any base
surface luminance.

---

## The canonical `--base-*` set

This is the catalog as of 2026-06. Components SHOULD reuse these names rather
than inventing new ones. New entries here require team agreement (because
every consumer component is expected to honor them).

### Colors — accent / text / surface

| Variable | Purpose | Typical fallback |
|----------|---------|------------------|
| `--base-accent-color` | Primary brand / focus color. Editor outline, sort indicator, selected state. | `#0078d4` |
| `--base-accent-color-hover` | Hover state for accent elements. | `#106ebe` |
| `--base-accent-color-active` | Pressed state for accent elements. | `#005a9e` |
| `--base-accent-color-light` | Light tint of accent for selected-row backgrounds, range highlights. | `color-mix(in srgb, var(--base-accent-color) 15%, transparent)` |
| `--base-text-color-1` | Primary body text. | `light-dark(#242424, #f5f5f5)` |
| `--base-text-color-2` | Secondary text — row numbers, secondary labels. | `light-dark(#424242, #d4d4d4)` |
| `--base-text-color-3` | Muted text — placeholders, disabled, empty states. | `light-dark(#707070, #a3a3a3)` |
| `--base-text-color-on-accent` | Text laid over `--base-accent-color`. | `#ffffff` |
| `--base-text-inverted` | Text on inverse-colored surfaces. | `#ffffff` |
| `--base-main-bg` | Primary surface — card backgrounds, cell backgrounds, input fields. | `light-dark(#ffffff, #1a1a1a)` |
| `--base-elevated-bg` | Elevated surface — header rows, striped rows, pagination bars. Also chains to `--base-dropdown-bg`. | `light-dark(#f5f5f5, #2b2b2b)` |
| `--base-hover-bg` | Hover state. Primary lookup; falls back to `color-mix(text, main)`. | (none — adaptive) |
| `--base-active-bg` | Pressed / active state. Primary lookup; falls back to `color-mix(text, main)`. | (none — adaptive) |
| `--base-disabled-bg` | Read-only / disabled backgrounds. | `light-dark(#eaeaea, #232323)` |
| `--base-dropdown-bg` | Floating panels — context menus, dropdowns, popovers. Chains through `--base-elevated-bg`. | (chained) |
| `--base-inverse-bg` | Inverse-colored surface (dark in light mode, light in dark mode). Used as secondary fallback for tooltip backgrounds. | `light-dark(#333333, #f5f5f5)` |
| `--base-border-color` | Default border / separator color. | `light-dark(#e0e0e0, #3d3d3d)` |

### Colors — inputs

| Variable | Purpose | Typical fallback |
|----------|---------|------------------|
| `--base-input-bg` | Text input background. | `light-dark(#ffffff, #1f1f1f)` |
| `--base-input-color` | Text input foreground. | `var(--base-text-color-1)` |
| `--base-input-border` | Input border (full shorthand). | `1px solid light-dark(#d1d1d1, #5a5a5a)` |
| `--base-input-border-hover` | Input border on hover. | `1px solid var(--base-accent-color)` |
| `--base-input-border-focus` | Input border when focused. | `1px solid var(--base-accent-color)` |
| `--base-input-placeholder-color` | Placeholder text inside inputs. | `light-dark(#707070, #a3a3a3)` |

### Colors — semantic

| Variable | Purpose | Typical fallback |
|----------|---------|------------------|
| `--base-danger-color` | Validation errors, destructive actions. | `light-dark(#d13438, #f87c86)` |
| `--base-danger-bg-light` | Light tint behind invalid fields. | `light-dark(#fde7e9, #442726)` |
| `--base-tooltip-bg` | Tooltip background. Chains through `--base-inverse-bg`. | (chained) |
| `--base-tooltip-color` | Tooltip text color. | `light-dark(#ffffff, #1a1a1a)` |
| `--base-dropdown-box-shadow` | Drop shadow for floating panels. | `0 2px 8px rgba(0, 0, 0, 0.15)` |

### Typography

| Variable | Purpose | Typical fallback |
|----------|---------|------------------|
| `--base-font-family` | Font for all component text. | `inherit` |
| `--base-font-size-base` | Standard body text. | `1.6` (multiplied by rem) |
| `--base-font-size-sm` | Smaller text — cells, controls. | `1.4` |
| `--base-font-size-xs` | Smallest text — filters, labels. | `1.2` |
| `--base-font-size-2xs` | Captions, error messages. | `1.1` |
| `--base-font-weight-normal` | Normal weight. | `400` |
| `--base-font-weight-semibold` | Header / emphasis weight. | `600` |
| `--base-line-height-normal` | Default line-height multiplier. | `1.5` |

Font sizes are unitless multipliers, intended to be applied via
`calc(var(--base-font-size-sm) * var(--<prefix>-rem))`. The component's `--<prefix>-rem` sets the base unit (default `10px`, set to `1rem` for Pure Admin integration).

### Layout

| Variable | Purpose | Typical fallback |
|----------|---------|------------------|
| `--base-border-radius-sm` | Tight corners — buttons, inputs. | `0.4` (multiplied by rem) |
| `--base-border-radius-md` | Standard corners — cards, dialogs. | `0.6` |
| `--base-border-radius-lg` | Large corners — overlays. | `0.8` |

Same multiplier convention as font sizes.

---

## Fallback chains — the four chained variables

Four `--base-*` variables chain through *other* `--base-*` variables before
hitting a literal fallback. The chains exist so that theme designers can set
fewer variables and still get sensible coverage.

```
--base-dropdown-bg → --base-elevated-bg → --base-main-bg → light-dark(#fff, #2b2b2b)
--base-tooltip-bg  → --base-inverse-bg                  → light-dark(#333, #f5f5f5)
--base-hover-bg    → color-mix(8% of text into main-bg)
--base-active-bg   → color-mix(14% of text into main-bg)
```

In CSS:

```css
/* dropdown chain */
--wp-dropdown-bg: var(--base-dropdown-bg,
                  var(--base-elevated-bg,
                  var(--base-main-bg,
                  light-dark(#ffffff, #2b2b2b))));

/* tooltip chain */
--wp-tooltip-bg:  var(--base-tooltip-bg,
                  var(--base-inverse-bg,
                  light-dark(#333333, #f5f5f5)));

/* hover chain */
--wp-hover-bg:    var(--base-hover-bg,
                  color-mix(in srgb, var(--wp-text) 8%, var(--wp-main-bg)));

/* active chain */
--wp-active-bg:   var(--base-active-bg,
                  color-mix(in srgb, var(--wp-text) 14%, var(--wp-main-bg)));
```

Why these specific chains?

- **Dropdown → elevated**: a dropdown is essentially a floating elevated
  surface. If a theme sets `--base-elevated-bg` but not `--base-dropdown-bg`,
  dropdowns should follow the elevated surface.
- **Tooltip → inverse**: tooltips are inverse-colored (dark on light pages,
  light on dark pages). `--base-inverse-bg` is the generic inverse surface;
  tooltips are one specific use of it.
- **Hover / active → color-mix**: derived from text + main-bg so the highlight
  always has enough contrast against the surface, regardless of how light or
  dark the surface is. Avoids the "invisible hover on dark themes" footgun.

---

## Component prefix convention

Each component picks a 2–4 letter prefix for its component-local variables.
Pick once, use everywhere. Existing prefixes:

| Component | Prefix | Example variable |
|-----------|--------|------------------|
| `@keenmate/web-grid` | `wg` | `--wg-cell-padding` |
| `@keenmate/web-multiselect` | `ms` | `--ms-option-bg` |
| `@keenmate/web-daterangepicker` | `drp` | `--drp-day-cell-bg` |
| `@keenmate/web-player` | `wp` | `--wp-control-bg` |

**Rules:**

1. Lowercase letters only.
2. Short (≤ 4 chars). The prefix appears on hundreds of CSS lines; long
   prefixes are noise.
3. Mnemonic. `ms` for multiselect, `wg` for web-grid. Avoid generic prefixes
   like `kc`, `ui`, `c`.
4. Reserve it in this doc when you create a new component, so the next person
   doesn't clash.

---

## Naming convention for component-local variables

Use `--<prefix>-<component-part>-<property>` where reasonable. Be specific.
Avoid generic spacing/color variables in the consumed CSS rules.

**Wrong — generic variable consumed directly:**

```css
.wp__progress-bar {
  height: var(--base-spacing-md);  /* What does spacing-md mean for a progress bar? */
}
```

**Right — component-specific variable:**

```css
:host {
  --wp-progress-bar-height: 0.6rem;
}

.wp__progress-bar {
  height: var(--wp-progress-bar-height);  /* Clear intent. Themeable in isolation. */
}
```

**Why this matters:**

1. **Self-documenting.** The variable name explains what it controls.
2. **Targeted overrides.** Consumers can change one thing without affecting
   others. Changing `--wp-progress-bar-height` shouldn't also resize buttons.
3. **Consistent across components.** Every KeenMate component follows this
   pattern, so consumers know what to look for.

### Suffix conventions

For mode-aware properties, suffix with the state:

- `--wp-control-bg` — default
- `--wp-control-bg-hover` — hover
- `--wp-control-bg-active` — pressed
- `--wp-control-bg-disabled` — disabled

For boundary properties (top/right/bottom/left), be explicit:

- `--wp-control-padding-block` — vertical padding
- `--wp-control-padding-inline` — horizontal padding

For sizes that scale with the host font, multiply through a rem unit:

```css
:host {
  --wp-rem: 10px;
  --wp-font-size-base: calc(var(--base-font-size-base, 1.6) * var(--wp-rem));
}
```

This is how a single host-level CSS change (`--wp-rem: 1rem`) scales the whole
component to honor the page's font size.

---

## The manifest file

Every component publishes a `component-variables.manifest.json` at its package
root. It enumerates every `--base-*` variable the component reads and every
`--<prefix>-*` variable it exposes for theming. Theme designers (and
tooling) read this to know what knobs exist.

### Format

```json
{
  "$schema": "https://raw.githubusercontent.com/keenmate/schemas/main/component-variables.schema.json",
  "component": "@keenmate/web-player",
  "prefix": "wp",
  "baseVariables": [
    {
      "name": "base-accent-color",
      "required": true,
      "usage": "Progress bar fill, focused control outline"
    },
    {
      "name": "base-main-bg",
      "required": true,
      "usage": "Player background"
    },
    {
      "name": "base-active-bg",
      "required": false,
      "usage": "Pressed state for transport controls (chains through color-mix fallback)"
    }
  ],
  "componentVariables": [
    {
      "name": "wp-control-bg",
      "category": "controls",
      "usage": "Background of play/pause/skip buttons"
    },
    {
      "name": "wp-progress-bar-height",
      "category": "progress",
      "usage": "Height of the seek bar (default 6px)"
    }
  ]
}
```

### Required fields per entry

- `name` — variable name *without* the leading `--`. Both lists use this.
- `usage` — one-line human-readable description. Used in tooltip / docs UIs.
- `required` (baseVariables only) — `true` if the component cannot render
  without it being set OR having a sensible fallback. Most are `false` because
  the fallback chain covers them.
- `category` (componentVariables only) — short grouping label, used to
  organize generated docs/tooling. Pick from existing categories where
  possible (`accent`, `text`, `surface`, `border`, `input`, `state`,
  `typography`, `radius`, `spacing`, plus component-specific ones).

### When to update the manifest

- New `--base-*` variable consumed → add to `baseVariables`.
- New `--<prefix>-*` variable exposed → add to `componentVariables`.
- Removed a variable → remove its entry. Document the removal in CHANGELOG.
- Changed semantics → update the `usage` string.

The manifest is *not* a stylesheet — it's metadata. Don't put values in it.

### Exporting the manifest

Add to `package.json`:

```json
{
  "exports": {
    "./manifest": "./component-variables.manifest.json"
  }
}
```

So consumers can `import manifest from '@keenmate/web-player/manifest'` and
generate docs / theme editors from it.

---

## Adding a new `--base-*` variable

Adding to the canonical taxonomy is a coordination move — every component
should honor it. Before adding:

1. **Is there an existing variable that fits?** Don't add `--base-button-bg`
   when `--base-active-bg` or `--base-main-bg` would do.
2. **Is the use case truly cross-component?** A property that only one
   component cares about belongs in `--<prefix>-*`, not `--base-*`.
3. **Will it have a sensible fallback?** Every new `--base-*` should have a
   default that works standalone.

If yes to all three, the steps are:

1. Add the variable to this doc's canonical table (in the right category).
2. Wire it up in any existing component that should honor it.
3. Add manifest entries (`baseVariables`) in every consuming component.
4. CHANGELOG entry in every consuming component (one minor version bump
   each).
5. Update theme-designer to set the new variable on its themes.

---

## Anti-patterns we've seen

1. **Reading `--base-*` directly in CSS rules** instead of going through
   `--<prefix>-*`. Breaks the two-layer override pattern.

   ```css
   /* Wrong */
   .wp__control { background: var(--base-main-bg, #fff); }

   /* Right */
   :host { --wp-control-bg: var(--base-main-bg, light-dark(#fff, #1a1a1a)); }
   .wp__control { background: var(--wp-control-bg); }
   ```

2. **No fallback in `var()`.** A consumer who doesn't load theme-designer
   gets a broken render.

   ```css
   /* Wrong */
   --wp-bg: var(--base-main-bg);

   /* Right */
   --wp-bg: var(--base-main-bg, light-dark(#fff, #1a1a1a));
   ```

3. **Inventing a parallel taxonomy.** `--wp-base-bg` is not a thing. Either
   it's `--base-X` (cross-component) or `--wp-X` (component-local). No
   third layer.

4. **Hardcoded literals in non-`:host` rules.** Every color used in the
   component must trace back to a variable defined on `:host`.

5. **Missing manifest entries.** A variable that exists in code but not in
   the manifest is invisible to theme designers. Always update both.

---

## Reference implementations

- `@keenmate/web-grid/component-variables.manifest.json` — the most
  comprehensive existing manifest. Mirrors the canonical taxonomy.
- `@keenmate/web-grid/src/css/_variables.css` — reference implementation of
  the fallback-chain pattern.
- `@keenmate/web-multiselect/src/css/_variables.css` — minimal version of the
  same pattern. Good starting point for a new component.

---

## Open questions / future work

- Should we formalize `--base-spacing-*` variables (xs/sm/md/lg/xl) as part of
  the canonical set? Web-grid has `--wg-spacing-*` locally, but they're not
  cross-component. Likely yes — would help typographic / layout consistency
  across the suite.
- Should `--base-z-index-*` exist? Currently each component owns its own
  z-index scale, which is fine because z-index is layout-scope, not
  theme-scope. Probably no.
- Schema validation for `component-variables.manifest.json` — the `$schema`
  URL is a placeholder; need to publish the actual JSON schema.
