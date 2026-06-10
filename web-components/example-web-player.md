# Example — `@keenmate/web-player`

A hands-on walkthrough applying [css-structure.md](./css-structure.md),
[base-variables.md](./base-variables.md), and
[color-scheme.md](./color-scheme.md) to a hypothetical media-player web
component. Use this as a template when building a new component from scratch.

The web-player isn't a real package yet — this doc is the worked example. If
the package later lands, this example becomes its reference implementation.

---

## What we're building

`<web-player>` — a custom element that renders an audio/video transport bar:

```
┌─────────────────────────────────────────────────────────────┐
│ [▶]  ━━━━━━━●━━━━━━━━━━━━━━━━  01:24 / 04:37  [🔊]━━●━ ⋮   │
└─────────────────────────────────────────────────────────────┘
```

Surfaces to think about for theming:

1. The player container itself (background, border).
2. The transport controls (play/pause, prev/next, settings — each with hover
   and active states).
3. The progress bar — both the unfilled track and the filled portion (uses
   accent color).
4. The current-time/total-time text.
5. The volume control (similar shape to progress).
6. A settings popover that may open on click of the ⋮ button (floating panel,
   uses dropdown-style theming).
7. A hover-preview tooltip showing the time at the cursor position when
   hovering the progress bar.

That's enough surface to exercise every pattern in the guidelines.

---

## Step 1 — Decisions (css-structure)

Working through [css-structure.decisions.md](./css-structure.decisions.md):

```
D-CSS-1 file-set strategy        : A. Canonical
D-CSS-2 co-location              : A. Centralized in src/css/
D-CSS-3 cascade layer naming     : A. variables, component, overrides
D-CSS-4 file-naming convention   : A. kebab-case, no prefix
D-CSS-5 mixed-concern placement  : A. by primary concern
D-CSS-6 BEM strictness           : A. strict
D-CSS-7 section banner threshold : A. > 100 lines
D-CSS-8 animations placement     : A. animations.css
```

No deviations.

## Step 2 — Decisions (color-scheme)

Working through [color-scheme.decisions.md](./color-scheme.decisions.md):

```
D-CS-1 dark mode strategy        : A. Belt-and-suspenders
D-CS-2 framework classes         : data-theme, data-bs-theme, .dark
D-CS-3 per-instance attribute    : A. data-theme
D-CS-4 hover/active fallback     : A. adaptive color-mix
D-CS-5 contrast tests cover      : signals 3, 4a, 4b, 4c, 5
D-CS-6 forced-colors             : A. no special handling (TBD)
```

No deviations — defaults across the board.

## Step 3 — Decisions (base-variables)

Working through [base-variables.decisions.md](./base-variables.decisions.md):

```
D-BV-1 component prefix          : wp
D-BV-2 base vars consumed        : see manifest below
D-BV-3 new --base-* proposed     : none
D-BV-4 component vars exposed    : see manifest below
D-BV-5 fallback chains used      : direct (most); dropdown chain for settings popover; tooltip chain for hover preview; computed for hover/active
D-BV-6 manifest published        : yes
D-BV-7 --wp-rem base             : 10px
```

`--base-*` we'll consume:

- `--base-text-color-1`, `--base-text-color-2` — primary time display,
  secondary time hint
- `--base-text-color-3` — placeholder when no media loaded
- `--base-main-bg` — player container surface
- `--base-elevated-bg` — control button surface
- `--base-hover-bg`, `--base-active-bg` — interactive state backgrounds
- `--base-accent-color` — progress bar fill, volume fill, focused outline
- `--base-text-color-on-accent` — text rendered on accent (rare here, but
  there for the unlikely "filled play head" case)
- `--base-border-color` — separators between controls and surrounding chrome
- `--base-dropdown-bg` — settings popover surface (chains)
- `--base-tooltip-bg`, `--base-tooltip-color` — hover-preview tooltip
- `--base-font-family`, `--base-font-size-sm`, `--base-font-size-xs` — time
  display typography
- `--base-border-radius-sm` — control corners

No new `--base-*` proposed.

---

## Step 4 — Folder skeleton

