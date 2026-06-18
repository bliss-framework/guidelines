# Theme Container — Post-Implementation Checks

Run every check below **after** scaffolding (or refactoring) the
container of a component, and **before** declaring the work done.

Each check has: what to look for, how to verify, what failure looks
like. Failing any check means the work is not complete. Mark each as
✅ pass, ❌ fail, ⚠️ Manual (needs human), or ⚠️ Exception (documented
in the component README's "Known limitations") in the PR description.

Read [theme-container.md](./theme-container.md) for rationale.

Throughout these checks `<container>` means `:host` (for web-components)
or `.<prefix>-container` (for Svelte), and `<prefix>` means the
component's chosen prefix (`ms`, `wg`, `drp`, `ltree`, …).

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the meaning of
each tier.

---

## C-TC-1 — No `--<prefix>-*` variables on `:root` / `html` / `body`

**Tier:** `[auto]` (requires component prefix as input)

**What:** Component-local variables MUST live on the container, never
on the document root. This is the rule that fails subtree theming.

**How to verify:**
```bash
# Look for component-local var declarations on document-root selectors
grep -nE "^\s*:root\s*\{|^\s*html\s*\{|^\s*body\s*\{" src/css/*.css
grep -nE "--<prefix>-[a-z-]+:" src/css/*.css \
  | grep -E "(:root|^\s*html|^\s*body)"
```

**Pass:** No `--<prefix>-*` declarations under `:root`, `html`, or
`body`. (Web-components with portaled UI may declare on `:host, :root`
under D-TC-7 option C — that's an exception, document it.)

**Failure mode:** A wrapper around the component that sets `--base-*`
has no effect because the substitution is resolved at `:root` where
the wrapper isn't visible. The svelte-treeview rc10 bug, exactly.

---

## C-TC-2 — Component renders a visible surface standalone

**Tier:** `[semi]` — Option A is mechanical (grep for the `background: var(--<prefix>-bg)` declaration); Options B and C require reading the README's Theming section to confirm documented intent and identify the painted element.

**What:** When mounted on a plain page (no `--base-*` set, no theme
class), the component produces a visible surface. The guideline
recognizes three patterns for *where* that surface comes from
(D-TC-3); the check accepts whichever pattern the component declares.

**How to verify:**

1. **D-TC-3 option A — self-painted host** *(default)*. The
   container declares `background: var(--<prefix>-bg, …)`:
   ```bash
   grep -nE "^\s*:host\s*\{" src/css/*.css -A 60 \
     | grep -E "background\s*:\s*var\(--<prefix>-bg"
   ```
   **Pass:** match found. **Fail:** no match AND no D-TC-3 B or C
   declaration.

2. **D-TC-3 option B — intentionally transparent** (inline switches,
   badges). Container has no `background`. **Pass requires:** the
   component README's "Theming" section explicitly says so.

3. **D-TC-3 option C — wrapper host with painted chrome**
   (form-control components). Container has no `background`, but a
   specific internal element paints. Identify the chrome element
   (typically `.<prefix>__input` or `.<prefix>__viewport`) and
   confirm it declares `background: var(--<prefix>-<element>-bg)`:
   ```bash
   grep -nE "background\s*:\s*var\(--<prefix>-(input|viewport|surface)-bg" src/css/*.css
   ```
   **Pass:** match found AND the README's "Theming" section
   identifies the component as a wrapper-host (form-control) and
   names the painted element.

**Failure mode:** Component is invisible (or a flash of unstyled
content) on a page that doesn't pre-paint a surface behind it AND
the design intent isn't documented.

**Worked examples (passing):**
- **A:** `@keenmate/svelte-treeview` —
  `.ltree-container { background: var(--ltree-bg) }`.
- **B:** `@keenmate/svelte-switch` — transparent inline control,
  documented in README as "no host surface; pill paints itself."
- **C:** `@keenmate/web-multiselect` — `:host` has no background;
  `.ms__input { background: var(--ms-input-bg) }` paints the
  visible chrome. README's Theming section names this as the
  form-control wrapper-host pattern.

---

## C-TC-3 — `--<prefix>-bg` chains through `--base-main-bg` with `light-dark()`

**Tier:** `[auto]` (regex on `variables.css`)

**What:** The default background variable reads through `--base-main-bg`
and falls back to `light-dark(<light>, <dark>)` so OS dark mode works
out of the box.

**How to verify:** Open `variables.css` and find the `--<prefix>-bg`
declaration. It should look like:

```css
--<prefix>-bg: var(--base-main-bg, light-dark(#ffffff, #1a1a1a));
```

**Pass:** Pattern matches. Concrete light/dark colors can vary.

**Failure mode:** Dark mode looks wrong, or theme-designer's
`--base-main-bg` doesn't apply.

**Cross-references:** [base-variables.checks.md](./base-variables.checks.md)
C-BV-2 (every var has a fallback) and
[color-scheme.checks.md](./color-scheme.checks.md) C-CS-2
(`light-dark()` in fallbacks).

---

## C-TC-4 — No *bare* `color-scheme` on the container (conditional is fine)

**Tier:** `[semi]` — grep finds every `color-scheme` match; classifying each selector as bare vs conditional is a regex/lookup step

**What:** The container does NOT declare `color-scheme: light`,
`color-scheme: dark`, or `color-scheme: light dark` on its **bare**
selector (`:host` / `.<prefix>-container` with no further qualifier).
A bare declaration shadows the page's inherited `color-scheme` for
*every* instance and breaks dark mode inheritance.

**Conditional declarations are explicitly allowed** — and are the
recommended "Strategy B" pattern in
[color-scheme.md](./color-scheme.md). Selectors like
`:host([data-theme="dark"])`, `:host-context([data-bs-theme="dark"])`,
`.<prefix>-container[data-theme="dark"]`, or
`[data-theme="dark"] .<prefix>-container` fire only when the consumer
has explicitly signalled their theme intent. Setting
`color-scheme: dark` inside such a block *amplifies* the consumer's
signal — light-dark() in the component's variables resolves to dark —
while leaving the consumer's own `--base-*` overrides untouched.

**How to verify:**
```bash
grep -nE "color-scheme" src/css/*.css
```

For every match, classify it:

| Selector shape | Verdict |
|---|---|
| `:host { color-scheme: ... }` (bare) | ❌ Fail |
| `.<prefix>-container { color-scheme: ... }` (bare) | ❌ Fail |
| `:host([attr]) { color-scheme: ... }` | ✅ Conditional — pass |
| `:host-context(...) { color-scheme: ... }` | ✅ Conditional — pass |
| `.<prefix>-container[attr] { color-scheme: ... }` | ✅ Conditional — pass |
| `[ancestor-attr] .<prefix>-container { color-scheme: ... }` | ✅ Conditional — pass |
| Inside `@media` query | ✅ Pass |
| Inside a comment | ✅ Pass |

**Pass:** Every match is either inside a comment, inside `@media`, or
on a conditional selector (one of the rows marked ✅).

**Failure mode:** A bare `:host { color-scheme }` shadows the page's
inheritance for every instance. The component renders light on a dark
page even when `body { color-scheme: dark }` is set. Duplicates
[color-scheme.checks.md](./color-scheme.checks.md) C-CS-1 — passing one
passes the other.

**Worked example (passing):** `@keenmate/web-multiselect`
`src/css/dark-mode.css` declares `color-scheme: dark` on five
conditional selectors (`:host([data-theme="dark"])`,
`:host-context([data-theme="dark"])`,
`:host-context([data-bs-theme="dark"])`, `:host-context(.dark)`,
plus light counterparts). The bare `:host` block in
`src/css/variables.css` carries a long explanatory comment about *why*
it doesn't declare `color-scheme` there.

---

## C-TC-5 — Per-instance `data-theme` selectors exist (dark AND light)

**Tier:** `[auto]` (requires prefix + knowledge of container shape)

**What:** The stylesheet defines per-instance overrides for both
dark and light on the container.

**How to verify (web-component):**
```bash
grep -nE ":host\(\[data-theme=\"dark\"\]\)"  src/css/*.css
grep -nE ":host\(\[data-theme=\"light\"\]\)" src/css/*.css
```

**How to verify (Svelte):**
```bash
grep -nE "\.<prefix>-container\[data-theme=\"dark\"\]"  src/css/*.css
grep -nE "\.<prefix>-container\[data-theme=\"light\"\]" src/css/*.css
```

**Pass:** Both selectors exist. Both blocks set the *same* variable
keys.

**Failure mode:** A consumer who sets `data-theme="light"` to opt one
instance out of a dark page only gets *some* variables overridden — the
mismatched set bleeds through.

**Cross-references:** D-TC-4 (chose `data-theme` mechanism), D-TC-8
(symmetric selectors).

---

## C-TC-6 — Dark/light overrides target the container, not arbitrary scopes

**Tier:** `[semi]` — needs to read each block in `dark-mode.css` and judge whether the selector targets the container; mostly mechanical but the selector shapes vary

**What:** Every dark-mode and light-mode rule sets variables on the
container, not on descendants or arbitrary scopes.

**How to verify:** Open `dark-mode.css`. Each block should be one of:

- `@media (prefers-color-scheme: dark) { <container> { … } }`
- `:host-context(…), :host([…]) { … }` (web-component)
- `[…] .<prefix>-container, .<prefix>-container[…] { … }` (Svelte)

There should be no `.<prefix>__button[data-theme="dark"]` or
similar descendant-only override — variables flow from the container
down, not from a descendant up.

**Pass:** Every block in `dark-mode.css` targets the container.

**Failure mode:** Half the component flips for dark mode, half doesn't,
because variables defined on a descendant only override one rule.

---

## C-TC-7 — `display: block` (or documented exception) on container

**Tier:** `[auto]`

**What:** The container's display is `block`, `inline-block`, or
another **non-`contents`** block-level value.

**How to verify:**
```bash
grep -nE "^\s*display\s*:" src/css/*.css | grep -E "(:host|\.<prefix>-container)"
```

**Pass:** A `display: block` (or `inline-block`) rule on the container.
**Fail:** `display: contents`, or no `display` declaration at all
(custom-element default is inline; bare Svelte `<div>` is block but
that's implicit and shouldn't be relied on).

---

## C-TC-8 — Container is the positioning context (or every floating panel uses `position: fixed`)

**Tier:** `[semi]` — Path 1 is mechanical (`grep position: relative on the container`); the Path-2 fixed-floating exception needs to enumerate floating panels and verify each uses `fixed`, plus checking that absolute descendants anchor to an internal positioned wrapper

**What:** Either the container is the positioning context for
absolutely-positioned descendants (the default), OR the component is
designed so that nothing requires `:host` to be the offsetParent —
the "fixed-floating-UI" pattern.

**How to verify:**
```bash
# Path 1 — container is :host with position: relative
grep -nE "^\s*position\s*:" src/css/*.css | grep -E "(:host|\.<prefix>-container)"

# Path 2 — every floating panel uses position: fixed
grep -nE "^\s*position\s*:\s*fixed" src/css/floating.css

# Path 3 — in-flow absolute descendants anchor to an internal wrapper
grep -nE "^\s*position\s*:\s*relative" src/css/*.css | grep -vE "(:host|\.<prefix>-container)"
```

**Pass — any of:**

1. **Default:** `position: relative` declared on the container, OR
2. **Fixed-floating exception:** every floating-UI-anchored panel
   (`.<prefix>__dropdown`, `.<prefix>__tooltip`,
   `.<prefix>__popover`, …) declares `position: fixed`, AND every
   in-flow `position: absolute` descendant anchors to an internal
   `position: relative` wrapper inside the component
   (`.<prefix>__input-wrapper`, `.<prefix>__viewport`, etc.) rather
   than reaching out to `:host`.

**Failure mode:** Floating UI inside the component anchors to the
nearest positioned ancestor on the consumer's page instead of where
intended. Hard to debug for the consumer.

**Worked example (Path 2 + 3 passing):** `@keenmate/web-multiselect`
has no `position: relative` on `:host`. `floating.css` declares
`position: fixed` on `.ms__dropdown`, `.ms__hint`,
`.ms__badge-tooltip`, `.ms__selected-popover`. The in-flow
`.ms__toggle` and `.ms__counter` (`position: absolute`) anchor to
`.ms__input-wrapper { position: relative }`. The component never
needs `:host` to be the offsetParent.

---

## C-TC-9 — Container is a single root element

**Tier:** `[semi]` — auto-pass for web-components (`:host` is always single); Svelte requires reading the top-level `.svelte` file to confirm a single root

**What:** The component renders exactly one container — not a sibling
pair of containers, not a fragment.

**How to verify (Svelte):** Open the top-level `.svelte` file. The
template should have a single root element with the container class.

```svelte
<!-- RIGHT -->
<div class="ltree-container" data-theme={theme}>
  …
</div>

<!-- WRONG — fragment, no theme anchor -->
{#each items as item}
  <div class="ltree-container">…</div>
{/each}

<!-- WRONG — sibling containers -->
<div class="ltree-container">…</div>
<div class="ltree-container">…</div>
```

For web-components: the component is `:host`, which is always single
by definition; this check passes automatically.

**Pass:** Single root with the container class.

**Failure mode:** Theme overrides applied at the consumer level apply
to one of the roots but not the other, or to none at all.

---

## C-TC-10 — Svelte: `theme` prop forwards to container `data-theme`

**Tier:** `[semi]` (Svelte only — needs to read the top-level `.svelte` file; N/A for web-components)

**What:** Svelte components expose a `theme` prop and forward it to
`data-theme` on the container.

**How to verify (Svelte):** Open the top-level `.svelte` file. Look for:

```svelte
<script lang="ts">
  export let theme: 'dark' | 'light' | null | undefined = undefined;
</script>

<div class="<prefix>-container" data-theme={theme || null}>
```

The `{theme || null}` (or `{theme ?? null}`) idiom prevents
`data-theme=""` rendering when the prop is unset.

**Pass:** Prop exists, forwarded correctly.

**Failure mode:** Consumers can't override per-instance from Svelte
code; they have to drop into raw DOM manipulation.

**Web-component variant:** N/A — the attribute lands on the host
directly, no prop wiring needed. Mark N/A and move on.

---

## C-TC-11 — `docs/theming.md` documents the container contract

**Tier:** `[manual]` (read the file, judge coverage)

**What:** The component's `docs/theming.md` (per the
[readme-structure](./readme-structure.md) triad — the home of the
theming contract since the README slim-down) documents:

- The container selector (`:host` or `.<prefix>-container`).
- The default background and the opt-out (`--<prefix>-bg: transparent`).
- How to set `data-theme` per-instance (attribute or prop).
- The framework conventions honored on ancestors.
- Any portal / popover quirks (D-TC-7).

**How to verify:** Open `packages/<component>/docs/theming.md`, find
the container section, confirm coverage.

**Pass:** Section exists and covers the five points above.

**Failure mode:** Consumers don't know where the theme anchors; they
try to set `--<prefix>-*` on `:root` and find it doesn't override.

**Exception:** A component that pre-dates the readme-structure triad
(`docs/theming.md` not yet split out) can still pass if the
information lives in `README.md` under a "Theming" section — but
flag the file as a candidate for the readme-structure migration
(see [readme-structure.decisions.md](./readme-structure.decisions.md)
D-RS-6).

---

## C-TC-12 — Subtree theming smoke test (browser)

**Tier:** `[manual]` (browser observation)

**What:** Two instances of the component on the same page, with
different `--base-*` wrappers, render differently.

**How to verify:** Drop into a fixture page:

```html
<style>
  :root { color-scheme: light dark; }
  .theme-red  { --base-accent-color: red;  }
  .theme-blue { --base-accent-color: blue; }
</style>

<div class="theme-red">
  <my-component></my-component>   <!-- or <ComponentName /> for Svelte -->
</div>

<div class="theme-blue">
  <my-component></my-component>
</div>
```

Open in a browser. The two instances should render with different
accent colors.

**Pass:** Visible color difference.

**Failure mode:** Both instances render the same color. The variables
are declared on `:root` (C-TC-1 also failing) or the wrapper class
isn't actually wrapping the container.

Always ⚠️ Manual — automated detection of "visually different" is
flaky.

---

## C-TC-13 — Standalone render works

**Tier:** `[manual]` (browser observation)

**What:** The component renders correctly on a plain page with no
`--base-*`, no theme classes, no wrapper. Cross-reference
[base-variables.checks.md](./base-variables.checks.md) C-BV-10.

**How to verify:** Mount the component on a fixture page that does
NOTHING but `<script src="…/dist/component.js">` and the component
tag. Confirm:

- The default background paints a visible surface.
- Text is readable.
- Interactive states (hover, focus) are visible.

**Pass:** Component looks correct standalone.

**Failure mode:** Component is invisible or unreadable without a
configured theme — violates Project Invariant #1 in
[CLAUDE.md](../CLAUDE.md).

Always ⚠️ Manual.

---

## C-TC-14 — Per-instance override works end-to-end (browser)

**Tier:** `[manual]` (browser observation)

**What:** Setting `data-theme="dark"` on a single instance, on an
otherwise-light page, flips that instance to dark. Symmetric for
`data-theme="light"` on a dark page.

**How to verify:**

```html
<!-- Plain light page, force one instance to dark -->
<my-component data-theme="dark"></my-component>

<!-- Or for Svelte -->
<Component theme="dark" />
```

**Pass:** The single instance renders dark while the rest of the page
is light.

**Failure mode:** Per-instance attribute has no effect — the
`:host([data-theme="dark"])` / `.container[data-theme="dark"]`
selector is missing (C-TC-5) or has lower specificity than the
ancestor-class selectors.

Always ⚠️ Manual.

---

## C-TC-15 — FOUC prevention rule targets the right tag (web-components only)

**Tier:** `[auto]` (two greps + string comparison; N/A for Svelte or D-TC-9 = B)

**What:** If the component ships a FOUC-prevention rule in `base.css`
(D-TC-9 = A), the tag name in the `<tag>:not(:defined)` selector
matches the string passed to `customElements.define(...)` in the TS
source. If the component opted out (D-TC-9 = B), this check is N/A.

See [theme-container.md](./theme-container.md) → "FOUC prevention" for
the rationale and the canonical pattern.

**How to verify (web-component):**

```bash
# 1. Grep the tag(s) used in :not(:defined) rules in base.css
grep -nE "^\s*[a-z][a-z0-9-]+\s*:not\(:defined\)" src/css/base.css

# 2. Grep the registered tag(s) from the TS source
grep -rnE "customElements\.define\(['\"][^'\"]+['\"]" src

# 3. Compare — every CSS tag must appear in a define() call, and
#    every define() tag must have a matching CSS rule.
```

**Pass:** Every tag found in step 1 appears verbatim in a step-2
result, and vice versa. For a single-tag component, exactly one tag
on each side, matching.

**Failure modes:**

- **Tag mismatch (silent rename trap).** `multi-select:not(:defined)`
  in `base.css` but `customElements.define('web-multiselect', ...)`
  in TS. The FOUC rule never matches; pre-upgrade flash and layout
  shift reappear.
- **CSS prefix used instead of the tag.** `ms:not(:defined)` instead
  of `web-multiselect:not(:defined)`. The variable prefix is not the
  tag.
- **Rule missing on a visible-chrome component** AND D-TC-9 was
  answered A. Add the rule.
- **Define() result missing.** No `customElements.define` call found
  — likely the component is library-mode and consumers register
  manually. Confirm the docs name the expected tag and that
  `base.css` uses that exact name.

**N/A:**

- Svelte components (no upgrade phase).
- Components that declared D-TC-9 = B (intentionally no FOUC
  prevention) — confirm the README "Known limitations" section
  explains why.

**Worked example (failing):** `@keenmate/web-multiselect`
v1.12.0-rc01 — `base.css:13` declares `multi-select:not(:defined)`
but `src/web-component.ts:1154` registers
`customElements.define('web-multiselect', ...)`. Carried over from a
pre-rename version; FOUC prevention silently broken from that point.

---

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-TC-1  [auto]   no --<prefix>-* on :root / html / body
[ ] C-TC-2  [semi]   container paints default background
[ ] C-TC-3  [auto]   --<prefix>-bg chains through --base-main-bg with light-dark()
[ ] C-TC-4  [semi]   no bare color-scheme on container (conditional ok)
[ ] C-TC-5  [auto]   per-instance data-theme dark AND light selectors exist
[ ] C-TC-6  [semi]   dark/light overrides target the container
[ ] C-TC-7  [auto]   display: block (or documented exception)
[ ] C-TC-8  [semi]   position: relative on container (or fixed-floating exception)
[ ] C-TC-9  [semi]   single root container
[ ] C-TC-10 [semi]   Svelte: theme prop forwards to data-theme (N/A web-components)
[ ] C-TC-11 [manual] docs/theming.md documents the container contract
[ ] C-TC-12 [manual] subtree theming smoke test passed
[ ] C-TC-13 [manual] standalone render works
[ ] C-TC-14 [manual] per-instance override works in browser
[ ] C-TC-15 [auto]   FOUC rule tag matches customElements.define (web-component; N/A Svelte / D-TC-9 = B)

Tier totals: 5 auto, 6 semi, 4 manual
```

If any box is unchecked, the work is not done.
