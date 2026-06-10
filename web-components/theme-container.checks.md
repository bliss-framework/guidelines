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

---

## C-TC-1 — No `--<prefix>-*` variables on `:root` / `html` / `body`

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

## C-TC-2 — Container paints a default background

**What:** The container has `background: var(--<prefix>-bg, …)` so the
component is visible standalone.

**How to verify:**
```bash
# For web components
grep -nE "^\s*:host\s*\{" src/css/*.css -A 50 \
  | grep -E "background\s*:\s*var\(--<prefix>-bg"

# For Svelte
grep -nE "^\s*\.<prefix>-container\s*\{" src/css/*.css -A 50 \
  | grep -E "background\s*:\s*var\(--<prefix>-bg"
```

**Pass:** The container sets `background` from the component-local bg
variable.

**Failure mode:** Component is invisible (or a flash of unstyled
content) on a page that doesn't pre-paint a surface behind it.

**Exception:** if D-TC-3 chose option B (intentionally transparent),
skip this check and confirm the README documents the opt-out.

---

## C-TC-3 — `--<prefix>-bg` chains through `--base-main-bg` with `light-dark()`

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

## C-TC-4 — No `color-scheme` on the container

**What:** The container does NOT declare `color-scheme: light`, `color-scheme: dark`,
or `color-scheme: light dark`. Declaring it shadows the page's
inherited `color-scheme` and breaks dark mode.

**How to verify:**
```bash
grep -nE "color-scheme" src/css/*.css
```

**Pass:** No match inside any `:host { … }` or `.<prefix>-container { … }`
block. Matches inside `@media` queries, comments, or descendant rules
are fine.

**Failure mode:** Component renders light on a dark page even when
`body { color-scheme: dark }` is set. Duplicates
[color-scheme.checks.md](./color-scheme.checks.md) C-CS-1 — passing one
passes the other.

---

## C-TC-5 — Per-instance `data-theme` selectors exist (dark AND light)

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

## C-TC-8 — `position: relative` on the container

**What:** The container is the positioning context for any
absolutely-positioned descendants (tooltips, popovers, dropdown chrome
that floats inside the component).

**How to verify:**
```bash
grep -nE "^\s*position\s*:" src/css/*.css | grep -E "(:host|\.<prefix>-container)"
```

**Pass:** `position: relative` declared on the container.

**Failure mode:** Floating UI inside the component anchors to the
nearest positioned ancestor on the consumer's page instead of to the
component's own root. Hard to debug for the consumer.

**Exception:** if the component has no internally-positioned
descendants AND will never grow one, `position: static` is acceptable.
Document.

---

## C-TC-9 — Container is a single root element

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

## C-TC-11 — README documents the container contract

**What:** The component's `README.md` "Theming" section documents:

- The container selector (`:host` or `.<prefix>-container`).
- The default background and the opt-out (`--<prefix>-bg: transparent`).
- How to set `data-theme` per-instance (attribute or prop).
- The framework conventions honored on ancestors.
- Any portal / popover quirks (D-TC-7).

**How to verify:** Open `packages/<component>/README.md`, find the
Theming section, confirm coverage.

**Pass:** Section exists and covers the four points above.

**Failure mode:** Consumers don't know where the theme anchors; they
try to set `--<prefix>-*` on `:root` and find it doesn't override.

---

## C-TC-12 — Subtree theming smoke test (browser)

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

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-TC-1  no --<prefix>-* on :root / html / body
[ ] C-TC-2  container paints default background
[ ] C-TC-3  --<prefix>-bg chains through --base-main-bg with light-dark()
[ ] C-TC-4  no color-scheme on container
[ ] C-TC-5  per-instance data-theme dark AND light selectors exist
[ ] C-TC-6  dark/light overrides target the container
[ ] C-TC-7  display: block (or documented exception)
[ ] C-TC-8  position: relative on container
[ ] C-TC-9  single root container
[ ] C-TC-10 Svelte: theme prop forwards to data-theme (N/A for web-components)
[ ] C-TC-11 README documents the container contract
[ ] C-TC-12 subtree theming smoke test passed
[ ] C-TC-13 standalone render works
[ ] C-TC-14 per-instance override works in browser
```

If any box is unchecked, the work is not done.