Following the canonical strategy from `css-structure.md`:

```
packages/web-player/
├── component-variables.manifest.json
├── package.json
├── README.md
└── src/
    ├── css/
    │   ├── main.css            ← entry, @layer declaration, imports
    │   ├── variables.css       ← :host { --wp-* } definitions
    │   ├── base.css            ← host display, player container
    │   ├── controls.css        ← play/pause/skip button rules
    │   ├── floating.css        ← settings popover, hover tooltip
    │   ├── states.css          ← :focus, :hover, :disabled, ARIA states
    │   ├── animations.css      ← (stub — player has no @keyframes today)
    │   ├── dark-mode.css       ← framework class overrides
    │   └── (Tier 3 below)
    │   ├── progress.css        ← progress bar / seek behavior
    │   └── volume.css          ← volume slider
    └── (TypeScript module files)
```

Tier 1 (skeleton) and Tier 2 (canonical concerns) files: 7. Tier 3 features
unique to web-player: 2 (`progress.css`, `volume.css`).

## Step 5 — `main.css`

`packages/web-player/src/css/main.css`:

```css
/* ==============================================================================
   @keenmate/web-player — MAIN ENTRY POINT
   ==============================================================================
   Cascade layer order (later = higher priority):
     variables  — :host { --wp-* } declarations
     component  — base + feature rules
     overrides  — dark mode, framework themes, per-instance overrides

   Consumer override contract:
   - Any unlayered consumer rule beats every rule below.
   - Any :root --base-* declaration beats the variables layer.

   BEM convention:
     .wp__<element>             — element
     .wp__<element>--<modifier> — state modifier
*/

@layer variables, component, overrides;

/* === SKELETON + CANONICAL CONCERNS (identical across the suite) === */
@import url('./variables.css')  layer(variables);
@import url('./base.css')       layer(component);
@import url('./controls.css')   layer(component);
@import url('./floating.css')   layer(component);
@import url('./states.css')     layer(component);
@import url('./animations.css') layer(component);

/* === COMPONENT-SPECIFIC FEATURES === */
@import url('./progress.css')   layer(component);
@import url('./volume.css')     layer(component);

/* === OVERRIDES === */
@import url('./dark-mode.css')  layer(overrides);
```

## Step 6 — Manifest

