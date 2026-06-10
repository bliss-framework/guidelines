# CSS Structure — Web Component Guideline

How to organize the CSS files inside a custom-element library: file
decomposition, cascade strategy, naming conventions, and the standard file
set every component should ship with.

This doc focuses on **structure** — *where* CSS goes. It doesn't repeat the
content guidelines in [color-scheme.md](./color-scheme.md) or
[base-variables.md](./base-variables.md); read those for *what* CSS goes
inside the files.

---

## TL;DR

> **One file per feature, kebab-case names, no underscore prefix. `main.css`
> is the only entry point and declares an `@layer variables, component,
> overrides` cascade. Every block is BEM (`<prefix>__element--modifier`).
> Files over 100 lines get section banners; mixed-bag files (one file
> covering multiple unrelated concerns) get split.**

---

## The standard file set

We use a **canonical file set**: every component ships with the same fixed
list of stylesheets, even if some files are empty for a given component.
This means `main.css` is **identical across every component** — no edits
when a feature is added or removed, no `@import` drift, no per-component
"where does this go?" decisions.

The trade-off: an empty `pagination.css` in a component that doesn't paginate
is a small amount of clutter. We accept that in exchange for cross-component
consistency and zero-touch `main.css`.

### Tier 1 — Skeleton (always non-empty)

| File | Purpose | Layer |
|------|---------|-------|
| `main.css` | Entry point. Declares `@layer` order. Imports the canonical set. | (orchestrator) |
| `variables.css` | All `:host` CSS custom-property declarations. | `variables` |
| `base.css` | Host display, top-level container, structural primitives. | `component` |
| `dark-mode.css` | Framework theme-class overrides + `@media (prefers-color-scheme: dark)`. | `overrides` |

### Tier 2 — Canonical concerns (created always, may be empty per component)

| File | Owns | Empty for components that… |
|------|------|----------------------------|
| `controls.css` | Buttons, inputs, interactive control chrome. | …have no interactive controls (rare) |
| `floating.css` | Tooltips, dropdowns, popovers, menus — anything Floating-UI-anchored. | …have no floating elements |
| `states.css` | Cross-feature state modifiers: focus, hover, disabled, error tinting, dirty indicator. | …have no state variants (rare) |
| `animations.css` | `@keyframes` declarations. | …have no keyframe animations |

### Tier 3 — Component-specific features (added per component, named freely)

One file per feature. File name matches the BEM block:

| Example (web-grid) | Example (web-player) |
|--------------------|----------------------|
| `header.css` | `progress.css` |
| `cells.css` | `volume.css` |
| `editors.css` | `transport.css` |
| `pagination.css` | (none — player has no pagination) |
| `freeze.css` | (none — player has no freeze) |
| `tree.css` | (none — player has no tree) |

These are listed in `main.css` after the canonical set, alphabetized.

### Why a fixed canonical set

1. **`main.css` is identical (or nearly identical) across components.** A
   developer learning a second component already knows the file layout.
2. **No `main.css` drift.** Adding a feature doesn't require editing the
   entry-point file. The slot is already there.
3. **Cross-component diffability.** `diff component-a/main.css
   component-b/main.css` shows only the Tier-3 feature lines — the genuine
   differences, not noise.
4. **New-component setup is mechanical.** Copy the skeleton, fill in
   `variables.css` and `base.css`, leave the rest empty until needed.

### Empty file convention

An empty Tier-2 file MUST have a one-line stub comment so it's obvious it's
intentionally empty:

```css
/* controls.css — no interactive controls in this component. */
```

Without the stub, a reader can't tell "empty on purpose" from "forgot to
write."

### Files that should NEVER exist

- **`reset.css`** — shadow DOM doesn't inherit page styles, so CSS resets
  are unnecessary. If you think you need one, you're probably solving the
  wrong problem.
- **`utilities.css`** — utility classes are a light-DOM pattern (Tailwind,
  etc.). In a shadow-DOM library, every rule is already scoped — use
  component-specific class names instead.
- **`print.css`** unless the component has a defined print mode. Most don't.
  If yours doesn't, no file needed; not even a stub.

### Lean strategy (legacy / opt-out)

Some existing components (web-grid pre-refactor) created files only when
needed. This is the **lean strategy** — opposite of canonical. We allow it
for two reasons:

1. **Existing components** that already follow the lean pattern don't have
   to migrate immediately. Migrate when there's other CSS work to do.
2. **Trivial components** (a single-purpose icon, a basic loading spinner)
   may genuinely have nothing to put in `controls.css` or `floating.css`
   and the empty files are pure clutter.

**Default for new components: canonical.** Document the deviation if you
pick lean.

---

## File naming

### Rules

1. **kebab-case.** `dropdown.css`, `cell-selection.css`, `dark-mode.css`.
2. **No underscore prefix.** Underscore is a SASS partial convention. These
   files are plain CSS modules — underscore signals something they're not.
3. **One feature per file.** A file owns one logical area. If you can't
   summarize the file's purpose in one sentence, it's two files.
4. **File name matches the BEM block** where applicable. `toolbar.css` ↔
   `.<prefix>__toolbar`. Makes navigation predictable.
5. **No version suffixes.** Don't write `cells-v2.css` during a refactor.
   Use git history.

### Size guidance

- **Aim for < 200 lines per file.** Hard ceiling at ~300.
- Files **> 100 lines** must have section banners (see below).
- If a file is growing past 300 lines, it's almost certainly two files.
  Splitting is cheap; refactoring tangled CSS later is not.

---

## Cascade strategy — `@layer`

Use named CSS layers to make the cascade explicit. Consumers should not have
to guess the order in which your rules apply.

### Standard three-layer order

```css
/* main.css — IDENTICAL across components (canonical strategy) */
@layer variables, component, overrides;

/* Tier 1 — skeleton */
@import url('./variables.css')  layer(variables);
@import url('./base.css')       layer(component);

/* Tier 2 — canonical concerns (may be empty in some components) */
@import url('./controls.css')   layer(component);
@import url('./floating.css')   layer(component);
@import url('./states.css')     layer(component);
@import url('./animations.css') layer(component);

/* Tier 3 — component-specific features (alphabetized; varies per component) */
@import url('./cells.css')      layer(component);
@import url('./editors.css')    layer(component);
@import url('./header.css')     layer(component);
@import url('./pagination.css') layer(component);
/* ...etc... */

/* Tier 1 — dark mode last so it can override anything above */
@import url('./dark-mode.css')  layer(overrides);
```

**Layer order (later = higher priority):**

1. **`variables`** — `:host { --xx-foo: ... }` declarations only. Lowest
   priority. A consumer's `web-grid { --wg-foo: red }` always wins.
2. **`component`** — base + every feature file. The bulk of the stylesheet.
3. **`overrides`** — dark mode, framework theme classes, per-instance
   `data-theme` selectors. Highest internal priority — they must beat the
   default `component` rules to flip the theme.

### Why three layers, not five or one

- **One layer (or no layers):** consumers can't easily override your rules
  without `!important` or higher-specificity selectors.
- **Five+ layers:** invents distinctions (base / states / features /
  variants…) that don't pay off. The component is small enough that three
  buckets cover every case.
- **Three is the sweet spot:** clear semantics (what changes what), simple
  to maintain, gives consumers a clean escape hatch (their unlayered styles
  always win).

### Consumer override contract

With `@layer`, the rules of engagement are:

- A consumer's **unlayered CSS** always beats your `@layer component` rules.
  They don't need `!important`.
- A consumer's **`@layer overrides`** rules (or any rule with higher
  specificity inside `overrides`) beat your `overrides` rules.
- A consumer's **CSS variable** on `:root` or on `<your-component>` beats
  your `variables` layer trivially.

Document this contract in the component README so consumers know they have
power.

### The unlayered-reset footgun

The same rule that gives consumers a clean override path — *unlayered
beats layered* — bites in the other direction when a consumer ships a
universal reset *outside* any layer:

```css
/* Consumer's global stylesheet — Bootstrap reboot, Tailwind preflight,
   normalize.css, hand-rolled, anything of this shape */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
```

