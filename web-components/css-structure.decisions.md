# CSS Structure — Pre-Implementation Decisions

Answer every decision below **before** scaffolding the CSS folder for a new
component, or before refactoring an existing component's CSS structure.

Each decision has a recommended default. Deviating from the default requires
a one-line justification in the component README or CHANGELOG.

Read [css-structure.md](./css-structure.md) first if any of these questions
don't make sense.

---

## D-CSS-1 — File-set strategy

**Question:** Will the component use the canonical file set (every Tier-1
and Tier-2 file present, even if empty) or the lean set (only files with
content)?

| Option | When to pick |
|--------|--------------|
| **A. Canonical** *(default)* | New component, or refactor of an existing one where consistency with the rest of the suite matters. Empty Tier-2 files are acceptable. |
| B. Lean | Existing component that already follows the lean pattern and isn't due for a structure refactor. Or trivial single-purpose components where empty files would be pure clutter. |

**Default: A. Canonical.**

**If you pick B:** state which Tier-2 files you're skipping and why. Note
this in the README under "Code structure."

---

## D-CSS-2 — Co-location

**Question:** Where do feature CSS files live relative to their TypeScript
counterparts?

| Option | When to pick |
|--------|--------------|
| **A. Centralized in `src/css/`** *(default)* | Easier to scan total CSS surface; matches web-grid, web-multiselect, web-daterangepicker convention. |
| B. Co-located with modules (`src/modules/<feature>/<feature>.css`) | New component where you want strong module ownership of feature CSS, and where deleting a module should delete its CSS automatically. |

**Default: A. Centralized.**

**Rule:** never mix. Either all CSS is centralized or all CSS is co-located.

**If you pick B:** `main.css` still imports from the module folders. Update
the bundler config if needed.

---

## D-CSS-3 — Cascade layer naming

**Question:** Which `@layer` names will `main.css` declare?

| Option | When to pick |
|--------|--------------|
| **A. `variables, component, overrides`** *(default)* | Standard three-layer order. Used across the suite. |
| B. Custom naming | Almost never. If you have a real reason (component has multiple independent concerns that need separate cascade buckets), document the layer contract in the README. |
| C. No layers (omit `@layer`) | Acceptable only for very simple components or for libraries that need to support browsers without `@layer` support (Chrome < 99, Firefox < 97, Safari < 15.4 — quite old by 2026). Document the gap. |

**Default: A.**

**Decision implication:** the layer names go into `main.css`, into the
"Consumer override contract" section of the README, and into the
`css-structure.checks.md` verifications.

---

## D-CSS-4 — File-naming convention

**Question:** What's the file-name convention?

| Option | When to pick |
|--------|--------------|
| **A. kebab-case, no prefix** *(default)* — `variables.css`, `dark-mode.css`, `cells.css` | New component; matches this guideline. |
| B. kebab-case with underscore prefix — `_variables.css`, `_dark-mode.css` | Existing component that already uses the underscore convention and isn't being renamed in this pass. Document as legacy. |

**Default: A.**

**Note:** underscore prefix is a SASS partial convention with no meaning in
pure CSS. Picking B should always come with a "we'll migrate later" intent.

---

## D-CSS-5 — Where mixed concerns go

**Question:** When a feature CSS would logically span multiple Tier-2
buckets (e.g., a tooltip has both *floating* behavior and *state* behavior
like fade-in), where does it live?

| Option | When to pick |
|--------|--------------|
| **A. By primary concern** *(default)* | Tooltip → `floating.css` (because positioning is the primary concern, fade is incidental). Date picker → `floating.css` (popover) + its own `datepicker.css` for the calendar grid. |
| B. By component | Tooltip → `tooltip.css` (its own Tier-3 file). Use when the feature is substantial enough to merit its own file. |

**Default: A** unless the feature is > 60 lines, in which case B.

**Rule of thumb:** small floating panel = `floating.css`. Large dedicated
feature with its own DOM tree = Tier-3 file named after the feature.

---

## D-CSS-6 — BEM strictness

**Question:** Is BEM (`<prefix>__element--modifier`) strictly enforced, or
do you allow other patterns?

| Option | When to pick |
|--------|--------------|
| **A. Strict BEM** *(default)* | New component. Predictability across the suite. Required by `css-structure.md`. |
| B. Mixed BEM + utility classes | Almost never. The shadow-DOM scoping makes utilities redundant. |
| C. Other convention | Only with strong justification and full documentation. |

**Default: A.**

---

## D-CSS-7 — Section banners

**Question:** What's the threshold for adding section banners inside a
file?

| Option | When to pick |
|--------|--------------|
| **A. > 100 lines** *(default)* | Files at or below 100 lines are scannable without banners; above 100, navigation benefits noticeably. |
| B. Always (even tiny files) | Probably overkill. Use only if your editor's "fold to comment" workflow leans on banners regardless of file size. |
| C. > 200 lines | Lower-overhead convention. Files between 100 and 200 lines stay banner-free. |

**Default: A. > 100 lines.**

---

## D-CSS-8 — Animations placement

**Question:** Where do `@keyframes` and animation rules live?

| Option | When to pick |
|--------|--------------|
| **A. `animations.css`** *(default — required under canonical strategy)* | All keyframes centralized. Inline `transition: ...` rules stay next to the property they animate. |
| B. Next to the feature that uses them | Acceptable under lean strategy if the component has only one or two animations and they're tightly coupled to a single feature. |

**Default: A.** Even if `animations.css` ends up empty (no keyframes),
create the stub.

---

## Decision summary table

Fill this out and paste into the component CHANGELOG entry or PR description:

```
D-CSS-1 file-set strategy        : [A canonical | B lean — reason]
D-CSS-2 co-location              : [A centralized | B co-located]
D-CSS-3 cascade layer naming     : [A variables/component/overrides | B custom | C none — reason]
D-CSS-4 file-naming convention   : [A kebab-case | B underscore — reason]
D-CSS-5 mixed-concern placement  : [A by primary concern | B by component]
D-CSS-6 BEM strictness           : [A strict | B mixed | C other — reason]
D-CSS-7 section banner threshold : [A >100 | B always | C >200]
D-CSS-8 animations placement     : [A animations.css | B inline]
```

---

When done deciding, proceed to implementation. Use
[css-structure.checks.md](./css-structure.checks.md) before declaring it
done.