`packages/web-player/component-variables.manifest.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/keenmate/schemas/main/component-variables.schema.json",
  "component": "@keenmate/web-player",
  "prefix": "wp",
  "baseVariables": [
    { "name": "base-accent-color",        "required": true,  "usage": "Progress bar fill, volume fill, focused control outline" },
    { "name": "base-text-color-1",        "required": true,  "usage": "Current-time and total-time text" },
    { "name": "base-text-color-2",        "required": false, "usage": "Secondary labels (e.g. buffered duration hint)" },
    { "name": "base-text-color-3",        "required": false, "usage": "Placeholder text when no media is loaded" },
    { "name": "base-text-color-on-accent","required": false, "usage": "Text laid over accent-colored regions" },
    { "name": "base-main-bg",             "required": true,  "usage": "Player container background" },
    { "name": "base-elevated-bg",         "required": false, "usage": "Transport control button background; also chains to dropdown-bg" },
    { "name": "base-hover-bg",            "required": false, "usage": "Control hover background (primary lookup; falls back to color-mix)" },
    { "name": "base-active-bg",           "required": false, "usage": "Control pressed background (primary lookup; falls back to color-mix)" },
    { "name": "base-border-color",        "required": false, "usage": "Subtle separators within the player chrome" },
    { "name": "base-dropdown-bg",         "required": false, "usage": "Settings popover background (chains through elevated-bg)" },
    { "name": "base-inverse-bg",          "required": false, "usage": "Secondary fallback for hover-preview tooltip background" },
    { "name": "base-tooltip-bg",          "required": false, "usage": "Hover-preview tooltip background (primary lookup; chains through inverse-bg)" },
    { "name": "base-tooltip-color",       "required": false, "usage": "Hover-preview tooltip text color" },
    { "name": "base-font-family",         "required": false, "usage": "Font for time display and labels" },
    { "name": "base-font-size-sm",        "required": false, "usage": "Time display size" },
    { "name": "base-font-size-xs",        "required": false, "usage": "Secondary label size" },
    { "name": "base-border-radius-sm",    "required": false, "usage": "Control button corner radius" }
  ],
  "componentVariables": [
    { "name": "wp-rem",                       "category": "sizing",     "usage": "Base sizing unit (default 10px; set to 1rem for inherited font-scale)" },

    { "name": "wp-bg",                        "category": "surface",    "usage": "Player container background" },
    { "name": "wp-border",                    "category": "surface",    "usage": "Player container outer border" },
    { "name": "wp-border-radius",             "category": "surface",    "usage": "Player container corner radius" },
    { "name": "wp-padding",                   "category": "surface",    "usage": "Padding inside the player container" },

    { "name": "wp-text",                      "category": "text",       "usage": "Primary text color (time display)" },
    { "name": "wp-text-muted",                "category": "text",       "usage": "Muted text color (placeholder)" },
    { "name": "wp-font-family",               "category": "typography", "usage": "Font family for all player text" },
    { "name": "wp-font-size",                 "category": "typography", "usage": "Default text size (time display)" },
    { "name": "wp-font-size-label",           "category": "typography", "usage": "Secondary label size" },

    { "name": "wp-control-bg",                "category": "controls",   "usage": "Default background for transport controls" },
    { "name": "wp-control-bg-hover",          "category": "controls",   "usage": "Hover background for transport controls" },
    { "name": "wp-control-bg-active",         "category": "controls",   "usage": "Pressed/active background for transport controls" },
    { "name": "wp-control-color",             "category": "controls",   "usage": "Icon color for transport controls" },
    { "name": "wp-control-size",              "category": "controls",   "usage": "Control button width / height (default 32px)" },
    { "name": "wp-control-padding",           "category": "controls",   "usage": "Padding inside control buttons" },
    { "name": "wp-control-border-radius",     "category": "controls",   "usage": "Control button corner radius" },
    { "name": "wp-control-gap",               "category": "controls",   "usage": "Gap between adjacent controls" },

    { "name": "wp-progress-bar-height",       "category": "progress",   "usage": "Height of the seek bar (default 6px)" },
    { "name": "wp-progress-bar-bg",           "category": "progress",   "usage": "Unfilled portion of the seek bar" },
    { "name": "wp-progress-bar-fill",         "category": "progress",   "usage": "Filled portion of the seek bar (accent color)" },
    { "name": "wp-progress-bar-handle-size",  "category": "progress",   "usage": "Diameter of the draggable seek handle" },
    { "name": "wp-progress-bar-handle-color", "category": "progress",   "usage": "Color of the draggable seek handle" },

    { "name": "wp-volume-track-width",        "category": "volume",     "usage": "Width of the volume slider track (default 60px)" },
    { "name": "wp-volume-track-bg",           "category": "volume",     "usage": "Unfilled portion of the volume slider" },
    { "name": "wp-volume-track-fill",         "category": "volume",     "usage": "Filled portion of the volume slider" },

    { "name": "wp-popover-bg",                "category": "popover",    "usage": "Settings popover surface" },
    { "name": "wp-popover-border",            "category": "popover",    "usage": "Settings popover border" },
    { "name": "wp-popover-shadow",            "category": "popover",    "usage": "Settings popover drop shadow" },
    { "name": "wp-popover-padding",           "category": "popover",    "usage": "Padding inside the settings popover" },

    { "name": "wp-tooltip-bg",                "category": "tooltip",    "usage": "Hover-preview tooltip background" },
    { "name": "wp-tooltip-color",             "category": "tooltip",    "usage": "Hover-preview tooltip text color" },
    { "name": "wp-tooltip-padding",           "category": "tooltip",    "usage": "Padding inside the hover-preview tooltip" },

    { "name": "wp-focus-outline",             "category": "focus",      "usage": "Focused control outline (2px solid accent)" },
    { "name": "wp-focus-outline-offset",      "category": "focus",      "usage": "Offset of the focused control outline" },

    { "name": "wp-transition-fast",           "category": "transition", "usage": "Fast UI transition (hover, focus changes)" }
  ]
}
```