Per the CSS `@layer` specification, that `*` rule is **unlayered**, so
it beats *every* rule in your `@layer component` regardless of
specificity. The component's
`.<prefix>__cell { padding: var(--<prefix>-cell-padding) }` loses to
`* { padding: 0 }`, and the component renders with broken spacing even
though all the variables resolved correctly. This is not a library bug —
it's the contract working as designed — but it is the most common way
consumers accidentally clobber a layered component library's defaults.
We've hit it in practice (svelte-treeview showcase, 2026-06: a generic
`* { padding: 0 }` reset in the demo page's shared stylesheet wiped out
`.ltree-node-content` padding).

**Recommend to consumers in the component README:** wrap universal
resets in a named layer. Any layer name will do; the rule just needs to
be *layered* so the library's layered defaults can win against it.

```css
/* Consumer's global stylesheet — note the @layer wrapper around the reset */
@layer reset, page;

@layer reset {
  * { margin: 0; padding: 0; box-sizing: border-box; }
}

/* The rest of the consumer's styles stay unlayered — they still beat
   the library when the consumer intends to override. */
.my-app-header { padding: 1rem; }
```

The consumer's intentional overrides remain unlayered, so the escape
hatch is preserved for *deliberate* overrides. Only the generic reset
is demoted into a layer so it can't accidentally win.

This is the first thing to check when a consumer reports that the
component renders with collapsed padding, missing margins, or wrong
box-sizing despite the variables resolving to sane values.

---

## Section banners

Every file > 100 lines must internally segment with this banner format:

```css
/* ==============================================================================
   SECTION TITLE (UPPERCASE)
   ==============================================================================
   One- or two-line description of what's in this section, including any
   non-obvious constraints or invariants. */

.<prefix>__some-rule {
  /* ... */
}
```

**Why the equals-sign banners specifically:**

- Wide enough to spot when scanning a long file.
- Compatible with editor "fold to comment" features.
- Distinct from inline `/* ... */` comments inside rule blocks.

A 200-line file should have 3–6 sections. A 50-line file doesn't need them
at all.

---

## BEM class naming

Every CSS class in the shadow DOM follows BEM with the component prefix.

### Pattern

```
<prefix>__<element>           — element (mandatory prefix on every class)
<prefix>__<element>--<state>  — modifier (state variant of an element)
<prefix>__<element>__<part>   — sub-element (avoid when possible; usually
                                 the element is too coarse)
```

### Examples (web-grid)

```css
.wg__cell                   /* element: a single cell */
.wg__cell--focused          /* modifier: focused state */
.wg__cell--dirty            /* modifier: has unsaved changes */
.wg__cell--editing          /* modifier: in edit mode */
.wg__cell .wg__editor       /* nested element via descendant selector */
.wg__header-row             /* element: the header row */
.wg__header-row--sortable   /* modifier: column is sortable */
```

### Rules

1. **Prefix on every class.** No bare `.cell` or `.row`. Even with shadow
   DOM isolation, the prefix makes inspector navigation trivial and
   prevents accidental clashes with `slot`ed light-DOM content.
2. **Double underscore for element, double dash for modifier.** Standard
   BEM. Easy to spot in selectors.
3. **One class per concern.** A cell that's both focused and dirty has two
   classes: `wg__cell wg__cell--focused wg__cell--dirty`, not a combined
   `wg__cell--focused-dirty`.
4. **No nested BEM.** Don't write `wg__cell__content__inner__wrapper`.
   Two underscore levels max. If you're hitting three, the structure is
   too deep — flatten it.
5. **Modifiers describe state, not styling.** `wg__cell--focused` (state)
   is good. `wg__cell--blue` (styling) is wrong — use a variable.

### When to deviate

- **Pseudo-classes belong on selectors, not class names.** Use
  `.wg__control:hover`, not `.wg__control--hover`. The exception is when
  the hover state is also reachable via keyboard/programmatic means.
- **Tree-walking classes** like `.wg__row.even` for striped rows are
  acceptable in `_modifiers` style files, but prefer `.wg__row--even` for
  consistency.

---

## Co-location vs centralization

Two valid patterns:

### Pattern A — Centralized CSS (web-grid's current approach)

```
src/
├── css/                   ← all CSS lives here
│   ├── main.css
│   ├── variables.css
│   ├── toolbar.css
│   └── ...
└── modules/               ← all TS lives here
    ├── toolbar/
    │   └── index.ts
    └── ...
```

**Pros:** every stylesheet in one searchable folder; easy to spot duplication.
**Cons:** TS module and its CSS can drift; touching one without the other is easy.

