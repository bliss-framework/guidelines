# Base Variables — Post-Implementation Checks

Run every check below **after** wiring up CSS variables in a new component
(or after refactoring an existing component's variable layer), and **before**
declaring the work done.

Each check: what to look for, how to verify, what failure looks like. Failing
any check means the work is not complete. Mark each as ✅ pass or ❌ fail in
the PR description.

Read [base-variables.md](./base-variables.md) for rationale.

---

## C-BV-1 — Every visible color resolves through a variable

**What:** No hardcoded color literal appears in any non-`:host` CSS rule.
Every `background`, `color`, `border-color`, `box-shadow` etc. consumes a
`var(--<prefix>-...)`.

**How to verify:**
```bash
# Find color hex / rgb literals in CSS rules (excluding :host blocks and comments)
grep -nE "(background|color|border|box-shadow|fill|stroke):\s*(#[0-9a-f]|rgb)" \
  src/css/*.css \
  | grep -v "_variables.css" \
  | grep -v "_dark-mode.css"
```

**Pass:** Empty output (or only matches inside comments / inside `:host`
blocks). Every visible color in `_base.css`, `_dropdown.css`, etc. consumes
`var(--...)`.

**Failure mode:** Theme overrides don't reach the element. A consumer sets
`--base-main-bg` and one element stays the wrong color.

---

## C-BV-2 — Every `var(--base-*)` read has a fallback

**What:** Every read of a `--base-*` variable must include a fallback —
another `var()` (chain), a literal, or `light-dark()`. Reads of
component-local `--<prefix>-*` variables do **not** require a fallback:
they're defined on the container (`:host` / `.<prefix>-container`) with
their own `--base-*` chain, so a feature-file read of `var(--wp-control-bg)`
is guaranteed to resolve. The two-layer pattern is what makes the
literal-at-the-call-site noise both unnecessary and out-of-sync-prone.

**How to verify:**
```bash
# Find --base-* reads with no comma (no fallback)
grep -nE "var\(--base-[a-z-]+\)" src/css/*.css

# Sanity: --<prefix>-* reads WITHOUT fallback are FINE; do not flag them.
# Only the --base-* ones above are violations.
```

**Pass:** Empty output from the `--base-*` grep. Any `var(--<prefix>-X)`
read without a fallback in a feature file is a pass — that's the
intended pattern.

**Failure mode:** A bare `var(--base-X)` read inside `:host` /
`.<prefix>-container` resolves to nothing when the consumer hasn't
loaded theme-designer (or set `--base-*` on `:root`/ancestor). The
property reverts to browser default and the component renders broken
standalone.

**Worked example (passing):**
```css
:host {
  /* --base-* read: fallback REQUIRED */
  --wp-control-bg: var(--base-main-bg, light-dark(#ffffff, #1a1a1a));
}

.wp__control {
  /* --<prefix>-* read: fallback NOT required */
  background: var(--wp-control-bg);
}
```

**Cross-references:** This rule pairs with [base-variables.md](./base-variables.md)
"The two-layer pattern" — the fallback lives at the definition site, not
the read site. Also see CLAUDE.md invariant #9.

---

## C-BV-3 — `:host` declares every component-local variable

**What:** Every `--<prefix>-X` consumed in a rule is also *defined* on `:host`
(or `:host([...])` for state-specific values).

**How to verify:**
```bash
# List variables consumed
grep -oE "var\(--<prefix>-[a-z-]+" src/css/*.css | sort -u > /tmp/consumed.txt

# List variables defined on :host
grep -oE "^\s*--<prefix>-[a-z-]+:" src/css/_variables.css | sed 's/://' | sort -u > /tmp/defined.txt

# Diff
diff /tmp/consumed.txt /tmp/defined.txt
```

**Pass:** Every consumed variable is in the defined list. Variables defined
but not consumed are fine (provides forward compatibility) but should be
documented in the manifest.

**Failure mode:** A consumer can't override a property because the variable
isn't there to override. The "themeable" knob is fictional.

---

## C-BV-4 — Component prefix is unique and reserved

**What:** The prefix picked in D-BV-1 is reserved in
[base-variables.md](./base-variables.md) → "Component prefix convention" and
isn't already used by another component.

**How to verify:** Open `base-variables.md` and find the prefix table. The
new prefix should be there with the component name. Cross-check by searching
the repo (or all KeenMate repos) for stray uses.

**Pass:** Prefix is listed, no collisions found.

**Failure mode:** Two components both use `wt`, and theme-designer can't
distinguish them.

---

## C-BV-5 — Manifest file exists and is published

**What:** `component-variables.manifest.json` exists at the package root,
lists every `--base-*` the component reads and every `--<prefix>-*` it
exposes, and is exported via `package.json`.

**How to verify:**
```bash
# Manifest exists
ls packages/<component>/component-variables.manifest.json

# Is exported
cat packages/<component>/package.json | grep -A2 '"./manifest"'
```

**Pass:** Manifest exists, exports field includes `"./manifest":
"./component-variables.manifest.json"`.

**Failure mode:** Theme-designer can't introspect the component. Doc-
generation tooling skips it.

---

## C-BV-6 — Manifest entries match the code

**What:** Every `--base-*` listed in `baseVariables` is actually read in the
component's CSS. Every `--<prefix>-*` listed in `componentVariables` is
actually defined on `:host`. No phantom entries, no missing entries.

**How to verify:** (rough automation)
```bash
# Every baseVariables entry should appear in _variables.css
jq -r '.baseVariables[].name' component-variables.manifest.json | while read v; do
  grep -q "var(--$v," src/css/_variables.css || echo "MISSING in code: --$v"
done

# Every componentVariables entry should appear on :host
jq -r '.componentVariables[].name' component-variables.manifest.json | while read v; do
  grep -q "^\s*--$v:" src/css/_variables.css || echo "MISSING on :host: --$v"
done
```

**Pass:** Empty output from both checks.

**Failure mode:** The manifest claims a knob exists but turning it does
nothing, or a real knob is undocumented.

---

## C-BV-7 — Fallback chains match the canonical patterns

**What:** Any variable that should use a canonical chain (dropdown, tooltip,
hover, active) follows the exact form documented in
[base-variables.md](./base-variables.md) → "Fallback chains."

**How to verify:** Open `_variables.css` and search for the four chain
patterns. Confirm each variable that needs a chain uses the canonical form
verbatim (or a justified deviation).

**Pass:** Patterns match. Any deviation is documented inline with a comment.

**Failure mode:** Inconsistency across components — theme designers can't
predict where a `--base-elevated-bg` will or won't cascade.

---

## C-BV-8 — Component README documents the contract

**What:** The component's README has a "Theming" section that:

- Lists or links to the manifest
- Documents `--<prefix>-rem` and how to override it
- Shows at least one example of overriding a `--base-*` and a `--<prefix>-*`

**How to verify:** Open `packages/<component>/README.md`, find the theming
section, confirm it covers the three points above.

**Pass:** Section exists and is accurate.

**Failure mode:** Consumers don't know what knobs exist or how to use them.

---

## C-BV-9 — No reads of `--base-*` directly in rules

**What:** The two-layer pattern requires `--base-*` to be consumed only
inside `:host` (when defining `--<prefix>-*`). Rules in `_base.css`,
`_dropdown.css`, etc. must consume `--<prefix>-*`, never `--base-*`.

**How to verify:**
```bash
grep -rn "var(--base-" src/css/ | grep -v _variables.css
```

**Pass:** Empty output. All `--base-*` reads are in `_variables.css`.

**Failure mode:** Component-level overrides (`web-grid { --wg-bg: red }`)
don't take effect because the rule reads `--base-bg` directly.

---

## C-BV-10 — Standalone render works

**What:** The component renders correctly in a page that doesn't define any
`--base-*` variables. The light-dark + literal fallbacks fully cover the
default appearance.

**How to verify:** Start the dev server, navigate to a fixture page that
mounts the component on a plain page with no theme overrides. Confirm:

- Text is readable.
- Borders are visible.
- Backgrounds aren't transparent (unless intentional).
- Interactive states (hover, focus) are visible.

**Pass:** Component looks correct standalone.

**Failure mode:** Component is unusable without theme-designer — violates
Project Invariant #1 from the README.

---

## C-BV-11 — Theme override works end-to-end

**What:** A consumer can set `--base-main-bg` (or any other `--base-*`) on
`:root` and the component picks it up.

**How to verify:** In a test fixture or dev page, add:
```html
<style>:root { --base-main-bg: hotpink; --base-accent-color: cyan; }</style>
```
and confirm the component renders with hotpink surfaces and cyan accents.

**Pass:** Visible color change.

**Failure mode:** Theme overrides silently don't apply — the `--base-*` chain
is broken somewhere.

---

## C-BV-12 — CHANGELOG entry

**What:** A CHANGELOG entry exists for the version that lands the variable
work, summarizing what's new / changed.

**How to verify:**
```bash
head -50 CHANGELOG.md
```

**Pass:** Entries under `Added` (for new variables) and/or `Changed` (for
semantics changes) describe the variable work concretely.

**Failure mode:** Downstream consumers miss the addition; theme designers
don't pick up new knobs.

---

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-BV-1  every visible color resolves through a variable
[ ] C-BV-2  every var(--base-*) read has a fallback
[ ] C-BV-3  :host declares every component-local variable
[ ] C-BV-4  component prefix is unique and reserved
[ ] C-BV-5  manifest exists and is exported
[ ] C-BV-6  manifest entries match the code
[ ] C-BV-7  fallback chains match canonical patterns
[ ] C-BV-8  README documents the contract
[ ] C-BV-9  no --base-* reads outside :host
[ ] C-BV-10 standalone render works
[ ] C-BV-11 theme override works end-to-end
[ ] C-BV-12 CHANGELOG entry
```

If any box is unchecked, the work is not done.