---

## Step 7 — `variables.css`

`packages/web-player/src/css/variables.css`:

```css
/* ==============================================================================
   CSS CUSTOM PROPERTIES (:host level)
   ==============================================================================
   See guidelines/web-components/base-variables.md for the two-layer pattern
   and guidelines/web-components/color-scheme.md for light-dark() rationale.
   ============================================================================== */

:host {
  /* --------------------------------------------------------------------------
     BASE SIZING UNIT
     -------------------------------------------------------------------------- */
  --wp-rem: 10px;

  /* --------------------------------------------------------------------------
     HOST DISPLAY
     -------------------------------------------------------------------------- */
  display: inline-block;
  position: relative;
  font-family: var(--wp-font-family);

  /* --------------------------------------------------------------------------
     COLORS — surface
     -------------------------------------------------------------------------- */
  --wp-bg: var(--base-main-bg, light-dark(#ffffff, #1a1a1a));
  --wp-border: 1px solid var(--base-border-color, light-dark(#e0e0e0, #3d3d3d));
  --wp-border-radius: calc(var(--base-border-radius-sm, 0.4) * var(--wp-rem));
  --wp-padding: calc(0.8 * var(--wp-rem));

  /* --------------------------------------------------------------------------
     COLORS — text
     -------------------------------------------------------------------------- */
  --wp-text:       var(--base-text-color-1, light-dark(#242424, #f5f5f5));
  --wp-text-muted: var(--base-text-color-3, light-dark(#707070, #a3a3a3));

  /* --------------------------------------------------------------------------
     TYPOGRAPHY
     -------------------------------------------------------------------------- */
  --wp-font-family:     var(--base-font-family, inherit);
  --wp-font-size:       calc(var(--base-font-size-sm, 1.4) * var(--wp-rem));
  --wp-font-size-label: calc(var(--base-font-size-xs, 1.2) * var(--wp-rem));

  /* --------------------------------------------------------------------------
     CONTROLS (transport buttons)
     --------------------------------------------------------------------------
     Hover and active fall back to adaptive color-mix so the highlight stays
     visible on any surface luminance. See base-variables.md → Fallback chains. */
  --wp-control-bg:        var(--base-elevated-bg, light-dark(#f5f5f5, #2b2b2b));
  --wp-control-bg-hover:  var(--base-hover-bg,
                          color-mix(in srgb, var(--wp-text) 8%, var(--wp-bg)));
  --wp-control-bg-active: var(--base-active-bg,
                          color-mix(in srgb, var(--wp-text) 14%, var(--wp-bg)));
  --wp-control-color:        var(--wp-text);
  --wp-control-size:         calc(3.2 * var(--wp-rem));
  --wp-control-padding:      calc(0.6 * var(--wp-rem));
  --wp-control-border-radius: var(--wp-border-radius);
  --wp-control-gap:          calc(0.4 * var(--wp-rem));

  /* --------------------------------------------------------------------------
     PROGRESS BAR
     -------------------------------------------------------------------------- */
  --wp-progress-bar-height:       calc(0.6 * var(--wp-rem));
  --wp-progress-bar-bg:           var(--base-elevated-bg, light-dark(#e0e0e0, #3d3d3d));
  --wp-progress-bar-fill:         var(--base-accent-color, #0078d4);
  --wp-progress-bar-handle-size:  calc(1.2 * var(--wp-rem));
  --wp-progress-bar-handle-color: var(--base-accent-color, #0078d4);

  /* --------------------------------------------------------------------------
     VOLUME
     -------------------------------------------------------------------------- */
  --wp-volume-track-width: calc(6.0 * var(--wp-rem));
  --wp-volume-track-bg:    var(--wp-progress-bar-bg);
  --wp-volume-track-fill:  var(--wp-progress-bar-fill);

  /* --------------------------------------------------------------------------
     POPOVER (settings menu)
     --------------------------------------------------------------------------
     Floating surface. Chains: dropdown-bg → elevated-bg → main-bg. */
  --wp-popover-bg:     var(--base-dropdown-bg,
                       var(--base-elevated-bg,
                       var(--base-main-bg, light-dark(#ffffff, #2b2b2b))));
  --wp-popover-border: 1px solid var(--base-border-color, light-dark(#e0e0e0, #3d3d3d));
  --wp-popover-shadow: var(--base-dropdown-box-shadow, 0 2px 8px rgba(0, 0, 0, 0.15));
  --wp-popover-padding: calc(0.8 * var(--wp-rem));

  /* --------------------------------------------------------------------------
     TOOLTIP (hover-time preview)
     --------------------------------------------------------------------------
     Inverse-colored surface. Chains: tooltip-bg → inverse-bg. */
  --wp-tooltip-bg:      var(--base-tooltip-bg,
                        var(--base-inverse-bg, light-dark(#333333, #f5f5f5)));
  --wp-tooltip-color:   var(--base-tooltip-color, light-dark(#ffffff, #1a1a1a));
  --wp-tooltip-padding: calc(0.4 * var(--wp-rem)) calc(0.8 * var(--wp-rem));

  /* --------------------------------------------------------------------------
     FOCUS
     -------------------------------------------------------------------------- */
  --wp-focus-outline:        2px solid var(--base-accent-color, #0078d4);
  --wp-focus-outline-offset: 2px;

  /* --------------------------------------------------------------------------
     TRANSITIONS
     -------------------------------------------------------------------------- */
  --wp-transition-fast: 0.1s ease;
}
```

