# Base Variables — Post-Implementation Checks

Run every check below **after** wiring up CSS variables in a new component
(or after refactoring an existing component's variable layer), and **before**
declaring the work done.

Each check: what to look for, how to verify, what failure looks like. Failing
any check means the work is not complete. Mark each as ✅ pass or ❌ fail in
the PR description.

Read [base-variables.md](./base-variables.md) for rationale.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the meaning of
each tier.

---

## C-BV-1 — Every visible color resolves through a variable

**Tier:** `[auto]`

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

**Tier:** `[auto]`

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

**Tier:** `[auto]` (grep + diff; requires component prefix as input)

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

**Tier:** `[semi]` — grep the prefix table is mechanical; cross-checking against other KeenMate repos requires knowing where to look

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

**Tier:** `[auto]`

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

**Tier:** `[auto]` (jq + grep loops as shown)

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

**Tier:** `[semi]` — for each variable that *should* use a canonical chain, the regex match is mechanical; identifying *which* variables need a chain requires reading the canonical-patterns list

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

## C-BV-8 — `docs/theming.md` documents the variable contract

**Tier:** `[manual]` (read the file, judge coverage)

**What:** The component's `docs/theming.md` (per the
[readme-structure](./readme-structure.md) triad — the home of the
theming contract since the README slim-down) covers:

- Lists or links to the manifest
- Documents `--<prefix>-rem` and how to override it
- Shows at least one example of overriding a `--base-*` and a `--<prefix>-*`

**How to verify:** Open `packages/<component>/docs/theming.md`, find
the variable section, confirm it covers the three points above.

**Pass:** Section exists and is accurate.

**Failure mode:** Consumers don't know what knobs exist or how to use them.

**Exception:** A component that pre-dates the readme-structure triad
can still pass if the information lives in `README.md` under a
"Theming" section — flag for the readme-structure migration
(D-RS-6).

---

## C-BV-9 — No reads of `--base-*` directly in rules

**Tier:** `[auto]`

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

**Tier:** `[manual]` (browser observation)

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

**Tier:** `[manual]` (browser observation)

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

**Tier:** `[semi]` — existence of the entry is mechanical; judging whether it "describes the work concretely" is human work

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

## C-BV-13 — Input controls consume `--base-input-size-*-height`

**Tier:** `[semi]` — grep finds every `height:` / `min-height:` declaration; classifying which rule belongs to an input control vs structural chrome needs judgment

**What:** Any element the component renders as a text input, combobox,
autocomplete, date input, inline editor cell, picker trigger, or
similar **form-control surface** must read its height from the
canonical `--base-input-size-*-height` scale (per the "Layout" table in
[base-variables.md](./base-variables.md)). Hardcoded `height: 3.5rem`,
`height: 32px`, `min-height: 2.6em`, etc. on an input-like rule is a
fail; so is reading the height from a `--<prefix>-input-height` whose
fallback is a bare literal not chained through `--base-input-size-*`.

The five-tier scale (`xs` 3.1 / `sm` 3.3 / `md` 3.5 / `lg` 3.8 /
`xl` 4.1) is the canonical sizing axis for form controls — Theme
Designer publishes one set of heights and every consuming component
reads through the same variables for cross-component visual
consistency. A component that supports only one size still consumes
one tier (typically `md`); a component that supports multiple sizes
consumes one tier per variant.

**How to verify:**
```bash
# Find every height / min-height declaration in CSS files
grep -nE "(^|\s)(height|min-height):\s*" src/css/*.css

# For each match: identify the selector. If it targets an input-like
# element (editor cell, combobox trigger, autocomplete input, date
# input, picker chip, etc.), the value MUST resolve through
# var(--base-input-size-<tier>-height, ...). Structural chrome
# (headers, toolbars, scrollbars) is exempt and can use other tokens.

# Sanity check: every input rule should reference an input-size variable
grep -nE "var\(--base-input-size-[a-z]+-height" src/css/*.css
```

For each input-like rule:

1. The container declares
   `--<prefix>-input-height: var(--base-input-size-md-height, light-dark(3.5, 3.5)) * var(--<prefix>-rem)`
   (or the equivalent `calc(... * rem)` shape with a non-color
   fallback — `light-dark()` is only for colors).
2. The feature rule reads `var(--<prefix>-input-height)` — no
   literal.
3. Component-local variant variables (`--<prefix>-input-height-sm`,
   `-lg`, …) chain through the matching `--base-input-size-<tier>-height`.

**Pass:** Every input-like rule's height (and `min-height` /
`line-height` where it acts as a control-height substitute) is
expressed through `--<prefix>-input-height*` whose fallback chain
terminates in a `--base-input-size-*-height` read. The manifest's
`baseVariables` lists every `--base-input-size-*-height` tier the
component reads (per C-BV-6).

**Failure mode:** A component ships with 32px input height, web-grid
ships 36px, web-multiselect ships 35px — visually inconsistent next to
each other on the same page. Theme Designer's height knob does nothing
because nobody reads it.

**Exception:** Inline editor cells whose height must match the
surrounding row (driven by `--<prefix>-row-height`) and not the
form-control scale — document the inheritance in `docs/theming.md`
and cite this exception in `VALIDATION-NOTES.md`. Display-only
components (badges, tags, status pills) are N/A.