### Pattern B — Co-located CSS

```
src/
└── modules/
    ├── toolbar/
    │   ├── index.ts
    │   └── toolbar.css    ← lives with the feature
    └── ...
```

**Pros:** changes to a feature touch one folder; deleting a module deletes
its CSS automatically.
**Cons:** harder to scan total CSS; CSS imports need a bundler that resolves them; main.css gets longer.

### Recommendation

**Pick one per component and document it in the component's README.** Both
patterns are defensible. For *new* components, Pattern B (co-located) tends
to scale better — modules feel like real units that own their styles. For
*existing* components like web-grid, the cost of refactoring to co-locate
is higher than the benefit, so stay with Pattern A.

The guideline is: **never mix patterns**. A component does one or the other,
not both at once.

---

## What goes in `main.css`

`main.css` is the entry point and only the entry point. It should contain:

1. A header comment with the component name and the cascade-layer contract
2. The `@layer` declaration
3. Every `@import` (in load order — layers handle priority, but readers still benefit from sane ordering)
4. Nothing else — no actual rules

Under the canonical strategy, **the Tier-1 and Tier-2 import block is
identical across every component**. Only the Tier-3 lines vary.

```css
/* ==============================================================================
   <COMPONENT NAME> — MAIN ENTRY POINT
   ==============================================================================
   Cascade layer order (later = higher priority):
     variables  — :host { --xx-* } declarations
     component  — base + feature rules
     overrides  — dark mode, framework themes, per-instance overrides

   Consumer override contract:
   - Any unlayered consumer rule beats every rule below.
   - Any :root --base-* declaration beats the variables layer.
*/

@layer variables, component, overrides;

/* === SKELETON + CANONICAL CONCERNS (Tier 1 + Tier 2 — identical across components) === */
@import url('./variables.css')  layer(variables);
@import url('./base.css')       layer(component);
@import url('./controls.css')   layer(component);
@import url('./floating.css')   layer(component);
@import url('./states.css')     layer(component);
@import url('./animations.css') layer(component);

/* === COMPONENT-SPECIFIC FEATURES (Tier 3 — alphabetized) === */
@import url('./cells.css')      layer(component);
@import url('./editors.css')    layer(component);
@import url('./header.css')     layer(component);
/* ...one line per feature file, alphabetized... */

/* === OVERRIDES === */
@import url('./dark-mode.css')  layer(overrides);
```

### No more header-comment drift

Under the canonical strategy, there's no separate file list in the header
comment — the comment just describes the layer contract, and the imports
below are self-documenting. Two reasons this works:

1. The Tier 1 + 2 block is invariant — readers learn it once, recognize it
   everywhere.
2. Tier 3 is short (component-specific features) and self-evident from the
   import lines.

This sidesteps the doc-drift problem that affected web-grid's pre-refactor
`main.css` header.

---

## What goes in `variables.css`

See [base-variables.md](./base-variables.md) for the *content* rules. Structure-wise:

- **One file**, even for components with 100+ variables. Don't split into
  `colors.css`, `typography.css`, `spacing.css` — it just adds indirection.
- **Section banners** to group related variables (`COLORS — TEXT`,
  `COLORS — SURFACE`, `TYPOGRAPHY`, `SPACING`, `Z-INDEX`, etc.).
- **Only `:host` rules.** No `.wg__cell { ... }` rules — those belong in
  feature files. `variables.css` only declares variables.
- **Comment the rationale** for non-obvious chains and `color-mix`
  computations. Future maintainers will thank you.

---

## What goes in `dark-mode.css`

Everything related to detecting dark mode that isn't a `light-dark()`
fallback in `variables.css`:

- `@media (prefers-color-scheme: dark)` block
- `:host([data-theme="dark"])` and `:host-context([data-theme="dark"])`
- Bootstrap `[data-bs-theme]` and Tailwind `.dark` selectors
- Symmetric `light` selectors so consumers can force light on a dark page

The variable overrides inside these selectors mirror the dark branch of
`light-dark()` in `variables.css`. Keep them in sync — if you change a dark
value, change both places.

See [color-scheme.md](./color-scheme.md) for the full pattern.

---

## What's NOT included

These topics are deliberately out of scope for this doc:

- **Print stylesheets** — most components don't have a useful print mode.
  If yours does, add a `print.css` and a `@media print` block; document why.
- **Container queries (`@container`)** — supported by all modern browsers
  but not standardized in our component patterns yet. If you reach for one,
  document the convention you're setting.
- **Animation choreography** — there isn't a single right answer for where
  complex animation sequences live. For now, keep `@keyframes` in
  `animations.css` (if you have any) and rule-level transitions inline with
  the rule.
- **Theming UX** (themes / presets) — the variable system is the
  mechanism; how a theme designer composes one is `@keenmate/theme-designer`'s
  concern.

When one of these grows into a real concern, formalize it as its own
guideline doc.

---

## Reference implementations

- **`@keenmate/web-grid` (current)** — Pattern A (centralized). Uses
  underscore-prefixed file names (legacy SASS convention) — *don't copy this
  part*. Does not yet use `@layer` (relies on `@import` order). Variables file
  is exemplary in structure.
- **`@keenmate/web-grid` (post-refactor — TODO)** — once it's brought in line
  with this doc, it'll be the canonical reference.
- **[example-web-player.md](./example-web-player.md)** — applies this doc's
  patterns to a hypothetical new component.

---

## Anti-patterns we've seen

1. **Mixed-bag files.** A file named `dialogs.css` that has tooltips AND
   a go-to dialog AND a confirmation modal. Three unrelated things. Split
   them.

2. **Vague file names.** `modifiers.css`, `extras.css`, `misc.css` —
   anything that doesn't tell you what's inside. Rename or split.

3. **`@import` order as the only cascade strategy.** Works until a consumer
   wants to override one specific rule and has to outweigh both your
   stylesheet's specificity AND its import position. Use `@layer`.

4. **Underscore prefix on non-partial files.** Inherited from SASS where it
   means "do not compile standalone." Pure-CSS files have no such concept —
   the prefix is just noise that misleads readers.

5. **Rules with hardcoded colors in feature files.** Every visible color
   must trace through a variable defined in `variables.css`. See
   [base-variables.md](./base-variables.md) → C-BV-1.

6. **Section banners every 20 lines in a 100-line file.** Banners are for
   navigation in large files, not for visual decoration. If every section
   has 5 lines, you're using them wrong.

7. **Re-declaring `:host` in feature files.** `:host` declarations live in
   `variables.css`, period. If a feature needs a new variable, add it
   there.

8. **Cross-file selectors.** Don't write `.wg__cell .wg__editor` in
   `cells.css` if the `.wg__editor` styles live in `editors.css`. Keep
   selectors local to the file that owns the right-most class; structure
   the HTML so this is natural.

---

## Migration from web-grid's current state

When web-grid is brought in line with this doc, the changes will be:

1. **Rename:** all `_*.css` → `*.css`. Update `main.css` imports.
2. **Cascade layers:** add `@layer variables, component, overrides;` to
   `main.css`. Wrap every `@import` in `layer(...)`.
3. **Canonical concerns:** create the four Tier-2 files
   (`controls.css`, `floating.css`, `states.css`, `animations.css`) if not
   already present. Move existing content into them:
   - Move tooltip-related rules from `dialogs.css` → `floating.css`.
   - Move dropdown panel rules from `dropdown.css` → `floating.css`.
   - Move toolbar floating-related rules from `toolbar.css` → `floating.css`.
     Keep button styling in `toolbar.css` (Tier 3).
   - Move state-modifier rules from `modifiers.css` → `states.css`.
   - `animations.css` likely stays empty (web-grid has only inline
     transitions). Add the stub comment.
4. **Split mixed-bag files:** `dialogs.css` becomes just the go-to dialog
   rules (or moves entirely into a Tier-3 `dialogs.css`); tooltip rules
   leave for `floating.css`.
5. **Section banners:** add to files > 100 lines that don't have them.
6. **`main.css` rewrite:** replace the drifted header comment with the
   canonical layer-contract comment. Rewrite the imports in canonical
   order.
7. **BEM convention** documented at top of `main.css` (one paragraph).

Each step is reversible and testable independently — the visual output
should not change. The dark-mode contrast suite (added in v1.3.0) is the
regression gate.

See `css-structure.checks.md` for the verification checklist.