---

## Step 8 — `dark-mode.css`

`packages/web-player/src/css/dark-mode.css`:

```css
/* ==============================================================================
   DARK MODE / LIGHT MODE SUPPORT
   ==============================================================================
   See guidelines/web-components/color-scheme.md for the full taxonomy of
   signals. This file handles signal #4 (framework theme classes) — light-dark()
   in _variables.css handles signals #1 / #3.
*/
@media (prefers-color-scheme: dark) {
  :host {
    --wp-bg:                #1a1a1a;
    --wp-text:              #f5f5f5;
    --wp-text-muted:        #a3a3a3;
    --wp-control-bg:        #2b2b2b;
    --wp-progress-bar-bg:   #3d3d3d;
  }
}

/* Framework theme classes — Bootstrap, Tailwind, generic data-theme */
:host([data-theme="dark"]),
:host-context([data-theme="dark"]),
:host([data-bs-theme="dark"]),
:host-context([data-bs-theme="dark"]),
:host-context(.dark) {
  --wp-bg:                #1a1a1a;
  --wp-text:              #f5f5f5;
  --wp-text-muted:        #a3a3a3;
  --wp-control-bg:        #2b2b2b;
  --wp-progress-bar-bg:   #3d3d3d;
}

/* Explicit LIGHT override — for forcing light on a dark page */
:host([data-theme="light"]),
:host-context([data-theme="light"]),
:host([data-bs-theme="light"]),
:host-context([data-bs-theme="light"]),
:host-context(.light) {
  --wp-bg:              var(--base-main-bg, #ffffff);
  --wp-text:            var(--base-text-color-1, #242424);
  --wp-text-muted:      var(--base-text-color-3, #707070);
  --wp-control-bg:      var(--base-elevated-bg, #f5f5f5);
  --wp-progress-bar-bg: var(--base-elevated-bg, #e0e0e0);
}
```

---

## Step 9 — Feature CSS (`base.css`, `controls.css`, `progress.css`, etc.)

This step splits the consuming rules across the canonical Tier-2 and the
component-specific Tier-3 files. Below, only the file-by-file decomposition
of what each rule lives in.

### `base.css` — player container

```css
.wp__player {
  display: inline-flex;
  align-items: center;
  gap: var(--wp-control-gap);
  background: var(--wp-bg);
  border: var(--wp-border);
  border-radius: var(--wp-border-radius);
  padding: var(--wp-padding);
  color: var(--wp-text);
  font-family: var(--wp-font-family);
  font-size: var(--wp-font-size);
}

.wp__time-display {
  font-size: var(--wp-font-size);
  color: var(--wp-text);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
```