**Cross-references:** D-BV-2 (decision to opt into input-size
consumption); C-BV-6 (manifest must list the tiers consumed);
[base-variables.md](./base-variables.md) → "Layout" table for the
canonical scale.

---

## C-BV-14 — Tooltip geometry consumes the canonical `--base-tooltip-*` scale

**Tier:** `[semi]` — grep finds tooltip rules; classifying each value as "uses the canonical chain" vs "hardcoded" needs reading the rule

**What:** Any rule that paints the component's own tooltip surface
(in-shadow or portaled — Kind A / B from C-CS-10) must read its
geometry — `padding`, `font-size`, `line-height`, `border-radius`,
`max-width`, `box-shadow` — through the canonical
`--base-tooltip-*` scale defined in the "Layout — tooltips" table of
[base-variables.md](./base-variables.md). Hardcoded `padding: 0.4rem
0.8rem`, `max-width: 200px`, `border-radius: 8px`, etc., are a fail;
so is consuming a `--<prefix>-tooltip-*` whose fallback is a bare
literal not chained through the matching `--base-tooltip-*`.

The motivation is cross-component visual consistency: today's
`web-multiselect` tooltip is roughly 2× the padding, larger font,
double the border-radius, and noticeably wider max-width compared to
`web-daterangepicker`. With every component reading the same
`--base-tooltip-*` defaults, a tooltip on the multiselect looks like a
tooltip on the date picker looks like a tooltip on the grid — without
each component re-deciding density. Consumers wanting one component's
tooltips to look different override the `--<prefix>-tooltip-*` layer
locally; the *default* is uniform.

The seven canonical knobs (`padding-block`, `padding-inline`,
`font-size`, `line-height`, `border-radius`, `max-width`, `box-shadow`)
cover the full tooltip surface. Tooltip *colors* are still governed by
C-CS-2 / C-CS-10 — this check is geometry only.

**How to verify:**
```bash
# Find tooltip CSS rules (covers dedicated files and shared floating files)
grep -nE "(tooltip|popover)[^{]*\{" src/css/*.css

# In each tooltip rule, inspect every property — padding, font-size,
# line-height, border-radius, max-width, box-shadow — and confirm it
# either reads a --<prefix>-tooltip-* variable whose chain terminates
# in --base-tooltip-* OR reads --base-tooltip-* directly with a
# fallback.

# Sanity: the container should declare the --<prefix>-tooltip-* layer
grep -nE "^\s*--[a-z]+-tooltip-(padding|font|line|border|max|box)" src/css/variables.css
```

For each tooltip rule:

1. The container (`:host` or `.<prefix>-container`) declares each
   `--<prefix>-tooltip-<knob>` reading the matching `--base-tooltip-*`
   with the canonical fallback (`var(--base-tooltip-padding-block, 0.6)`
   etc.).
2. The tooltip selector reads only `var(--<prefix>-tooltip-*)` — no
   hardcoded sizing literals (`padding: 0.4rem 0.8rem`,
   `max-width: 200px`, `box-shadow: none`, etc.).
3. The manifest's `baseVariables` lists every `--base-tooltip-*`
   geometry variable the component reads (per C-BV-6).

**Pass:** Every tooltip-geometry property in every tooltip rule
resolves through a `--base-tooltip-*` chain. The manifest is
complete.

**Failure mode:** Two KeenMate components mounted on the same page
render tooltips with visibly different padding / font / corner radius
/ shadow, and a designer setting `--base-tooltip-padding-inline: 1.4`
on `:root` doesn't change either component because neither one reads
the variable.

**Exception:** A component with no custom tooltips (relying purely on
browser-native `title=""` tooltips — Kind C from C-CS-10) is N/A.
Cite the grep that returned no tooltip CSS rules.

**Cross-references:** C-CS-10 (tooltip *contrast* / theme propagation
— the color half of the tooltip story); D-BV-2 (decision to opt into
tooltip consumption); C-BV-6 (manifest must list the variables
consumed); [base-variables.md](./base-variables.md) → "Layout —
tooltips" for the canonical scale and defaults.

---

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-BV-1  [auto]   every visible color resolves through a variable
[ ] C-BV-2  [auto]   every var(--base-*) read has a fallback
[ ] C-BV-3  [auto]   :host declares every component-local variable
[ ] C-BV-4  [semi]   component prefix is unique and reserved
[ ] C-BV-5  [auto]   manifest exists and is exported
[ ] C-BV-6  [auto]   manifest entries match the code
[ ] C-BV-7  [semi]   fallback chains match canonical patterns
[ ] C-BV-8  [manual] docs/theming.md documents the variable contract
[ ] C-BV-9  [auto]   no --base-* reads outside :host
[ ] C-BV-10 [manual] standalone render works
[ ] C-BV-11 [manual] theme override works end-to-end
[ ] C-BV-12 [semi]   CHANGELOG entry
[ ] C-BV-13 [semi]   input controls consume --base-input-size-*-height
[ ] C-BV-14 [semi]   tooltip geometry consumes canonical --base-tooltip-* scale

Tier totals: 6 auto, 5 semi, 3 manual
```

If any box is unchecked, the work is not done.