### `controls.css` — transport buttons

```css
.wp__control {
  width: var(--wp-control-size);
  height: var(--wp-control-size);
  padding: var(--wp-control-padding);
  background: var(--wp-control-bg);
  color: var(--wp-control-color);
  border: none;
  border-radius: var(--wp-control-border-radius);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
```

### `floating.css` — popover + hover-preview tooltip

```css
/* Settings popover (positioned by Floating UI; mounted via portal helper). */
.wp__popover {
  background: var(--wp-popover-bg);
  border: var(--wp-popover-border);
  border-radius: var(--wp-border-radius);
  box-shadow: var(--wp-popover-shadow);
  padding: var(--wp-popover-padding);
  color: var(--wp-text);
}

/* Hover-preview tooltip on the progress bar. */
.wp__tooltip {
  background: var(--wp-tooltip-bg);
  color: var(--wp-tooltip-color);
  padding: var(--wp-tooltip-padding);
  border-radius: var(--wp-border-radius);
  font-size: var(--wp-font-size-label);
  pointer-events: none;
  white-space: nowrap;
}
```

### `states.css` — focus, hover, active modifiers

```css
.wp__control:hover {
  background: var(--wp-control-bg-hover);
}

.wp__control:active {
  background: var(--wp-control-bg-active);
}

.wp__control:focus-visible {
  outline: var(--wp-focus-outline);
  outline-offset: var(--wp-focus-outline-offset);
}
```

### `animations.css` — stub (no @keyframes yet)

```css
/* animations.css — web-player has no @keyframes today. */
```

### `progress.css` — Tier 3 feature

```css
.wp__progress {
  position: relative;
  flex: 1 1 auto;
  height: var(--wp-progress-bar-height);
  background: var(--wp-progress-bar-bg);
  border-radius: 9999px;
  cursor: pointer;
}

.wp__progress-fill {
  position: absolute;
  inset: 0 auto 0 0;
  background: var(--wp-progress-bar-fill);
  border-radius: inherit;
}

.wp__progress-handle {
  position: absolute;
  top: 50%;
  width: var(--wp-progress-bar-handle-size);
  height: var(--wp-progress-bar-handle-size);
  background: var(--wp-progress-bar-handle-color);
  border-radius: 50%;
  transform: translate(-50%, -50%);
}
```

### `volume.css` — Tier 3 feature

```css
.wp__volume {
  width: var(--wp-volume-track-width);
  height: var(--wp-progress-bar-height);
  background: var(--wp-volume-track-bg);
  border-radius: 9999px;
}

.wp__volume-fill {
  height: 100%;
  background: var(--wp-volume-track-fill);
  border-radius: inherit;
}
```

---

## Step 10 — Tests

### Dark-mode contrast fixture (`docs/test/dark-mode.html`)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>web-player — dark mode</title>
  <style>
    html, body {
      color-scheme: dark;
      background: #121212;
      color: #f5f5f5;
      padding: 16px;
    }
    web-player { display: inline-block; }
  </style>
</head>
<body>
  <h1>web-player dark mode contrast</h1>

  <!-- 1. Zero overrides — light-dark() fallbacks via color-scheme: dark -->
  <h2>Zero overrides</h2>
  <web-player id="zero" src="sample.mp3"></web-player>

  <!-- 2. Per-instance override on a light parent -->
  <div style="background: #fff; padding: 16px; color: #242424;">
    <h2 style="color: #242424;">Per-instance override (data-theme="dark")</h2>
    <web-player id="instance" src="sample.mp3" data-theme="dark"></web-player>
  </div>

  <!-- 3. Tailwind .dark class -->
  <div class="dark" style="background: #1a1a1a; padding: 16px;">
    <h2>.dark ancestor</h2>
    <web-player id="tailwind" src="sample.mp3"></web-player>
  </div>

  <script type="module">
    import '@keenmate/web-player'
  </script>
</body>
</html>
```

### Playwright contrast spec (`e2e/dark-mode.spec.ts`)

Reuse the contrast-ratio helpers from `web-grid/e2e/dark-mode.spec.ts`. Assert
≥ 3:1 for each visible element:

```ts
const cases = [
  { id: 'zero',     label: 'light-dark() inheritance' },
  { id: 'instance', label: 'per-instance data-theme="dark"' },
  { id: 'tailwind', label: '.dark ancestor' }
]

for (const { id, label } of cases) {
  test.describe(label, () => {
    test('time display readable', async ({ page }) => {
      await assertCellReadable(
        page.locator(`web-player#${id}`).locator('.wp__time-display'),
        `${id} time display`
      )
    })

    test('control hover readable', async ({ page }) => {
      const ctrl = page.locator(`web-player#${id}`).locator('.wp__control').first()
      await ctrl.hover()
      await assertCellReadable(ctrl, `${id} control hovered`)
    })

    test('control focused readable', async ({ page }) => {
      const ctrl = page.locator(`web-player#${id}`).locator('.wp__control').first()
      await ctrl.focus()
      await assertCellReadable(ctrl, `${id} control focused`)
    })

    test('progress bar fill visible against track', async ({ page }) => {
      const fill = page.locator(`web-player#${id}`).locator('.wp__progress-fill')
      await assertCellReadable(fill, `${id} progress fill`)
    })
  })
}
```

---

## Step 11 — README snippet

Add to `packages/web-player/README.md`:

```markdown
## Theming

`<web-player>` reads from the `@keenmate/web-grid`-compatible `--base-*`
taxonomy. Set any of the following on `:root` (or any ancestor of the
component) to theme it globally:

- `--base-accent-color` — progress bar fill, focused outline
- `--base-main-bg` — player background
- `--base-text-color-1` — time display text
- `--base-hover-bg`, `--base-active-bg` — control state backgrounds
- `--base-dropdown-bg` — settings popover background
- `--base-tooltip-bg`, `--base-tooltip-color` — hover-preview tooltip

For the complete list, see [`component-variables.manifest.json`](./component-variables.manifest.json).

### Component-specific variables

For component-level overrides (not affecting other KeenMate components), use
the `--wp-*` namespace. For example:

```css
web-player {
  --wp-control-size: 40px;            /* larger transport buttons */
  --wp-progress-bar-height: 8px;      /* taller seek bar */
  --wp-progress-bar-fill: hotpink;    /* override accent for the player only */
}
```

### Dark mode

Three signals trigger dark mode (any one is enough):

1. **OS preference + `color-scheme` declared on the page:**
   ```html
   <html style="color-scheme: light dark">
   ```
   The component then follows the OS preference automatically.

2. **Explicit page-level color-scheme:**
   ```html
   <body style="color-scheme: dark">
   ```

3. **Framework theme class on any ancestor:** `data-theme="dark"`,
   `data-bs-theme="dark"` (Bootstrap 5.3+), or `.dark` (Tailwind).

4. **Per-instance attribute on the component itself:**
   ```html
   <web-player data-theme="dark"></web-player>
   ```

To force light mode on a dark page, use the symmetric `light` versions:
`data-theme="light"`, `data-bs-theme="light"`, `.light`.
```

---

## Step 12 — Run the checks

Before declaring the component CSS / theming work done, walk through:

- [css-structure.checks.md](./css-structure.checks.md) — all 12 checks
- [color-scheme.checks.md](./color-scheme.checks.md) — all 9 checks
- [base-variables.checks.md](./base-variables.checks.md) — all 12 checks

Paste the three filled-out summary checklists into the PR description.

---

## What this example didn't cover

This walkthrough is intentionally limited to **CSS structure, variables, and
dark mode**. A full web-player would also need:

- Accessibility (focus management, ARIA roles for transport controls, keyboard
  shortcuts) — see (TBD) `accessibility.md`
- Event composition (`play`, `pause`, `timeupdate`, `volumechange` events
  composed out of the shadow DOM) — see (TBD) `shadow-dom-events.md`
- TypeScript types for the public API
- Packaging (UMD + ESM, manifest export)

Those topics will have their own examples once their guideline docs are
written.
